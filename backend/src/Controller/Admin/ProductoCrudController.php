<?php

namespace App\Controller\Admin;

use App\Entity\Producto;
use App\Service\SubidaImagenes;
use Doctrine\ORM\EntityManagerInterface;
use EasyCorp\Bundle\EasyAdminBundle\Config\Action;
use EasyCorp\Bundle\EasyAdminBundle\Config\Actions;
use EasyCorp\Bundle\EasyAdminBundle\Config\Crud;
use EasyCorp\Bundle\EasyAdminBundle\Config\Filters;
use EasyCorp\Bundle\EasyAdminBundle\Controller\AbstractCrudController;
use EasyCorp\Bundle\EasyAdminBundle\Field\AssociationField;
use EasyCorp\Bundle\EasyAdminBundle\Field\BooleanField;
use EasyCorp\Bundle\EasyAdminBundle\Field\Field;
use EasyCorp\Bundle\EasyAdminBundle\Field\FormField;
use EasyCorp\Bundle\EasyAdminBundle\Field\IdField;
use EasyCorp\Bundle\EasyAdminBundle\Field\IntegerField;
use EasyCorp\Bundle\EasyAdminBundle\Field\MoneyField;
use EasyCorp\Bundle\EasyAdminBundle\Field\TextareaField;
use EasyCorp\Bundle\EasyAdminBundle\Field\TextField;
use Symfony\Component\Form\Extension\Core\Type\FileType;

/**
 * Lo común a los 4 tipos de producto. Cada tipo hereda de aquí y solo añade sus campos.
 * Es abstracta porque Producto también lo es: siempre se crea un Videojuego, una Consola...
 */
abstract class ProductoCrudController extends AbstractCrudController
{
    public function __construct(private SubidaImagenes $subida)
    {
    }

    /** Los campos que solo tiene ese tipo de producto */
    abstract protected function camposPropios(): iterable;

    public function configureCrud(Crud $crud): Crud
    {
        return $crud
            ->setDefaultSort(['nombre' => 'ASC'])
            ->setSearchFields(['nombre', 'descripcion', 'empresa.nombre'])
            ->setPaginatorPageSize(20);
    }

    public function configureActions(Actions $actions): Actions
    {
        // Sin borrar: un producto con pedidos o alquileres no se puede borrar, se desactiva
        return $actions
            ->add(Crud::PAGE_INDEX, Action::DETAIL)
            ->disable(Action::DELETE, Action::BATCH_DELETE);
    }

    public function configureFilters(Filters $filters): Filters
    {
        return $filters->add('activo')->add('empresa');
    }

    public function configureFields(string $pageName): iterable
    {
        yield FormField::addFieldset('Datos generales');
        yield IdField::new('id')->onlyOnDetail();
        yield Field::new('imagen', 'Imagen')->setTemplatePath('admin/campo_imagen.html.twig')->hideOnForm();
        yield TextField::new('nombre', 'Nombre');
        yield AssociationField::new('empresa', 'Empresa');
        yield TextareaField::new('descripcion', 'Descripción')->hideOnIndex();
        yield MoneyField::new('precioVenta', 'Precio')->setCurrency('EUR')->setStoredAsCents(false);
        yield IntegerField::new('stock', 'Stock');
        yield BooleanField::new('activo', 'Activo');
        yield Field::new('archivoImagen', 'Imagen nueva')
            ->setFormType(FileType::class)
            ->setFormTypeOptions(['required' => false, 'attr' => ['accept' => 'image/jpeg,image/png,image/webp']])
            ->setHelp('JPG, PNG o WEBP de 10 MB como máximo. Déjalo vacío para mantener la actual.')
            ->onlyOnForms();

        yield FormField::addFieldset('Características');
        yield from $this->camposPropios();
    }

    public function persistEntity(EntityManagerInterface $entityManager, $entityInstance): void
    {
        $this->guardarImagen($entityInstance);
        parent::persistEntity($entityManager, $entityInstance);
    }

    public function updateEntity(EntityManagerInterface $entityManager, $entityInstance): void
    {
        $this->guardarImagen($entityInstance);
        parent::updateEntity($entityManager, $entityInstance);
    }

    /** Si han subido una imagen, la guarda con el mismo servicio que la API (que también pide la miniatura) */
    private function guardarImagen(Producto $producto): void
    {
        $archivo = $producto->getArchivoImagen();
        if ($archivo === null) {
            return;
        }

        try {
            $producto->setImagen($this->subida->subir($archivo, 'productos'));
        } catch (\Throwable) {
            $this->addFlash('warning', 'La imagen no se ha guardado: tiene que ser JPG, PNG o WEBP de 10 MB como máximo.');
        }

        $producto->setArchivoImagen(null);
    }
}
