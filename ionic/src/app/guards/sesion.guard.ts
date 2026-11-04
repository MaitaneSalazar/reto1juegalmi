import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { SesionService } from '../services/sesion.service';

// Pantallas de la app: sin sesión → al login
export const sesionGuard: CanActivateFn = () => {
  const sesion = inject(SesionService);
  return sesion.logueado() || inject(Router).createUrlTree(['/login']);
};

// Login y registro: si ya hay sesión → a su pantalla de inicio
export const invitadoGuard: CanActivateFn = () => {
  const sesion = inject(SesionService);
  if (!sesion.logueado()) return true;
  return inject(Router).createUrlTree([sesion.esTecnico() ? '/panel' : '/inicio']);
};

// Panel del trabajador: solo técnicos
export const tecnicoGuard: CanActivateFn = () => {
  const sesion = inject(SesionService);
  return sesion.esTecnico() || inject(Router).createUrlTree(['/inicio']);
};
