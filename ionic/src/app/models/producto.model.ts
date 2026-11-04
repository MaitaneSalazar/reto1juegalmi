// Tipos de producto que vende la tienda
export type TipoProducto = 'VIDEOJUEGO' | 'CONSOLA' | 'MOVIL' | 'TABLET';

export interface Producto {
  id: number;
  nombre: string;
  marca: string;                 // Nintendo, Sony, Samsung...
  tipo: TipoProducto;
  plataforma?: string;           // solo videojuegos: Switch, PS5, Xbox, Multi
  descripcion: string;
  genero?: string;               // solo videojuegos
  pegi?: number;                 // solo videojuegos
  precio: number;                // precio de venta
  alquilable: boolean;           // true si se puede alquilar
  precioAlquilerDia?: number;    // solo si es alquilable
  stock: number;                 // unidades disponibles
  stockTotal: number;            // unidades totales ("2 de 3" en la ficha)
  imagenUrl?: string;            // sin imagen → icono provisional
}

// Texto de cada tipo
export const NOMBRE_TIPO: Record<TipoProducto, string> = {
  VIDEOJUEGO: 'Videojuego',
  CONSOLA: 'Consola',
  MOVIL: 'Móvil',
  TABLET: 'Tablet',
};

// Icono provisional de cada tipo (mientras no hay foto o mientras carga)
export const ICONO_TIPO: Record<TipoProducto, string> = {
  VIDEOJUEGO: 'disc-outline',
  CONSOLA: 'game-controller-outline',
  MOVIL: 'phone-portrait-outline',
  TABLET: 'tablet-portrait-outline',
};

// "Nintendo · Switch" (videojuego) o "Sony · Consola" (resto)
export function subtituloProducto(p: Producto): string {
  return `${p.marca} · ${p.plataforma ?? NOMBRE_TIPO[p.tipo]}`;
}
