// Dirección de envío del cliente (GET /api/domicilios)
export interface DatosDireccion {
  calle: string;
  numero: string;
  piso?: string | null;          // opcional
  codigo_postal: string;         // 5 números
  ciudad: string;
  provincia: string;
}

export interface Domicilio {
  id: number;
  fecha_alta: string;
  fecha_baja: string | null;
  activo: boolean;
  direccion: DatosDireccion;
  texto: string;                 // "Gran Vía 12, 3ºB · Bilbao" (listo para la cesta)
  sustituye_a?: number;          // solo al editar: id del domicilio antiguo (dado de baja)
}
