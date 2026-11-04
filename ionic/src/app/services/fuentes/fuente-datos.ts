import { Observable } from 'rxjs';

// Filtros que se pasan a los listados (page y limit = paginación)
export type Filtros = Record<string, string | number | boolean | undefined>;

// Contrato común: los servicios solo conocen esto, no saben de dónde salen los datos
export interface FuenteDatos {
  listar<T>(recurso: string, filtros?: Filtros): Observable<T[]>;
  obtener<T>(recurso: string, id?: number): Observable<T>;   // sin id → recurso único (tienda)
  crear<T>(recurso: string, datos: Partial<T>): Observable<T>;
  actualizar<T>(recurso: string, id: number, datos: Partial<T>): Observable<T>;
  borrar(recurso: string, id: number): Observable<void>;
}
