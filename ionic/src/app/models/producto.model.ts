// Producto tal como lo devuelve la API (tarjeta del listado + datos de la ficha)
export type TipoProducto = 'videojuego' | 'consola' | 'movil' | 'tablet';

export interface Producto {
  id: number;
  tipo: TipoProducto;
  nombre: string;
  empresa: string;               // Nintendo, Sony...
  precio_venta: number;
  stock: number;
  disponible: boolean;
  imagen_url: string | null;     // null → imagen provisional
  miniatura_url?: string | null; // ~400 px, para listados
  plataforma?: string;           // videojuegos
  precio_alquiler_dia?: number | null;
  alquilado?: boolean;           // listado de alquiler: no queda copia libre
  // Ficha (GET /api/productos/{id})
  descripcion?: string;
  genero?: string;
  pegi?: number;
  copias_alquiler?: number;
  copias_disponibles?: number;
  almacenamiento_gb?: number;
  color?: string;
  edicion?: string;
  pantalla_pulgadas?: number;
  ram_gb?: number;
  sistema_operativo?: string;
  bateria_mah?: number;
  conectividad?: string;
}

// Texto de cada tipo
export const NOMBRE_TIPO: Record<TipoProducto, string> = {
  videojuego: 'Videojuego',
  consola: 'Consola',
  movil: 'Móvil',
  tablet: 'Tablet',
};

// Icono provisional de cada tipo (mientras no hay foto o mientras carga)
export const ICONO_TIPO: Record<TipoProducto, string> = {
  videojuego: 'disc-outline',
  consola: 'game-controller-outline',
  movil: 'phone-portrait-outline',
  tablet: 'tablet-portrait-outline',
};

// Un videojuego se puede alquilar si tiene precio por día
export function esAlquilable(p: Producto): boolean {
  return p.tipo === 'videojuego' && p.precio_alquiler_dia != null;
}
