import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { Filtros, FuenteDatos } from './fuente-datos';

// Fuente REAL: llama a la API de Symfony (GET, POST, PUT, DELETE)
export class FuenteApi implements FuenteDatos {
  constructor(private http: HttpClient, private url: string) {}

  // Convierte los filtros en ?clave=valor (ignora los vacíos)
  private params(filtros: Filtros = {}): HttpParams {
    let p = new HttpParams();
    for (const [clave, valor] of Object.entries(filtros)) {
      if (valor !== undefined) p = p.set(clave, String(valor));
    }
    return p;
  }

  listar<T>(recurso: string, filtros?: Filtros): Observable<T[]> {
    return this.http.get<T[]>(`${this.url}/${recurso}`, { params: this.params(filtros) });
  }

  obtener<T>(recurso: string, id?: number): Observable<T> {
    const ruta = id === undefined ? `${this.url}/${recurso}` : `${this.url}/${recurso}/${id}`;
    return this.http.get<T>(ruta);
  }

  crear<T>(recurso: string, datos: Partial<T>): Observable<T> {
    return this.http.post<T>(`${this.url}/${recurso}`, datos);
  }

  actualizar<T>(recurso: string, id: number, datos: Partial<T>): Observable<T> {
    return this.http.put<T>(`${this.url}/${recurso}/${id}`, datos);
  }

  borrar(recurso: string, id: number): Observable<void> {
    return this.http.delete<void>(`${this.url}/${recurso}/${id}`);
  }
}
