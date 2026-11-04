import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, shareReplay } from 'rxjs';
import { environment } from '../../environments/environment';
import { FotoTienda, Tienda } from '../models/tienda.model';

const API = environment.apiUrl;

@Injectable({ providedIn: 'root' })
export class TiendaService {
  private http = inject(HttpClient);

  // Se piden una vez y se reutilizan (no cambian mientras se usa la app)
  private tienda$ = this.http.get<Tienda>(`${API}/tienda`).pipe(shareReplay(1));
  private fotos$ = this.http.get<FotoTienda[]>(`${API}/tienda/fotos`).pipe(shareReplay(1));

  obtener(): Observable<Tienda> { return this.tienda$; }
  fotos(): Observable<FotoTienda[]> { return this.fotos$; }
}
