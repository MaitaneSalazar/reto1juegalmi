import { HttpClient } from '@angular/common/http';
import { Observable, delay, map, of, tap } from 'rxjs';
import { environment } from '../../../environments/environment';
import { Filtros, FuenteDatos } from './fuente-datos';

type ConId = { id: number };

// Fuente de EJEMPLO: lee assets/data/<recurso>.json y guarda los cambios en memoria
export class FuenteEjemplo implements FuenteDatos {
  private cache = new Map<string, unknown>();      // datos ya cargados, por recurso
  private espera = environment.retardoEjemploMs;   // simula la espera de red

  constructor(private http: HttpClient) {}

  // Carga el JSON una sola vez; después se usa la copia en memoria
  private cargar(recurso: string): Observable<unknown> {
    if (this.cache.has(recurso)) return of(this.cache.get(recurso));
    return this.http.get(`assets/data/${recurso}.json`).pipe(tap(datos => this.cache.set(recurso, datos)));
  }

  private tabla<T>(recurso: string): Observable<(T & ConId)[]> {
    return this.cargar(recurso) as Observable<(T & ConId)[]>;
  }

  listar<T>(recurso: string, filtros: Filtros = {}): Observable<T[]> {
    const { page, limit, ...campos } = filtros;    // separa la paginación del resto de filtros
    return this.tabla<T>(recurso).pipe(
      // Filtra por igualdad: { tipo: 'MOVIL' } → solo móviles
      map(filas => filas.filter(fila =>
        Object.entries(campos).every(([clave, valor]) =>
          valor === undefined || String((fila as Record<string, unknown>)[clave]) === String(valor)))),
      // Paginación: page=2&limit=5 → elementos 6 a 10
      map(filas => {
        if (!limit) return filas;
        const pagina = Number(page ?? 1);
        return filas.slice((pagina - 1) * Number(limit), pagina * Number(limit));
      }),
      delay(this.espera),
    );
  }

  obtener<T>(recurso: string, id?: number): Observable<T> {
    return this.cargar(recurso).pipe(
      map(datos => {
        if (id === undefined) return datos as T;                  // recurso único (tienda)
        const fila = (datos as ConId[]).find(f => f.id === id);
        if (!fila) throw new Error(`${recurso} ${id} no existe`);
        return fila as T;
      }),
      delay(this.espera),
    );
  }

  crear<T>(recurso: string, datos: Partial<T>): Observable<T> {
    return this.tabla<T>(recurso).pipe(
      map(filas => {
        const id = Math.max(0, ...filas.map(f => f.id)) + 1;      // id siguiente al mayor
        const nuevo = { ...datos, id } as T & ConId;
        filas.push(nuevo);                                         // alta en memoria
        return nuevo as T;
      }),
      delay(this.espera),
    );
  }

  actualizar<T>(recurso: string, id: number, datos: Partial<T>): Observable<T> {
    return this.tabla<T>(recurso).pipe(
      map(filas => {
        const fila = filas.find(f => f.id === id);
        if (!fila) throw new Error(`${recurso} ${id} no existe`);
        Object.assign(fila, datos);                                // modificación en memoria
        return fila as T;
      }),
      delay(this.espera),
    );
  }

  borrar(recurso: string, id: number): Observable<void> {
    return this.tabla<unknown>(recurso).pipe(
      map(filas => {
        const pos = filas.findIndex(f => f.id === id);
        if (pos >= 0) filas.splice(pos, 1);                        // baja en memoria
      }),
      delay(this.espera),
    );
  }
}
