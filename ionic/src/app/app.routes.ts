import { Routes } from '@angular/router';
import { invitadoGuard, sesionGuard } from './guards/sesion.guard';

export const routes: Routes = [
  { path: '', redirectTo: 'inicio', pathMatch: 'full' },   // sin sesión, el guard lo manda al login

  // Acceso (solo sin sesión)
  { path: 'login', canActivate: [invitadoGuard], loadComponent: () => import('./pages/login/login.page').then(m => m.LoginPage) },
  { path: 'registro', canActivate: [invitadoGuard], loadComponent: () => import('./pages/registro/registro.page').then(m => m.RegistroPage) },

  // Pantallas SIN barra inferior (requieren sesión)
  { path: 'producto/:id', canActivate: [sesionGuard], loadComponent: () => import('./pages/detalle-producto/detalle-producto.page').then(m => m.DetalleProductoPage) },
  { path: 'cuenta/pedidos', canActivate: [sesionGuard], loadComponent: () => import('./pages/pedidos/pedidos.page').then(m => m.PedidosPage) },
  { path: 'cuenta/alquileres', canActivate: [sesionGuard], loadComponent: () => import('./pages/alquileres/alquileres.page').then(m => m.AlquileresPage) },
  { path: 'cuenta/datos-personales', canActivate: [sesionGuard], loadComponent: () => import('./pages/datos-personales/datos-personales.page').then(m => m.DatosPersonalesPage) },
  { path: 'cuenta/datos-personales/editar', canActivate: [sesionGuard], loadComponent: () => import('./pages/editar-datos/editar-datos.page').then(m => m.EditarDatosPage) },
  { path: 'cuenta/direcciones', canActivate: [sesionGuard], loadComponent: () => import('./pages/direcciones/direcciones.page').then(m => m.DireccionesPage) },
  { path: 'cuenta/direcciones/nueva', canActivate: [sesionGuard], loadComponent: () => import('./pages/direccion/direccion.page').then(m => m.DireccionPage) },
  { path: 'cuenta/direcciones/:id', canActivate: [sesionGuard], loadComponent: () => import('./pages/direccion/direccion.page').then(m => m.DireccionPage) },

  // Pantallas CON barra inferior (requieren sesión)
  { path: '', canActivate: [sesionGuard], loadChildren: () => import('./tabs/tabs.routes').then(m => m.routes) },

  { path: '**', redirectTo: 'inicio' },
];
