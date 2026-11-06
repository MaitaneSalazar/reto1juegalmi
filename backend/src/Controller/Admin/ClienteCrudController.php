<?php

namespace App\Controller\Admin;

use App\Entity\Cliente;
use EasyCorp\Bundle\EasyAdminBundle\Config\Action;
use EasyCorp\Bundle\EasyAdminBundle\Config\Actions;
use EasyCorp\Bundle\EasyAdminBundle\Config\Crud;
use EasyCorp\Bundle\EasyAdminBundle\Config\Filters;
use EasyCorp\Bundle\EasyAdminBundle\Controller\AbstractCrudController;
use EasyCorp\Bundle\EasyAdminBundle\Field\BooleanField;
use EasyCorp\Bundle\EasyAdminBundle\Field\DateTimeField;
use EasyCorp\Bundle\EasyAdminBundle\Field\IdField;
use EasyCorp\Bundle\EasyAdminBundle\Field\TextField;
use Symfony\Component\Security\Http\Attribute\IsGranted;

/** Clientes. Se registran desde la app; el admin solo los ve y los activa o desactiva. */
#[IsGranted('ROLE_ADMIN')]
class ClienteCrudController extends AbstractCrudController
{
    public static function getEntityFqcn(): string
    {
        return Cliente::class;
    }

    public function configureCrud(Crud $crud): Crud
    {
        return $crud
            ->setEntityLabelInSingular('Cliente')
            ->setEntityLabelInPlural('Clientes')
            ->setDefaultSort(['fechaRegistro' => 'DESC'])
            ->setSearchFields(['nombre', 'apellido1', 'email', 'dni', 'telefono']);
    }

    public function configureActions(Actions $actions): Actions
    {
        // Sin crear (se registran en la app) ni borrar (se perderían sus pedidos)
        return $actions
            ->disable(Action::NEW, Action::DELETE, Action::BATCH_DELETE)
            ->add(Crud::PAGE_INDEX, Action::DETAIL)
            ->update(Crud::PAGE_INDEX, Action::EDIT, fn (Action $a) => $a->setLabel('Activar / desactivar'))
            ->update(Crud::PAGE_DETAIL, Action::EDIT, fn (Action $a) => $a->setLabel('Activar / desactivar'));
    }

    public function configureFilters(Filters $filters): Filters
    {
        return $filters->add('activo');
    }

    public function configureFields(string $pageName): iterable
    {
        yield IdField::new('id', 'Nº')->hideOnForm();
        yield TextField::new('nombre', 'Nombre')->hideOnForm();
        yield TextField::new('apellido1', 'Primer apellido')->hideOnForm();
        yield TextField::new('apellido2', 'Segundo apellido')->onlyOnDetail();
        yield TextField::new('dni', 'DNI')->hideOnForm();
        yield TextField::new('email', 'Email')->hideOnForm();
        yield TextField::new('telefono', 'Teléfono')->onlyOnDetail();
        yield DateTimeField::new('fechaRegistro', 'Registrado el')->setFormat('dd/MM/yyyy HH:mm')->hideOnForm();
        yield BooleanField::new('activo', 'Activo')
            ->setHelp('Un cliente desactivado no puede iniciar sesión en las apps.');
    }
}
