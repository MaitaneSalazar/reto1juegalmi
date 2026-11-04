import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { FUENTE_DATOS } from '../factories/fuente-datos.factory';
import { LineaCesta, Pedido } from '../models/pedido.model';

@Injectable({ providedIn: 'root' })
export class PedidoService {
  private fuente = inject(FUENTE_DATOS);

  // Pedidos del usuario (menú lateral · Mis pedidos)
  delUsuario(usuarioId: number): Observable<Pedido[]> {
    return this.fuente.listar<Pedido>('pedidos', { usuarioId });
  }

  // Alta del pedido al pulsar "Confirmar pedido" en la cesta
  crear(lineas: LineaCesta[], usuarioId: number, direccion: string): Observable<Pedido> {
    const total = lineas.reduce((suma, l) => suma + l.producto.precio * l.cantidad, 0);
    return this.fuente.crear<Pedido>('pedidos', {
      usuarioId,
      fecha: new Date().toISOString().slice(0, 10),
      lineas: lineas.map(l => ({
        productoId: l.producto.id,
        nombre: l.producto.nombre,
        precioUnitario: l.producto.precio,
        cantidad: l.cantidad,
      })),
      total: +total.toFixed(2),
      direccion,
      estado: 'PAGADO',
    });
  }
}
