<?php

namespace App\Controller\Admin;

use App\Entity\Tablet;
use EasyCorp\Bundle\EasyAdminBundle\Config\Crud;
use EasyCorp\Bundle\EasyAdminBundle\Field\ChoiceField;
use EasyCorp\Bundle\EasyAdminBundle\Field\IntegerField;
use EasyCorp\Bundle\EasyAdminBundle\Field\NumberField;
use EasyCorp\Bundle\EasyAdminBundle\Field\TextField;

class TabletCrudController extends ProductoCrudController
{
    public static function getEntityFqcn(): string
    {
        return Tablet::class;
    }

    public function configureCrud(Crud $crud): Crud
    {
        return parent::configureCrud($crud)
            ->setEntityLabelInSingular('Tablet')
            ->setEntityLabelInPlural('Tablets');
    }

    protected function camposPropios(): iterable
    {
        yield NumberField::new('pantallaPulgadas', 'Pantalla (pulgadas)')->setNumDecimals(1)->hideOnIndex();
        yield IntegerField::new('almacenamientoGb', 'Almacenamiento (GB)');
        yield TextField::new('sistemaOperativo', 'Sistema operativo')->hideOnIndex();
        yield ChoiceField::new('conectividad', 'Conectividad')
            ->setChoices(['Wi-Fi' => 'wifi', '4G' => '4g', '5G' => '5g']);
    }
}
