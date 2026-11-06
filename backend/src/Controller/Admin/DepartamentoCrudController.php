<?php

namespace App\Controller\Admin;

use App\Entity\Departamento;
use EasyCorp\Bundle\EasyAdminBundle\Config\Action;
use EasyCorp\Bundle\EasyAdminBundle\Config\Actions;
use EasyCorp\Bundle\EasyAdminBundle\Config\Crud;
use EasyCorp\Bundle\EasyAdminBundle\Controller\AbstractCrudController;
use EasyCorp\Bundle\EasyAdminBundle\Field\AssociationField;
use EasyCorp\Bundle\EasyAdminBundle\Field\BooleanField;
use EasyCorp\Bundle\EasyAdminBundle\Field\TextareaField;
use EasyCorp\Bundle\EasyAdminBundle\Field\TextField;
use Symfony\Component\Security\Http\Attribute\IsGranted;

/** Departamentos de la tienda. Solo para el admin. */
#[IsGranted('ROLE_ADMIN')]
class DepartamentoCrudController extends AbstractCrudController
{
    public static function getEntityFqcn(): string
    {
        return Departamento::class;
    }

    public function configureCrud(Crud $crud): Crud
    {
        return $crud
            ->setEntityLabelInSingular('Departamento')
            ->setEntityLabelInPlural('Departamentos')
            ->setDefaultSort(['nombre' => 'ASC']);
    }

    public function configureActions(Actions $actions): Actions
    {
        // Sin borrar: tienen trabajadores en su historial; se desactivan
        return $actions->disable(Action::DELETE, Action::BATCH_DELETE);
    }

    public function configureFields(string $pageName): iterable
    {
        yield TextField::new('nombre', 'Nombre');
        yield TextareaField::new('descripcion', 'Descripción')->setRequired(false)->hideOnIndex();
        yield TextField::new('telefono', 'Teléfono')->setRequired(false);
        yield AssociationField::new('tienda', 'Tienda');
        yield BooleanField::new('activo', 'Activo');
    }
}
