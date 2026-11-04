// Roles: el cliente usa la app y el técnico ve el panel del taller
export type Rol = 'CLIENTE' | 'TECNICO';

export interface Direccion {
  calle: string;                 // "Gran Vía 12, 3ºB"
  cp: string;                    // "48001"
  ciudad: string;                // "Bilbao"
  provincia: string;             // "Bizkaia"
}

export interface Usuario {
  id: number;
  nombre: string;
  apellido1: string;
  apellido2?: string;
  dni: string;
  telefono: string;
  email: string;
  rol: Rol;
  direccion?: Direccion;
}
