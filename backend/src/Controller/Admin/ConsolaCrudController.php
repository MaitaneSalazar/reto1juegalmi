<?php

namespace App\Controller\Admin;

use App\Entity\Consola;
use EasyCorp\Bundle\EasyAdminBundle\Config\Crud;
use EasyCorp\Bundle\EasyAdminBundle\Field\IntegerField;
use EasyCorp\Bundle\EasyAdminBundle\Field\TextField;

class ConsolaCrudController extends ProductoCrudController
{
    public static function getEntityFqcn(): string
    {
        return Consola::class;
    }

    public function configureCrud(Crud $crud): Crud
    {
        return parent::configureCrud($crud)
            ->setEntityLabelInSingular('Consola')
            ->setEntityLabelInPlural('Consolas');
    }

    protected function camposPropios(): iterable
    {
        yield IntegerField::new('almacenamientoGb', 'Almacenamiento (GB)');
        yield TextField::new('color', 'Color')->hideOnIndex();
        yield TextField::new('edicion', 'Edición')->hideOnIndex();
    }
}
