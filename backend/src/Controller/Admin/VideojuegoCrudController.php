<?php

namespace App\Controller\Admin;

use App\Entity\Videojuego;
use EasyCorp\Bundle\EasyAdminBundle\Config\Crud;
use EasyCorp\Bundle\EasyAdminBundle\Config\Filters;
use EasyCorp\Bundle\EasyAdminBundle\Field\ChoiceField;
use EasyCorp\Bundle\EasyAdminBundle\Field\IntegerField;
use EasyCorp\Bundle\EasyAdminBundle\Field\MoneyField;
use EasyCorp\Bundle\EasyAdminBundle\Field\TextField;

class VideojuegoCrudController extends ProductoCrudController
{
    public static function getEntityFqcn(): string
    {
        return Videojuego::class;
    }

    public function configureCrud(Crud $crud): Crud
    {
        return parent::configureCrud($crud)
            ->setEntityLabelInSingular('Videojuego')
            ->setEntityLabelInPlural('Videojuegos');
    }

    public function configureFilters(Filters $filters): Filters
    {
        return parent::configureFilters($filters)->add('plataforma')->add('pegi');
    }

    protected function camposPropios(): iterable
    {
        yield TextField::new('plataforma', 'Plataforma');
        yield TextField::new('genero', 'Género')->hideOnIndex();
        yield ChoiceField::new('pegi', 'PEGI')
            ->setChoices(array_combine(array_map(fn ($p) => 'PEGI ' . $p, Videojuego::PEGI), Videojuego::PEGI));
        yield MoneyField::new('precioAlquilerDia', 'Alquiler por día')
            ->setCurrency('EUR')->setStoredAsCents(false)->hideOnIndex();
        yield IntegerField::new('copiasAlquiler', 'Copias para alquilar');
    }
}
