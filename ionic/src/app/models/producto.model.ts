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

// Color de la portada generada (cuando la API manda imagen_url: null)
export const COLOR_PLATAFORMA: Record<string, string> = {
  PlayStation: '#375e60', PS5: '#375e60', Xbox: '#5c616c', Switch: '#5ea0a2', Multi: '#8a8c84',
};
export const COLOR_PORTADA = '#1f2329';          // consolas, móviles, tablets y sin plataforma

// Plataforma del juego. La API manda una por producto ("PlayStation", "Switch", "Xbox"): un juego de
// varias plataformas viene repetido, uno por cada una. "Multi" (antiguo) = las tres
export const PLATAFORMAS = ['PlayStation', 'Xbox', 'Switch'] as const;
export function plataformasDe(p: { plataforma?: string | null; plataformas?: string[] }): string[] {
  if (p.plataformas?.length) return p.plataformas;
  if (!p.plataforma) return [];
  return p.plataforma.trim().toLowerCase() === 'multi' ? [...PLATAFORMAS] : [p.plataforma.trim()];
}
// Xbox verde · PlayStation azul · Switch rojo. Se reconoce como venga escrito
// ("PS5", "PS4", "PlayStation 5", "ps5", "Nintendo Switch", "Xbox Series"...)
// Nombre para enseñar: la API manda "Switch" y "PS5" (igual que Plataforma.nombre() en Android)
export function nombrePlataforma(codigo: string): string {
  if (codigo === 'Switch') return 'Nintendo Switch';
  if (codigo === 'PS5') return 'PlayStation';
  return codigo;
}

export function colorPlataforma(plataforma: string): string {
  const t = plataforma.toLowerCase();
  if (t.includes('xbox')) return '#107c10';                              // verde
  if (t.includes('ps') || t.includes('playstation')) return '#0070d1';   // azul
  if (t.includes('switch') || t.includes('nintendo')) return '#e60012';  // rojo
  return '#5c616c';                                                      // otra: gris
}

// Etiqueta de stock: «Quedan 2», «Última unidad», «Agotado» (en alquiler: «Última copia», «Alquilado»)
export interface EtiquetaStock { texto: string; tipo: 'aviso' | 'off'; }
export function etiquetaStock(n: number, alquiler = false): EtiquetaStock | null {
  if (n <= 0) return { texto: alquiler ? 'Alquilado' : 'Agotado', tipo: 'off' };
  if (n === 1) return { texto: alquiler ? 'Última copia' : 'Última unidad', tipo: 'aviso' };
  if (n === 2) return { texto: 'Quedan 2', tipo: 'aviso' };
  return null;                                   // 3 o más: sin etiqueta
}

// Etiqueta de stock de las tarjetas (la misma regla que ProductoAdapter.pintarAviso() de Android)
export function avisoStock(p: Producto, alquiler: boolean): { texto: string; agotado: boolean } | null {
  const quedan = alquiler ? (p.copias_disponibles ?? 0) : p.stock;
  // Al alquilar solo cuentan las copias: "disponible" de la API solo mira el stock de venta
  if (quedan <= 0 || (!alquiler && !p.disponible)) return { texto: alquiler ? 'Alquilado' : 'Agotado', agotado: true };
  if (quedan === 1) return { texto: alquiler ? 'Última copia' : 'Última unidad', agotado: false };
  if (quedan === 2) return { texto: 'Quedan 2', agotado: false };
  return null;
}

// Un videojuego se puede alquilar si tiene precio por día
export function esAlquilable(p: Producto): boolean {
  return p.tipo === 'videojuego' && p.precio_alquiler_dia != null;
}
