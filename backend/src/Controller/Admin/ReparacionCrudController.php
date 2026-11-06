<?php

namespace App\Controller\Admin;

use App\Entity\Reparacion;
use App\Entity\Trabajador;
use App\Entity\TrabajadorReparacion;
use Doctrine\ORM\EntityManagerInterface;
use Doctrine\ORM\EntityRepository;
use EasyCorp\Bundle\EasyAdminBundle\Config\Action;
use EasyCorp\Bundle\EasyAdminBundle\Config\Actions;
use EasyCorp\Bundle\EasyAdminBundle\Config\Crud;
use EasyCorp\Bundle\EasyAdminBundle\Config\Filters;
use EasyCorp\Bundle\EasyAdminBundle\Controller\AbstractCrudController;
use EasyCorp\Bundle\EasyAdminBundle\Field\ChoiceField;
use EasyCorp\Bundle\EasyAdminBundle\Field\DateTimeField;
use EasyCorp\Bundle\EasyAdminBundle\Field\Field;
use EasyCorp\Bundle\EasyAdminBundle\Field\FormField;
use EasyCorp\Bundle\EasyAdminBundle\Field\IdField;
use EasyCorp\Bundle\EasyAdminBundle\Field\MoneyField;
use EasyCorp\Bundle\EasyAdminBundle\Field\TextareaField;
use EasyCorp\Bundle\EasyAdminBundle\Field\TextField;
use Symfony\Bridge\Doctrine\Form\Type\EntityType;
use Symfony\Component\Form\Extension\Core\Type\ChoiceType;
use EasyCorp\Bundle\EasyAdminBundle\Filter\ChoiceFilter;

/**
 * Reparaciones (soporte técnico). Las abre el cliente desde la app;
 * en la web el trabajador cambia el estado, se asigna y pone el presupuesto.
 */
class ReparacionCrudController extends AbstractCrudController
{
    private const ESTADOS = [
        'Recibida' => 'recibida',
        'Diagnóstico' => 'diagnostico',
        'En reparación' => 'en_reparacion',
        'Lista para recoger' => 'lista_para_recoger',
        'Entregada' => 'entregada',
        'Cancelada' => 'cancelada',
    ];

    private const COLORES_ESTADO = [
        'recibida' => 'secondary',
        'diagnostico' => 'info',
        'en_reparacion' => 'warning',
        'lista_para_recoger' => 'success',
        'entregada' => 'light',
        'cancelada' => 'danger',
    ];

    private const DISPOSITIVOS = [
        'Consola' => 'consola',
        'Móvil' => 'movil',
        'Tablet' => 'tablet',
        'Ordenador' => 'ordenador',
        'Mando' => 'mando',
        'Auriculares' => 'auriculares',
        'Reloj' => 'reloj',
        'Otro' => 'otro',
    ];

    /** Estados en los que la reparación ya está cerrada */
    private const FINALES = ['entregada', 'cancelada'];

    public static function getEntityFqcn(): string
    {
        return Reparacion::class;
    }

    public function configureCrud(Crud $crud): Crud
    {
        return $crud
            ->setEntityLabelInSingular('Reparación')
            ->setEntityLabelInPlural('Reparaciones')
            ->setPageTitle(Crud::PAGE_DETAIL, fn (Reparacion $r) => (string) $r)
            ->setPageTitle(Crud::PAGE_EDIT, fn (Reparacion $r) => 'Gestionar ' . $r)
            ->setDefaultSort(['id' => 'DESC'])
            ->setSearchFields(['marca', 'modelo', 'descripcionAveria', 'cliente.nombre', 'cliente.email'])
            ->setPaginatorPageSize(20);
    }

    public function configureActions(Actions $actions): Actions
    {
        return $actions
            ->disable(Action::NEW, Action::DELETE, Action::BATCH_DELETE)
            ->add(Crud::PAGE_INDEX, Action::DETAIL)
            ->update(Crud::PAGE_INDEX, Action::EDIT, fn (Action $a) => $a->setLabel('Gestionar'))
            ->update(Crud::PAGE_DETAIL, Action::EDIT, fn (Action $a) => $a->setLabel('Gestionar'));
    }

    public function configureFilters(Filters $filters): Filters
    {
        return $filters->add(ChoiceFilter::new('tipoDispositivo', 'Dispositivo')->setChoices(self::DISPOSITIVOS));
    }

    public function configureFields(string $pageName): iterable
    {
        // ---------- Listado y ficha ----------
        yield IdField::new('id', 'Nº')->hideOnForm();
        yield TextField::new('cliente.nombre', 'Cliente')->hideOnForm();
        yield TextField::new('cliente.email', 'Email')->onlyOnDetail();
        yield ChoiceField::new('tipoDispositivo', 'Dispositivo')->setChoices(self::DISPOSITIVOS)->hideOnForm();
        yield TextField::new('marca', 'Marca')->hideOnForm();
        yield TextField::new('modelo', 'Modelo')->hideOnForm();
        yield ChoiceField::new('estadoActual', 'Estado')
            ->setChoices(self::ESTADOS)->renderAsBadges(self::COLORES_ESTADO)
            ->setSortable(false)->hideOnForm();
        yield TextField::new('nombreTrabajadorActual', 'Trabajador')->setSortable(false)->hideOnForm();
        yield DateTimeField::new('fechaRecepcion', 'Recibida el')
            ->setFormat('dd/MM/yyyy HH:mm')->setSortable(false)->hideOnForm();
        yield TextareaField::new('descripcionAveria', 'Avería que describe el cliente')->onlyOnDetail();
        yield TextField::new('componente', 'Componente')->onlyOnDetail();
        yield MoneyField::new('presupuesto', 'Presupuesto')->setCurrency('EUR')->setStoredAsCents(false)->onlyOnDetail();
        yield Field::new('fotos', 'Fotos del cliente')->setTemplatePath('admin/fotos_reparacion.html.twig')->onlyOnDetail();
        yield Field::new('historial', 'Historial')->setTemplatePath('admin/historial_reparacion.html.twig')->onlyOnDetail();

        // ---------- Formulario «Gestionar» ----------
        yield FormField::addFieldset('Diagnóstico')->onlyOnForms();
        yield TextField::new('componente', 'Componente averiado')->setRequired(false)->onlyOnForms();
        yield MoneyField::new('presupuesto', 'Presupuesto')
            ->setCurrency('EUR')->setStoredAsCents(false)->setRequired(false)->onlyOnForms();

        yield FormField::addFieldset('Estado y trabajador')->onlyOnForms();
        yield Field::new('estadoNuevo', 'Estado')
            ->setFormType(ChoiceType::class)
            ->setFormTypeOptions(['choices' => self::ESTADOS])
            ->setHelp('Al cambiarlo se añade un paso al historial, que es lo que ve el cliente en la app.')
            ->onlyOnForms();
        yield TextareaField::new('notaEstado', 'Nota para el historial')->setRequired(false)
            ->setHelp('Opcional. Por ejemplo: «Cambiado el joystick izquierdo».')->onlyOnForms();
        yield Field::new('trabajadorNuevo', 'Trabajador asignado')
            ->setFormType(EntityType::class)
            ->setFormTypeOptions([
                'class' => Trabajador::class,
                'required' => false,
                'placeholder' => 'Sin asignar',
                'choice_label' => fn (Trabajador $t) => trim($t->getNombre() . ' ' . $t->getApellido1()),
                'query_builder' => fn (EntityRepository $r) => $r->createQueryBuilder('t')
                    ->where('t.activo = true')->orderBy('t.nombre', 'ASC'),
            ])
            ->onlyOnForms();
    }

    public function updateEntity(EntityManagerInterface $entityManager, $entityInstance): void
    {
        /** @var Reparacion $reparacion */
        $reparacion = $entityInstance;
        $estadoActual = $reparacion->getEstadoActual();
        $estadoNuevo = $reparacion->getEstadoNuevo();

        // Estado: si ha cambiado, se añade un paso al historial (nunca se edita el anterior)
        if ($estadoNuevo !== null && $estadoNuevo !== $estadoActual) {
            if (in_array($estadoActual, self::FINALES, true)) {
                $this->addFlash('warning', 'Esta reparación ya está cerrada: no se puede cambiar su estado.');
            } else {
                $nota = trim((string) $reparacion->getNotaEstado());
                $reparacion->cambiarEstado($estadoNuevo, $nota === '' ? null : $nota);
                $this->addFlash('success', 'Estado cambiado a «' . array_search($estadoNuevo, self::ESTADOS, true) . '».');
            }
        }

        // Trabajador: se cierra la asignación anterior y se abre una nueva
        $trabajadorNuevo = $reparacion->getTrabajadorNuevo();
        if ($trabajadorNuevo !== null && $trabajadorNuevo !== $reparacion->getTrabajadorActual()) {
            $ahora = new \DateTimeImmutable();
            foreach ($reparacion->getAsignaciones() as $asignacion) {
                if ($asignacion->getFechaFin() === null) {
                    $asignacion->setFechaFin($ahora);
                }
            }
            $asignacion = (new TrabajadorReparacion())->setTrabajador($trabajadorNuevo);
            $reparacion->addAsignacion($asignacion);
            $entityManager->persist($asignacion);
            $this->addFlash('success', 'Reparación asignada a ' . trim($trabajadorNuevo->getNombre() . ' ' . $trabajadorNuevo->getApellido1()) . '.');
        }

        parent::updateEntity($entityManager, $reparacion);
    }
}
