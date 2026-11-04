import { Routes } from '@angular/router';
import { TabsPage } from './tabs.page';

export const routes: Routes = [
  {
    path: '',
    component: TabsPage,
    children: [
      // Pestañas de la barra inferior
      { path: 'inicio',   loadComponent: () => import('../pages/home/home.page').then(m => m.HomePage) },
      { path: 'tienda',   loadComponent: () => import('../pages/tienda/tienda.page').then(m => m.TiendaPage) },
      { path: 'taller',   loadComponent: () => import('../pages/taller/taller.page').then(m => m.TallerPage) },
      { path: 'taller/reparacion/:id', loadComponent: () => import('../pages/reparacion/reparacion.page').then(m => m.ReparacionPage) },
      { path: 'cesta',    loadComponent: () => import('../pages/cesta/cesta.page').then(m => m.CestaPage) },
      { path: 'nosotros', loadComponent: () => import('../pages/nosotros/nosotros.page').then(m => m.NosotrosPage) },
      { path: 'cuenta',   loadComponent: () => import('../pages/cuenta/cuenta.page').then(m => m.CuentaPage) },

      // Opciones del menú lateral (cuelgan de Cuenta)
      { path: 'cuenta/pedidos',          loadComponent: () => import('../pages/pedidos/pedidos.page').then(m => m.PedidosPage) },
      { path: 'cuenta/alquileres',       loadComponent: () => import('../pages/alquileres/alquileres.page').then(m => m.AlquileresPage) },
      { path: 'cuenta/datos-personales', loadComponent: () => import('../pages/datos-personales/datos-personales.page').then(m => m.DatosPersonalesPage) },
      { path: 'cuenta/direcciones',      loadComponent: () => import('../pages/direcciones/direcciones.page').then(m => m.DireccionesPage) },
      { path: 'cuenta/notificaciones',   loadComponent: () => import('../pages/notificaciones/notificaciones.page').then(m => m.NotificacionesPage) },
      { path: 'cuenta/ajustes',          loadComponent: () => import('../pages/ajustes/ajustes.page').then(m => m.AjustesPage) },
      { path: 'cuenta/ayuda',            loadComponent: () => import('../pages/ayuda/ayuda.page').then(m => m.AyudaPage) },
    ],
  },
];
