// Usuario tal como lo devuelve la API (GET /api/yo, login y registro)
export type TipoUsuario = 'cliente' | 'trabajador';

export interface Contadores {
  pedidos: number;
  alquileres_activos: number;
  reparaciones_en_curso: number;
}

export interface Usuario {
  id: number;
  tipo: TipoUsuario;
  nombre: string;
  apellido1: string;
  apellido2?: string | null;
  nombre_completo?: string;      // "Ane Etxeberria"
  iniciales?: string;            // "AE"
  dni: string;
  email: string;
  telefono?: string | null;
  foto_perfil?: string | null;
  activo?: boolean;
  fecha_registro?: string;       // ISO 8601
  contadores?: Contadores;       // solo clientes
}

// Datos del formulario de registro (POST /api/registro)
export interface NuevoUsuario {
  nombre: string;
  apellido1: string;
  apellido2?: string;
  dni: string;
  telefono?: string;
  email: string;
  password: string;
}
