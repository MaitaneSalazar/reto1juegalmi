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
use App\Entity\Consola;
use App\Entity\Empresa;
use App\Entity\Movil;
use App\Entity\Tablet;
use App\Entity\Videojuego;
use App\Entity\Alquiler;
use App\Entity\Pedido;
use App\Entity\Producto;
use App\Entity\Reparacion;
use Doctrine\ORM\EntityManagerInterface;

#[AdminDashboard(routePath: '/admin', routeName: 'admin')]
class DashboardController extends AbstractDashboardController
{
    /** Pantalla 02: Resumen (la completamos en el B9.5) */
        /** A partir de cuántas unidades se avisa de poco stock */
    private const STOCK_BAJO = 2;

    public function __construct(private EntityManagerInterface $em)
    {
    }

    public function index(): Response
    {
        $reparaciones = array_values(array_filter(
            $this->em->getRepository(Reparacion::class)->findBy([], ['id' => 'DESC']),
            fn (Reparacion $r) => !in_array($r->getEstadoActual(), ['entregada', 'cancelada'], true),
        ));
        $alquileres = $this->em->getRepository(Alquiler::class)->findAll();
        $retrasados = array_values(array_filter($alquileres, fn (Alquiler $a) => $a->getEstado() === 'retrasado'));

        return $this->render('admin/resumen.html.twig', [
            'reparaciones' => $reparaciones,
            'para_recoger' => count(array_filter($reparaciones, fn (Reparacion $r) => $r->getEstadoActual() === 'lista_para_recoger')),
            'alquileres_activos' => count(array_filter($alquileres, fn (Alquiler $a) => $a->getEstado() === 'activo')),
            'retrasados' => $retrasados,
            'por_enviar' => $this->em->getRepository(Pedido::class)->count(['estado' => ['pendiente', 'pagado']]),
            'stock_bajo' => $this->em->getRepository(Producto::class)->createQueryBuilder('p')
                ->where('p.activo = true')->andWhere('p.stock <= :minimo')
                ->setParameter('minimo', self::STOCK_BAJO)
                ->orderBy('p.stock', 'ASC')->getQuery()->getResult(),
            'stock_minimo' => self::STOCK_BAJO,
        ]);
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

        yield MenuItem::section('Catálogo');
        yield MenuItem::linkTo(VideojuegoCrudController::class, 'Videojuegos', 'fa fa-compact-disc');
        yield MenuItem::linkTo(ConsolaCrudController::class, 'Consolas', 'fa fa-gamepad');
        yield MenuItem::linkTo(MovilCrudController::class, 'Móviles', 'fa fa-mobile-screen');
        yield MenuItem::linkTo(TabletCrudController::class, 'Tablets', 'fa fa-tablet-screen-button');
        yield MenuItem::section('Taller');
        yield MenuItem::linkTo(ReparacionCrudController::class, 'Reparaciones', 'fa fa-screwdriver-wrench');
        yield MenuItem::section('Ventas');
        yield MenuItem::linkTo(PedidoCrudController::class, 'Pedidos', 'fa fa-bag-shopping');
        yield MenuItem::linkTo(AlquilerCrudController::class, 'Alquileres', 'fa fa-clock-rotate-left');
        yield MenuItem::section('Administración')->setPermission('ROLE_ADMIN');
        yield MenuItem::linkTo(ClienteCrudController::class, 'Clientes', 'fa fa-users')->setPermission('ROLE_ADMIN');
        yield MenuItem::linkTo(TrabajadorCrudController::class, 'Trabajadores', 'fa fa-id-badge')->setPermission('ROLE_ADMIN');
        yield MenuItem::linkTo(DepartamentoCrudController::class, 'Departamentos', 'fa fa-sitemap')->setPermission('ROLE_ADMIN');
        yield MenuItem::linkTo(TiendaCrudController::class, 'Tienda', 'fa fa-store')->setPermission('ROLE_ADMIN');
        yield MenuItem::linkTo(EmpresaCrudController::class, 'Empresas', 'fa fa-building');
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
