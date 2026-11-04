import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';
import { NuevaReparacion, Reparacion } from '../models/reparacion.model';
import { Pagina } from '../models/pagina.model';

const API = environment.apiUrl;

@Injectable({ providedIn: 'root' })
export class ReparacionService {
  private http = inject(HttpClient);

  // Nueva reparación: POST /api/reparaciones → 201 en estado "recibida"
  crear(datos: NuevaReparacion): Observable<Reparacion> {
    return this.http.post<Reparacion>(`${API}/reparaciones`, datos);
  }

  // Foto de la cámara: POST /api/reparaciones/{id}/fotos (multipart, campo "imagen")
  subirFoto(id: number, imagen: Blob, nombre: string): Observable<Reparacion> {
    const form = new FormData();
    form.append('imagen', imagen, nombre);
    return this.http.post<Reparacion>(`${API}/reparaciones/${id}/fotos`, form);
  }

  // Mis reparaciones / Inicio: GET /api/reparaciones (la más reciente primero)
  listar(page = 1, limit = 50): Observable<Pagina<Reparacion>> {
    return this.http.get<Pagina<Reparacion>>(`${API}/reparaciones`, { params: { page, limit } });
  }

  // Seguimiento: GET /api/reparaciones/{id}
  obtener(id: number): Observable<Reparacion> {
    return this.http.get<Reparacion>(`${API}/reparaciones/${id}`);
  }

  // Cancelar (solo en "recibida"): DELETE /api/reparaciones/{id}
  cancelar(id: number): Observable<Reparacion> {
    return this.http.delete<Reparacion>(`${API}/reparaciones/${id}`);
  }
}
