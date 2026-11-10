import { Domicilio } from './domicilio.model';
import { Producto } from './producto.model';

export type EstadoPedido = 'pendiente' | 'pagado' | 'enviado' | 'entregado' | 'cancelado';

// Pedido en el listado (GET /api/pedidos)
export interface PedidoResumen {
  id: number;
  fecha: string;                 // ISO 8601
  estado: EstadoPedido;
  total: number;
  unidades: number;
  primer_producto: string;
  imagen_url: string | null;
  se_puede_cancelar: boolean;
}

// Pedido completo (GET /api/pedidos/{id})
export interface Pedido extends PedidoResumen {
  domicilio: Domicilio;
  lineas: LineaPedido[];
}
export interface LineaPedido { id: number; producto: Producto; cantidad: number; precio_unitario: number; subtotal: number; }

// Línea de la cesta (antes de confirmar el pedido; vive solo en la app)
export interface LineaCesta {
  producto: Producto;
  cantidad: number;
  alquiler?: boolean;            // true = alquiler; se guarda en localStorage igual que el resto
  dias?: number;                 // solo en los alquileres
}
