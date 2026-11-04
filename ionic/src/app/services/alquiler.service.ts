import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';
import { Alquiler, EstadoAlquiler } from '../models/alquiler.model';
import { Pagina } from '../models/pagina.model';

const API = environment.apiUrl;

@Injectable({ providedIn: 'root' })
export class AlquilerService {
  private http = inject(HttpClient);

  // Ficha · "Alquilar": POST /api/alquileres { dias, videojuegos: [ids] } (sin copias → 409)
  crear(dias: number, videojuegos: number[]): Observable<Alquiler> {
    return this.http.post<Alquiler>(`${API}/alquileres`, { dias, videojuegos });
  }

  // GET /api/alquileres?estado=activo|retrasado|devuelto
  listar(estado?: EstadoAlquiler, page = 1, limit = 50): Observable<Pagina<Alquiler>> {
    const params: Record<string, string | number> = { page, limit };
    if (estado) params['estado'] = estado;
    return this.http.get<Pagina<Alquiler>>(`${API}/alquileres`, { params });
  }

  // "Devolver": PUT /api/alquileres/{id}/devolver (sin cuerpo = todos los juegos)
  devolver(id: number): Observable<Alquiler> {
    return this.http.put<Alquiler>(`${API}/alquileres/${id}/devolver`, {});
  }

  // Fecha de devolución que se mostrará antes de alquilar (hoy + días)
  fechaDevolucion(dias: number, desde = new Date()): string {
    const fin = new Date(desde);
    fin.setDate(fin.getDate() + dias);
    return fin.toISOString().slice(0, 10);
  }
}
