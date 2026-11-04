// Datos de "Sobre nosotros" (mockups 12, 13 y 14)
export interface Tienda {
  nombre: string;
  eslogan: string;               // "Tienda y taller en Bilbao desde 2012."
  direccion: string;
  cp: string;
  ciudad: string;
  telefono: string;
  latitud: number;               // para el mapa
  longitud: number;
  horario: { dias: string; horas: string }[];
  historia: string;              // párrafo de introducción
  hitos: { anio: number; titulo: string; texto: string }[];
  fotos: { titulo: string; url?: string }[]; // sin url → imagen provisional
}
