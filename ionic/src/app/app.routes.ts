import { Routes } from '@angular/router';
import { invitadoGuard, sesionGuard, tecnicoGuard } from './guards/sesion.guard';

export const routes: Routes = [
  { path: '', redirectTo: 'inicio', pathMatch: 'full' },   // sin sesión, el guard lo manda al login

  // Acceso (solo sin sesión)
  { path: 'login', canActivate: [invitadoGuard], loadComponent: () => import('./pages/login/login.page').then(m => m.LoginPage) },
  { path: 'registro', canActivate: [invitadoGuard], loadComponent: () => import('./pages/registro/registro.page').then(m => m.RegistroPage) },

  // Pantallas SIN barra inferior (requieren sesión)
  { path: 'producto/:id', canActivate: [sesionGuard], loadComponent: () => import('./pages/detalle-producto/detalle-producto.page').then(m => m.DetalleProductoPage) },
  { path: 'panel', canActivate: [sesionGuard, tecnicoGuard], loadComponent: () => import('./pages/panel-trabajador/panel-trabajador.page').then(m => m.PanelTrabajadorPage) },

  // Pantallas CON barra inferior (requieren sesión)
  { path: '', canActivate: [sesionGuard], loadChildren: () => import('./tabs/tabs.routes').then(m => m.routes) },

  { path: '**', redirectTo: 'inicio' },
];
