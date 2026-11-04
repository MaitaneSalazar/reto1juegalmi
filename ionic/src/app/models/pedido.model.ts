import { Producto } from './producto.model';

export type EstadoPedido = 'PENDIENTE' | 'PAGADO' | 'ENVIADO' | 'ENTREGADO' | 'CANCELADO';

// Línea guardada en un pedido (precio congelado en el momento de la compra)
export interface LineaPedido {
  productoId: number;
  nombre: string;
  precioUnitario: number;
  cantidad: number;
}

export interface Pedido {
  id: number;
  usuarioId: number;
  fecha: string;                 // AAAA-MM-DD
  lineas: LineaPedido[];
  total: number;
  direccion: string;             // dirección de envío en texto
  estado: EstadoPedido;
}

// Línea de la cesta (antes de confirmar el pedido)
export interface LineaCesta {
  producto: Producto;
  cantidad: number;
}
