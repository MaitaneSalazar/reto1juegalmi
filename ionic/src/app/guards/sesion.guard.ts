import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { SesionService } from '../services/sesion.service';

// Pantallas de la app: sin sesión → al login
export const sesionGuard: CanActivateFn = () => {
  const sesion = inject(SesionService);
  return sesion.logueado() || inject(Router).createUrlTree(['/login']);
};

// Login y registro: si ya hay sesión → a Inicio
export const invitadoGuard: CanActivateFn = () => {
  const sesion = inject(SesionService);
  return !sesion.logueado() || inject(Router).createUrlTree(['/inicio']);
};
