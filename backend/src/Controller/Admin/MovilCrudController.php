<?php

namespace App\Controller\Admin;

use App\Entity\Movil;
use EasyCorp\Bundle\EasyAdminBundle\Config\Crud;
use EasyCorp\Bundle\EasyAdminBundle\Field\IntegerField;
use EasyCorp\Bundle\EasyAdminBundle\Field\NumberField;
use EasyCorp\Bundle\EasyAdminBundle\Field\TextField;

class MovilCrudController extends ProductoCrudController
{
    public static function getEntityFqcn(): string
    {
        return Movil::class;
    }

    public function configureCrud(Crud $crud): Crud
    {
        return parent::configureCrud($crud)
            ->setEntityLabelInSingular('Móvil')
            ->setEntityLabelInPlural('Móviles');
    }

    protected function camposPropios(): iterable
    {
        yield NumberField::new('pantallaPulgadas', 'Pantalla (pulgadas)')->setNumDecimals(1)->hideOnIndex();
        yield IntegerField::new('ramGb', 'RAM (GB)')->hideOnIndex();
        yield IntegerField::new('almacenamientoGb', 'Almacenamiento (GB)');
        yield TextField::new('sistemaOperativo', 'Sistema operativo')->hideOnIndex();
        yield IntegerField::new('bateriaMah', 'Batería (mAh)')->hideOnIndex();
    }
}
