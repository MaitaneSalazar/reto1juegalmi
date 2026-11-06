<?php

namespace App\Controller\Admin;

use App\Entity\Tienda;
use EasyCorp\Bundle\EasyAdminBundle\Config\Action;
use EasyCorp\Bundle\EasyAdminBundle\Config\Actions;
use EasyCorp\Bundle\EasyAdminBundle\Config\Crud;
use EasyCorp\Bundle\EasyAdminBundle\Controller\AbstractCrudController;
use EasyCorp\Bundle\EasyAdminBundle\Field\EmailField;
use EasyCorp\Bundle\EasyAdminBundle\Field\Field;
use EasyCorp\Bundle\EasyAdminBundle\Field\NumberField;
use EasyCorp\Bundle\EasyAdminBundle\Field\TextField;
use Symfony\Component\Security\Http\Attribute\IsGranted;

/** Datos de la tienda (la que se ve en la pestaña «Tienda» de las apps). Solo para el admin. */
#[IsGranted('ROLE_ADMIN')]
class TiendaCrudController extends AbstractCrudController
{
    public static function getEntityFqcn(): string
    {
        return Tienda::class;
    }

    public function configureCrud(Crud $crud): Crud
    {
        return $crud->setEntityLabelInSingular('Tienda')->setEntityLabelInPlural('Tienda');
    }

    public function configureActions(Actions $actions): Actions
    {
        return $actions
            ->disable(Action::NEW, Action::DELETE, Action::BATCH_DELETE)
            ->add(Crud::PAGE_INDEX, Action::DETAIL);
    }

    public function configureFields(string $pageName): iterable
    {
        yield TextField::new('nombre', 'Nombre');
        yield TextField::new('telefono', 'Teléfono');
        yield EmailField::new('email', 'Email');
        yield Field::new('direccion', 'Dirección')->setTemplatePath('admin/direccion.html.twig')->onlyOnDetail();
        yield NumberField::new('latitud', 'Latitud')->setNumDecimals(6)->hideOnIndex()
            ->setHelp('Para el mapa de las apps. Se saca de Google Maps (clic derecho en el sitio).');
        yield NumberField::new('longitud', 'Longitud')->setNumDecimals(6)->hideOnIndex();
    }
}
