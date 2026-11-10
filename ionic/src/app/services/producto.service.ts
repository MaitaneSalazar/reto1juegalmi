import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';
import { Producto, TipoProducto } from '../models/producto.model';
import { Pagina } from '../models/pagina.model';

const API = environment.apiUrl;

@Injectable({ providedIn: 'root' })
export class ProductoService {
  private http = inject(HttpClient);

  // Tienda · comprar: GET /api/productos?tipo=&q=&page=&limit=
  listar(f: { tipo?: TipoProducto; plataforma?: string; q?: string; page?: number; limit?: number } = {}): Observable<Pagina<Producto>> {
    return this.http.get<Pagina<Producto>>(`${API}/productos`, { params: this.params(f) });
  }

  // Tienda · alquilar: GET /api/videojuegos/alquiler?plataforma=&page=&limit=
  alquiler(f: { plataforma?: string; page?: number; limit?: number } = {}): Observable<Pagina<Producto>> {
    return this.http.get<Pagina<Producto>>(`${API}/videojuegos/alquiler`, { params: this.params(f) });
  }

  // Botones de filtro: ["Multi","PS5","Switch","Xbox"]
  plataformas(): Observable<string[]> {
    return this.http.get<string[]>(`${API}/videojuegos/plataformas`);
  }

  // Ficha: GET /api/productos/{id}
  obtener(id: number): Observable<Producto> {
    return this.http.get<Producto>(`${API}/productos/${id}`);
  }

  // Convierte los filtros en ?clave=valor (sin los vacíos)
  private params(f: object): HttpParams {
    let p = new HttpParams();
    for (const [clave, valor] of Object.entries(f)) {
      if (valor !== undefined && valor !== null && valor !== '') p = p.set(clave, String(valor));
    }
    return p;
  }
}
