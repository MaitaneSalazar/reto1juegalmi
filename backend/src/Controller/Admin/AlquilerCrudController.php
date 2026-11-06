<?php

namespace App\Controller\Admin;

use App\Entity\Alquiler;
use Doctrine\ORM\EntityManagerInterface;
use EasyCorp\Bundle\EasyAdminBundle\Config\Action;
use EasyCorp\Bundle\EasyAdminBundle\Config\Actions;
use EasyCorp\Bundle\EasyAdminBundle\Config\Crud;
use EasyCorp\Bundle\EasyAdminBundle\Config\Filters;
use EasyCorp\Bundle\EasyAdminBundle\Controller\AbstractCrudController;
use EasyCorp\Bundle\EasyAdminBundle\Field\ChoiceField;
use EasyCorp\Bundle\EasyAdminBundle\Field\DateTimeField;
use EasyCorp\Bundle\EasyAdminBundle\Field\Field;
use EasyCorp\Bundle\EasyAdminBundle\Field\IdField;
use EasyCorp\Bundle\EasyAdminBundle\Field\MoneyField;
use EasyCorp\Bundle\EasyAdminBundle\Field\TextField;
use Symfony\Component\Form\Extension\Core\Type\CheckboxType;

/** Alquileres de videojuegos. Los hace el cliente desde la app; en la web se registra la devolución. */
class AlquilerCrudController extends AbstractCrudController
{
    private const ESTADOS = ['Activo' => 'activo', 'Retrasado' => 'retrasado', 'Devuelto' => 'devuelto'];
    private const COLORES = ['activo' => 'info', 'retrasado' => 'danger', 'devuelto' => 'secondary'];

    public static function getEntityFqcn(): string
    {
        return Alquiler::class;
    }

    public function configureCrud(Crud $crud): Crud
    {
        return $crud
            ->setEntityLabelInSingular('Alquiler')
            ->setEntityLabelInPlural('Alquileres')
            ->setPageTitle(Crud::PAGE_DETAIL, fn (Alquiler $a) => (string) $a)
            ->setPageTitle(Crud::PAGE_EDIT, fn (Alquiler $a) => 'Devolución del ' . $a)
            ->setDefaultSort(['fechaInicio' => 'DESC'])
            ->setSearchFields(['cliente.nombre', 'cliente.email'])
            ->setPaginatorPageSize(20);
    }

    public function configureActions(Actions $actions): Actions
    {
        $soloSiFalta = fn (Alquiler $a) => $a->getEstado() !== 'devuelto';

        return $actions
            ->disable(Action::NEW, Action::DELETE, Action::BATCH_DELETE)
            ->add(Crud::PAGE_INDEX, Action::DETAIL)
            ->update(Crud::PAGE_INDEX, Action::EDIT, fn (Action $a) => $a->setLabel('Devolución')->displayIf($soloSiFalta))
            ->update(Crud::PAGE_DETAIL, Action::EDIT, fn (Action $a) => $a->setLabel('Devolución')->displayIf($soloSiFalta));
    }

    public function configureFilters(Filters $filters): Filters
    {
        return $filters->add('cliente')->add('fechaInicio')->add('fechaFinPrevista');
    }

    public function configureFields(string $pageName): iterable
    {
        // ---------- Listado y ficha ----------
        yield IdField::new('id', 'Nº')->hideOnForm();
        yield TextField::new('cliente.nombre', 'Cliente')->hideOnForm();
        yield TextField::new('cliente.email', 'Email')->onlyOnDetail();
        yield DateTimeField::new('fechaInicio', 'Desde')->setFormat('dd/MM/yyyy')->hideOnForm();
        yield DateTimeField::new('fechaFinPrevista', 'Hasta')->setFormat('dd/MM/yyyy')->hideOnForm();
        yield ChoiceField::new('estado', 'Estado')->setChoices(self::ESTADOS)->renderAsBadges(self::COLORES)
            ->setSortable(false)->hideOnForm();
        yield MoneyField::new('importe', 'Importe')->setCurrency('EUR')->setStoredAsCents(false)
            ->setSortable(false)->hideOnForm();
        yield Field::new('lineas', 'Juegos')->setTemplatePath('admin/alquiler_lineas.html.twig')->onlyOnDetail();

        // ---------- Formulario «Devolución» ----------
        yield Field::new('marcarDevuelto', 'Marcar como devueltos los juegos que faltan')
            ->setFormType(CheckboxType::class)
            ->setFormTypeOptions(['required' => false])
            ->setHelp('Se pone la fecha de hoy a los juegos aún no devueltos y sus copias vuelven a estar libres.')
            ->onlyOnForms();
    }

    public function updateEntity(EntityManagerInterface $entityManager, $entityInstance): void
    {
        /** @var Alquiler $alquiler */
        $alquiler = $entityInstance;

        if ($alquiler->isMarcarDevuelto()) {
            $ahora = new \DateTimeImmutable();
            $devueltos = 0;
            foreach ($alquiler->getLineas() as $linea) {
                if ($linea->getFechaDevolucion() === null) {
                    $linea->setFechaDevolucion($ahora);
                    $devueltos++;
                }
            }
            $this->addFlash($devueltos > 0 ? 'success' : 'warning', $devueltos > 0
                ? sprintf('Devolución registrada: %d juego(s).', $devueltos)
                : 'No había juegos pendientes de devolver.');
        } else {
            $this->addFlash('warning', 'No se ha marcado la casilla: no se ha cambiado nada.');
        }

        parent::updateEntity($entityManager, $alquiler);
    }
}
