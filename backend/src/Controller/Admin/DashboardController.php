<?php

namespace App\Controller\Admin;

use App\Entity\Trabajador;
use EasyCorp\Bundle\EasyAdminBundle\Attribute\AdminDashboard;
use EasyCorp\Bundle\EasyAdminBundle\Config\Assets;
use EasyCorp\Bundle\EasyAdminBundle\Config\Dashboard;
use EasyCorp\Bundle\EasyAdminBundle\Config\MenuItem;
use EasyCorp\Bundle\EasyAdminBundle\Config\UserMenu;
use EasyCorp\Bundle\EasyAdminBundle\Controller\AbstractDashboardController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Security\Core\User\UserInterface;

#[AdminDashboard(routePath: '/admin', routeName: 'admin')]
class DashboardController extends AbstractDashboardController
{
    /** Pantalla 02: Resumen (la completamos en el B9.5) */
    public function index(): Response
    {
        return $this->render('admin/resumen.html.twig');
    }

    public function configureDashboard(): Dashboard
    {
        return Dashboard::new()
            ->setTitle('<span class="logo-j">J</span> JuegAlmi')
            ->setFaviconPath('favicon.ico')
            ->setLocales(['es'])
            ->disableDarkMode();
    }

    public function configureAssets(): Assets
    {
        // Estética de los mockups: fondo claro, menú oscuro y turquesa
        return Assets::new()->addCssFile('css/admin.css');
    }

    public function configureMenuItems(): iterable
    {
        yield MenuItem::linkToDashboard('Resumen', 'fa fa-table-cells-large');
        // Productos, reparaciones, alquileres, pedidos, trabajadores y departamentos: B9.2 – B9.4
    }

    public function configureUserMenu(UserInterface $user): UserMenu
    {
        $menu = parent::configureUserMenu($user);

        if ($user instanceof Trabajador) {
            $menu->setName($user->getNombre() . ' ' . $user->getApellido1());
        }

        return $menu;
    }
}
