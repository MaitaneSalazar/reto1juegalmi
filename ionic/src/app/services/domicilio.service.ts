import { Injectable, inject, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, map, tap } from 'rxjs';
import { environment } from '../../environments/environment';
import { DatosDireccion, Domicilio } from '../models/domicilio.model';
import { Pagina, soloDatos } from '../models/pagina.model';

const API = environment.apiUrl;
const CLAVE = 'juegalmi_domicilio';    // domicilio elegido para la cesta (localStorage)

@Injectable({ providedIn: 'root' })
export class DomicilioService {
  private http = inject(HttpClient);

  readonly lista = signal<Domicilio[]>([]);                 // domicilios activos
  readonly elegidoId = signal<number | null>(this.leer());  // el que usa la cesta

  // GET /api/domicilios (activos, el más reciente primero)
  cargar(): Observable<Domicilio[]> {
    return this.http.get<Domicilio[] | Pagina<Domicilio>>(`${API}/domicilios`).pipe(
      map(r => soloDatos(r)),
      tap(l => this.lista.set(l)),
    );
  }

  // El de la cesta: el elegido o, si no hay, el primero
  elegido(): Domicilio | null {
    const l = this.lista();
    return l.find(d => d.id === this.elegidoId()) ?? l[0] ?? null;
  }

  elegir(id: number): void {
    this.elegidoId.set(id);
    try { localStorage.setItem(CLAVE, String(id)); } catch { /* sin almacenamiento */ }
  }

  // POST /api/domicilios → 201 con el domicilio nuevo
  crear(d: DatosDireccion): Observable<Domicilio> {
    return this.http.post<Domicilio>(`${API}/domicilios`, d);
  }

  // PUT /api/domicilios/{id} con solo lo que cambia. La API da de baja el antiguo y crea
  // uno nuevo (otro id, "sustituye_a" = id antiguo): si era el de la cesta, pasa a ser el nuevo
  editar(id: number, cambios: Partial<DatosDireccion>): Observable<Domicilio> {
    return this.http.put<Domicilio>(`${API}/domicilios/${id}`, cambios).pipe(
      tap(nuevo => { if (this.elegidoId() === (nuevo.sustituye_a ?? id)) this.elegir(nuevo.id); }),
    );
  }

  // DELETE /api/domicilios/{id} → baja (los pedidos antiguos lo conservan)
  borrar(id: number): Observable<unknown> {
    return this.http.delete(`${API}/domicilios/${id}`);
  }

  private leer(): number | null {
    try { const v = localStorage.getItem(CLAVE); return v ? Number(v) : null; } catch { return null; }
  }
}
