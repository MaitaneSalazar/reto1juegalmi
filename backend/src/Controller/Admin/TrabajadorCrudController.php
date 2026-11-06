<?php

namespace App\Controller\Admin;

use App\Entity\Departamento;
use App\Entity\Trabajador;
use App\Entity\TrabajadorDepartamento;
use Doctrine\ORM\EntityManagerInterface;
use Doctrine\ORM\EntityRepository;
use EasyCorp\Bundle\EasyAdminBundle\Config\Action;
use EasyCorp\Bundle\EasyAdminBundle\Config\Actions;
use EasyCorp\Bundle\EasyAdminBundle\Config\Crud;
use EasyCorp\Bundle\EasyAdminBundle\Controller\AbstractCrudController;
use EasyCorp\Bundle\EasyAdminBundle\Field\BooleanField;
use EasyCorp\Bundle\EasyAdminBundle\Field\DateField;
use EasyCorp\Bundle\EasyAdminBundle\Field\EmailField;
use EasyCorp\Bundle\EasyAdminBundle\Field\Field;
use EasyCorp\Bundle\EasyAdminBundle\Field\FormField;
use EasyCorp\Bundle\EasyAdminBundle\Field\IdField;
use EasyCorp\Bundle\EasyAdminBundle\Field\TextField;
use Symfony\Bridge\Doctrine\Form\Type\EntityType;
use Symfony\Component\Form\Extension\Core\Type\PasswordType;
use Symfony\Component\PasswordHasher\Hasher\UserPasswordHasherInterface;
use Symfony\Component\Security\Http\Attribute\IsGranted;

/** Trabajadores de la tienda. Solo para el admin. */
#[IsGranted('ROLE_ADMIN')]
class TrabajadorCrudController extends AbstractCrudController
{
    public function __construct(
        private UserPasswordHasherInterface $hasher,
        private EntityManagerInterface $em,
    ) {
    }

    public static function getEntityFqcn(): string
    {
        return Trabajador::class;
    }

    public function configureCrud(Crud $crud): Crud
    {
        return $crud
            ->setEntityLabelInSingular('Trabajador')
            ->setEntityLabelInPlural('Trabajadores')
            ->setDefaultSort(['nombre' => 'ASC'])
            ->setSearchFields(['nombre', 'apellido1', 'email', 'dni', 'cargo']);
    }

    public function configureActions(Actions $actions): Actions
    {
        // Sin borrar: tienen reparaciones y departamentos en su historial; se desactivan
        return $actions
            ->add(Crud::PAGE_INDEX, Action::DETAIL)
            ->disable(Action::DELETE, Action::BATCH_DELETE);
    }

    public function configureFields(string $pageName): iterable
    {
        yield FormField::addFieldset('Datos personales');
        yield IdField::new('id', 'Nº')->onlyOnDetail();
        yield TextField::new('nombre', 'Nombre');
        yield TextField::new('apellido1', 'Primer apellido');
        yield TextField::new('apellido2', 'Segundo apellido')->setRequired(false)->hideOnIndex();
        yield TextField::new('dni', 'DNI')->hideOnIndex();
        yield EmailField::new('email', 'Email');
        yield TextField::new('telefono', 'Teléfono')->setRequired(false)->hideOnIndex();

        yield FormField::addFieldset('Puesto');
        yield TextField::new('cargo', 'Cargo');
        yield DateField::new('fechaContratacion', 'Contratado el')->setFormat('dd/MM/yyyy');
        yield BooleanField::new('esAdmin', 'Admin')->renderAsSwitch(false);
        yield BooleanField::new('activo', 'Activo');

        yield FormField::addFieldset('Acceso y departamento')->onlyOnForms();
        yield Field::new('contrasenaNueva', $pageName === Crud::PAGE_NEW ? 'Contraseña' : 'Contraseña nueva')
            ->setFormType(PasswordType::class)
            ->setFormTypeOptions(['required' => $pageName === Crud::PAGE_NEW, 'attr' => ['autocomplete' => 'new-password']])
            ->setHelp($pageName === Crud::PAGE_NEW ? 'Con la que entrará en la web.' : 'Déjalo vacío para no cambiarla.')
            ->onlyOnForms();

        $actual = $this->departamentoActual($this->getContext()?->getEntity()?->getInstance());
        yield Field::new('departamentoNuevo', 'Departamento')
            ->setFormType(EntityType::class)
            ->setFormTypeOptions([
                'class' => Departamento::class,
                'required' => false,
                'placeholder' => $actual ? 'Sin cambios' : 'Sin departamento',
                'query_builder' => fn (EntityRepository $r) => $r->createQueryBuilder('d')
                    ->where('d.activo = true')->orderBy('d.nombre', 'ASC'),
            ])
            ->setHelp($actual ? 'Ahora está en «' . $actual->getNombre() . '». Al cambiarlo se guarda en su historial.' : '')
            ->onlyOnForms();
    }

    public function persistEntity(EntityManagerInterface $entityManager, $entityInstance): void
    {
        /** @var Trabajador $trabajador */
        $trabajador = $entityInstance;
        $this->guardarContrasena($trabajador);
        $this->cambiarDepartamento($trabajador);
        parent::persistEntity($entityManager, $trabajador);
    }

    public function updateEntity(EntityManagerInterface $entityManager, $entityInstance): void
    {
        /** @var Trabajador $trabajador */
        $trabajador = $entityInstance;

        // El admin no puede dejarse fuera de la web a sí mismo
        $yo = $this->getUser();
        if ($yo instanceof Trabajador && $yo->getId() === $trabajador->getId()
            && (!$trabajador->isActivo() || !$trabajador->isEsAdmin())) {
            $trabajador->setActivo(true)->setEsAdmin(true);
            $this->addFlash('warning', 'No puedes desactivarte ni quitarte el permiso de admin a ti mismo.');
        }

        $this->guardarContrasena($trabajador);
        $this->cambiarDepartamento($trabajador);
        parent::updateEntity($entityManager, $trabajador);
    }

    /** La contraseña se guarda con hash, igual que en el registro de la API */
    private function guardarContrasena(Trabajador $trabajador): void
    {
        $contrasena = $trabajador->getContrasenaNueva();
        if ($contrasena !== null && $contrasena !== '') {
            $trabajador->setPassword($this->hasher->hashPassword($trabajador, $contrasena));
            $this->addFlash('success', 'Contraseña guardada.');
        }
        $trabajador->setContrasenaNueva(null);
    }

    /** Cierra la etapa en el departamento anterior y abre otra en el nuevo */
    private function cambiarDepartamento(Trabajador $trabajador): void
    {
        $nuevo = $trabajador->getDepartamentoNuevo();
        if ($nuevo === null) {
            return;
        }

        $asignacion = $this->asignacionActual($trabajador);
        if ($asignacion?->getDepartamento() === $nuevo) {
            return;
        }

        $hoy = new \DateTimeImmutable('today');
        $asignacion?->setFechaFin($hoy);
        $this->em->persist((new TrabajadorDepartamento())
            ->setTrabajador($trabajador)->setDepartamento($nuevo)->setFechaInicio($hoy));
        $this->addFlash('success', 'Departamento cambiado a «' . $nuevo->getNombre() . '».');
    }

    private function asignacionActual(?object $trabajador): ?TrabajadorDepartamento
    {
        if (!$trabajador instanceof Trabajador || $trabajador->getId() === null) {
            return null;
        }

        return $this->em->getRepository(TrabajadorDepartamento::class)
            ->findOneBy(['trabajador' => $trabajador, 'fechaFin' => null]);
    }

    private function departamentoActual(?object $trabajador): ?Departamento
    {
        return $this->asignacionActual($trabajador)?->getDepartamento();
    }
}
