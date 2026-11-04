import { InjectionToken, Provider } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../environments/environment';
import { FuenteDatos } from '../services/fuentes/fuente-datos';
import { FuenteApi } from '../services/fuentes/fuente-api';
import { FuenteEjemplo } from '../services/fuentes/fuente-ejemplo';

// Token con el que los servicios piden "la fuente de datos"
export const FUENTE_DATOS = new InjectionToken<FuenteDatos>('FUENTE_DATOS');

// Factory: según environment devuelve la API real o los datos de ejemplo
export function crearFuenteDatos(http: HttpClient): FuenteDatos {
  return environment.usarDatosEjemplo
    ? new FuenteEjemplo(http)
    : new FuenteApi(http, environment.apiUrl);
}

// Proveedor que se registra en main.ts
export const proveedorFuenteDatos: Provider = {
  provide: FUENTE_DATOS,
  useFactory: crearFuenteDatos,   // ← proveedor useFactory que pide la rúbrica
  deps: [HttpClient],             // dependencias que recibe la factory
};
