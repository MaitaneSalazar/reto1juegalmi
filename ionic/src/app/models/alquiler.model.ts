import { Producto } from './producto.model';

export type EstadoAlquiler = 'activo' | 'retrasado' | 'devuelto';

export interface LineaAlquiler {
  id: number;
  videojuego: Producto;
  precio_dia: number;
  fecha_devolucion: string | null;
  devuelto: boolean;
  dias: number;
  importe: number;
}

// Alquiler tal como lo devuelve la API
export interface Alquiler {
  id: number;
  fecha_inicio: string;          // AAAA-MM-DD
  fecha_fin_prevista: string;    // AAAA-MM-DD
  estado: EstadoAlquiler;
  dias_restantes: number;        // negativo = días de retraso
  importe: number;
  lineas: LineaAlquiler[];
}
