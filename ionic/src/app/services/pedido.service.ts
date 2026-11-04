import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';
import { LineaCesta, Pedido, PedidoResumen } from '../models/pedido.model';
import { Pagina } from '../models/pagina.model';

const API = environment.apiUrl;

@Injectable({ providedIn: 'root' })
export class PedidoService {
  private http = inject(HttpClient);

  // Cesta · "Confirmar pedido": POST /api/pedidos (todo o nada; sin stock → 409)
  crear(idDomicilio: number, lineas: LineaCesta[]): Observable<Pedido> {
    return this.http.post<Pedido>(`${API}/pedidos`, {
      id_domicilio: idDomicilio,
      lineas: lineas.map(l => ({ id_producto: l.producto.id, cantidad: l.cantidad })),
    });
  }

  // Mis pedidos: GET /api/pedidos (el más reciente primero)
  listar(page = 1, limit = 50): Observable<Pagina<PedidoResumen>> {
    return this.http.get<Pagina<PedidoResumen>>(`${API}/pedidos`, { params: { page, limit } });
  }

  // Detalle: GET /api/pedidos/{id}
  obtener(id: number): Observable<Pedido> {
    return this.http.get<Pedido>(`${API}/pedidos/${id}`);
  }

  // PUT /api/pedidos/{id}/cancelar (solo pendiente o pagado)
  cancelar(id: number): Observable<Pedido> {
    return this.http.put<Pedido>(`${API}/pedidos/${id}/cancelar`, {});
  }
}
