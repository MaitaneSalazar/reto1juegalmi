// Reparación tal como la devuelve la API
export type TipoDispositivo = 'consola' | 'movil' | 'tablet' | 'ordenador' | 'mando' | 'auriculares' | 'reloj' | 'otro';
export type EstadoReparacion = 'recibida' | 'diagnostico' | 'en_reparacion' | 'lista_para_recoger' | 'entregada' | 'cancelada';

export interface PasoReparacion {
  estado: EstadoReparacion;
  texto: string;                 // "En reparación"
  hecho: boolean;
  actual: boolean;
  fecha: string | null;
  descripcion: string | null;
}

export interface Reparacion {
  id: number;
  numero: string;                // "Nº 0001"
  tipo_dispositivo: TipoDispositivo;
  marca: string;
  modelo: string;
  estado: EstadoReparacion;
  estado_texto: string;
  paso: number;                  // 3 → "3/5"
  total_pasos: number;
  fecha: string;                 // entrada (ISO 8601)
  se_puede_cancelar: boolean;
  // Solo en el detalle (GET /api/reparaciones/{id})
  componente?: string | null;
  descripcion_averia?: string;
  presupuesto?: number | null;   // null hasta que la tienda lo pone
  fecha_entrega?: string | null; // cuándo se entregó (null si aún no)
  pasos?: PasoReparacion[];
  trabajador?: { nombre_completo: string; cargo: string; telefono: string; departamento: string } | null;
  fotos?: { id: number; url: string; miniatura_url?: string | null; fecha_subida: string }[];
}

// Datos del formulario (POST /api/reparaciones)
export interface NuevaReparacion {
  tipo_dispositivo: TipoDispositivo;
  marca: string;
  modelo: string;
  componente?: string;
  descripcion_averia: string;
}

// "mando" → "Mando"
export const NOMBRE_DISPOSITIVO: Record<TipoDispositivo, string> = {
  consola: 'Consola', movil: 'Móvil', tablet: 'Tablet', ordenador: 'Ordenador',
  mando: 'Mando', auriculares: 'Auriculares', reloj: 'Reloj', otro: 'Otro',
};
