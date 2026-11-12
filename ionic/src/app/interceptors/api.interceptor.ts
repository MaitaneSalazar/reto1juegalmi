import { HttpErrorResponse, HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { Router } from '@angular/router';
import { catchError, from, switchMap, throwError } from 'rxjs';
import { environment } from '../../environments/environment';
import { SesionService } from '../services/sesion.service';
import { UbicacionService } from '../services/ubicacion.service';

// Se ejecuta antes de cada petición HTTP de la app
export const apiInterceptor: HttpInterceptorFn = (req, next) => {
  // Solo las llamadas a nuestra API (los mapas y las imágenes locales no se tocan)
  if (!req.url.startsWith(environment.apiUrl)) return next(req);

  const sesion = inject(SesionService);
  const ubicacion = inject(UbicacionService);
  const router = inject(Router);

  return from(ubicacion.actual()).pipe(
    switchMap(pos => {
      const cabeceras: Record<string, string> = {};

      // Token JWT (todo el consumo de la API mediante tokens)
      const token = sesion.token();
      if (token) cabeceras['Authorization'] = `Bearer ${token}`;

      // Ubicacion del usuario en cualquier consulta y tmbn sin sesion inicidada
      if (pos) {
        cabeceras['X-Lat'] = pos.lat.toFixed(6);
        cabeceras['X-Lon'] = pos.lon.toFixed(6);
      }

      return next(req.clone({ setHeaders: cabeceras }));
    }),
    catchError((e: unknown) => {
      // Token caducado o no válido → cerrar sesión y volver al login
      if (e instanceof HttpErrorResponse && e.status === 401 && sesion.logueado() && !req.url.endsWith('/login')) {
        sesion.cerrar();
        router.navigateByUrl('/login', { replaceUrl: true });
      }
      return throwError(() => e);
    }),
  );
};
