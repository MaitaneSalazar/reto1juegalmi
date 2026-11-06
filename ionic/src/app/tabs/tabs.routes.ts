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

      // Cuenta ya no es pestaña, pero sigue accesible (enlaces del menú)
      { path: 'cuenta',   loadComponent: () => import('../pages/cuenta/cuenta.page').then(m => m.CuentaPage) },
      { path: 'cuenta/notificaciones', loadComponent: () => import('../pages/notificaciones/notificaciones.page').then(m => m.NotificacionesPage) },
      { path: 'cuenta/ajustes',        loadComponent: () => import('../pages/ajustes/ajustes.page').then(m => m.AjustesPage) },
      { path: 'cuenta/ayuda',          loadComponent: () => import('../pages/ayuda/ayuda.page').then(m => m.AyudaPage) },
    ],
  },
];
