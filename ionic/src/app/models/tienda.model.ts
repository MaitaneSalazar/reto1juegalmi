// Datos de la tienda (GET /api/tienda)
export interface Tienda {
  nombre: string;
  telefono: string;
  email: string;
  latitud: number;
  longitud: number;
  direccion_linea1: string;      // "Gran Vía 12, bajo"
  direccion_linea2: string;      // "48001 Bilbao, Bizkaia"
}

// Foto de la galería (GET /api/tienda/fotos)
export interface FotoTienda {
  id: number;
  titulo: string;
  url: string | null;
}

// Horario e historia: la API no los devuelve, van escritos en la app
export const HORARIO = [
  { dias: 'Lunes a viernes', horas: '10:00 – 20:30' },
  { dias: 'Sábados', horas: '10:00 – 14:00' },
];

export const HISTORIA = 'JuegAlmi nació de la afición de dos amigos por los videojuegos y la electrónica. '
  + 'Hoy somos tienda, alquiler y taller, con el mismo trato cercano del primer día.';

export const HITOS = [
  { anio: 2012, titulo: 'Abrimos en Bilbao', texto: 'Un pequeño local en Gran Vía dedicado a la compraventa de videojuegos de segunda mano.', icono: 'storefront-outline' },
  { anio: 2015, titulo: 'Nace el taller', texto: 'Empezamos a reparar consolas y mandos en la trastienda, con un único técnico.', icono: 'build-outline' },
  { anio: 2018, titulo: 'Llegan los móviles', texto: 'Ampliamos la tienda con venta y reparación de móviles y tablets.', icono: 'phone-portrait-outline' },
  { anio: 2026, titulo: 'Lanzamos la app', texto: 'Compra, alquila y repara desde el móvil.', icono: 'rocket-outline' },
];

// Galería de respaldo si la API todavía no tiene fotos (assets/tienda/1-5.png)
export const FOTOS_LOCALES: FotoTienda[] = [
  { id: 1, titulo: 'Fachada', url: 'assets/tienda/1.png' },
  { id: 2, titulo: 'Mostrador', url: 'assets/tienda/2.png' },
  { id: 3, titulo: 'Zona de videojuegos', url: 'assets/tienda/3.png' },
  { id: 4, titulo: 'Taller', url: 'assets/tienda/4.png' },
  { id: 5, titulo: 'Zona de consolas', url: 'assets/tienda/5.png' },
];
