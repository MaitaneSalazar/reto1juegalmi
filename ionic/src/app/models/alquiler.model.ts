export type EstadoAlquiler = 'ACTIVO' | 'DEVUELTO' | 'VENCIDO';

export interface Alquiler {
  id: number;
  usuarioId: number;
  producto: { id: number; nombre: string; plataforma?: string }; // resumen del videojuego
  fechaInicio: string;           // formato AAAA-MM-DD
  fechaFin: string;              // fecha límite de devolución
  dias: number;
  precioTotal: number;           // dias × precioAlquilerDia
  estado: EstadoAlquiler;
}
