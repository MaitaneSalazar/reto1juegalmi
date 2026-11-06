<?php

namespace App\Controller\Admin;

use App\Entity\Pedido;
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
use EasyCorp\Bundle\EasyAdminBundle\Filter\ChoiceFilter;
use Symfony\Component\Form\Extension\Core\Type\ChoiceType;

/** Pedidos de la tienda. Los hace el cliente desde la app; en la web se cambia su estado. */
class PedidoCrudController extends AbstractCrudController
{
    private const ESTADOS = [
        'Pendiente' => 'pendiente',
        'Pagado' => 'pagado',
        'Enviado' => 'enviado',
        'Entregado' => 'entregado',
        'Cancelado' => 'cancelado',
    ];

    private const COLORES = [
        'pendiente' => 'secondary',
        'pagado' => 'info',
        'enviado' => 'warning',
        'entregado' => 'success',
        'cancelado' => 'danger',
    ];

    /** Estados en los que el pedido ya está cerrado */
    private const FINALES = ['entregado', 'cancelado'];

    public static function getEntityFqcn(): string
    {
        return Pedido::class;
    }

    public function configureCrud(Crud $crud): Crud
    {
        return $crud
            ->setEntityLabelInSingular('Pedido')
            ->setEntityLabelInPlural('Pedidos')
            ->setPageTitle(Crud::PAGE_DETAIL, fn (Pedido $p) => (string) $p)
            ->setPageTitle(Crud::PAGE_EDIT, fn (Pedido $p) => 'Gestionar ' . $p)
            ->setDefaultSort(['fecha' => 'DESC'])
            ->setSearchFields(['id', 'estado'])
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
        return $filters
            ->add(ChoiceFilter::new('estado', 'Estado')->setChoices(self::ESTADOS))
            ->add('fecha');
    }

    public function configureFields(string $pageName): iterable
    {
        // ---------- Listado y ficha ----------
        yield IdField::new('id', 'Nº')->hideOnForm();
        yield TextField::new('cliente.nombre', 'Cliente')->hideOnForm();
        yield TextField::new('cliente.email', 'Email')->onlyOnDetail();
        yield Field::new('domicilio', 'Dirección de envío')->setTemplatePath('admin/pedido_direccion.html.twig')->onlyOnDetail();
        yield DateTimeField::new('fecha', 'Fecha')->setFormat('dd/MM/yyyy HH:mm')->hideOnForm();
        yield MoneyField::new('total', 'Total')->setCurrency('EUR')->setStoredAsCents(false)
            ->setSortable(false)->hideOnForm();
        yield ChoiceField::new('estado', 'Estado')->setChoices(self::ESTADOS)->renderAsBadges(self::COLORES)->hideOnForm();
        yield Field::new('lineas', 'Productos')->setTemplatePath('admin/pedido_lineas.html.twig')->onlyOnDetail();

        // ---------- Formulario «Gestionar» ----------
        yield Field::new('estado', 'Estado del pedido')
            ->setFormType(ChoiceType::class)
            ->setFormTypeOptions(['choices' => self::ESTADOS])
            ->setHelp('Si lo cancelas, se devuelve al stock lo que se había pedido. Un pedido entregado o cancelado ya no cambia.')
            ->onlyOnForms();
    }

    public function updateEntity(EntityManagerInterface $entityManager, $entityInstance): void
    {
        /** @var Pedido $pedido */
        $pedido = $entityInstance;
        $anterior = $entityManager->getUnitOfWork()->getOriginalEntityData($pedido)['estado'] ?? $pedido->getEstado();
        $nuevo = $pedido->getEstado();

        if ($nuevo !== $anterior) {
            if (in_array($anterior, self::FINALES, true)) {
                $pedido->setEstado($anterior);
                $this->addFlash('warning', 'Este pedido ya está cerrado: no se puede cambiar su estado.');
            } else {
                if ($nuevo === 'cancelado') {
                    foreach ($pedido->getLineas() as $linea) {
                        $producto = $linea->getProducto();
                        $producto->setStock($producto->getStock() + $linea->getCantidad());
                    }
                    $this->addFlash('info', 'Se ha devuelto al stock lo que se había pedido.');
                }
                $this->addFlash('success', 'Estado cambiado a «' . array_search($nuevo, self::ESTADOS, true) . '».');
            }
        }

        parent::updateEntity($entityManager, $pedido);
    }
}
