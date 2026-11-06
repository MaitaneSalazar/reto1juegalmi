<?php

namespace App\Controller\Admin;

use App\Entity\Empresa;
use EasyCorp\Bundle\EasyAdminBundle\Config\Action;
use EasyCorp\Bundle\EasyAdminBundle\Config\Actions;
use EasyCorp\Bundle\EasyAdminBundle\Config\Crud;
use EasyCorp\Bundle\EasyAdminBundle\Controller\AbstractCrudController;
use EasyCorp\Bundle\EasyAdminBundle\Field\TextField;

class EmpresaCrudController extends AbstractCrudController
{
    public static function getEntityFqcn(): string
    {
        return Empresa::class;
    }

    public function configureCrud(Crud $crud): Crud
    {
        return $crud
            ->setEntityLabelInSingular('Empresa')
            ->setEntityLabelInPlural('Empresas')
            ->setDefaultSort(['nombre' => 'ASC'])
            ->setSearchFields(['nombre']);
    }

    public function configureActions(Actions $actions): Actions
    {
        // Sin borrar: los productos dependen de su empresa
        return $actions->disable(Action::DELETE, Action::BATCH_DELETE);
    }

    public function configureFields(string $pageName): iterable
    {
        yield TextField::new('nombre', 'Nombre');
    }
}
