// Pasos del seguimiento (mockup 09), en orden
export type EstadoReparacion = 'RECIBIDA' | 'DIAGNOSTICO' | 'EN_REPARACION' | 'LISTA' | 'ENTREGADA';

// Tipos de dispositivo (mockup 08)
export type TipoDispositivo = 'CONSOLA' | 'MOVIL' | 'TABLET' | 'ORDENADOR' | 'MANDO' | 'AURICULARES' | 'RELOJ' | 'OTRO';

// Los dos departamentos que pide el enunciado
export type Departamento = 'TELEFONIA' | 'CONSOLAS';

export interface PasoReparacion {
  estado: EstadoReparacion;
  fecha: string;                 // AAAA-MM-DD en que se alcanzó el paso
}

export interface Reparacion {
  id: number;
  usuarioId: number;
  clienteNombre: string;         // "Ane E." (lo ve el técnico)
  tipoDispositivo: TipoDispositivo;
  departamento: Departamento;
  marcaModelo: string;           // "Sony DualSense"
  componente: string;            // "Joystick", "Batería"...
  descripcion: string;
  fotos: string[];               // URLs de las fotos hechas con la cámara
  estado: EstadoReparacion;
  presupuesto?: number;          // lo pone el técnico
  tecnico?: string;              // técnico asignado ("Iker Goikoetxea")
  fechaEntrada: string;
  historial: PasoReparacion[];   // pasos ya alcanzados
}

// Textos de cada paso para la línea de tiempo
export const PASOS_REPARACION: { estado: EstadoReparacion; titulo: string; texto: string }[] = [
  { estado: 'RECIBIDA',      titulo: 'Recibida',         texto: 'Tenemos tu dispositivo en el taller.' },
  { estado: 'DIAGNOSTICO',   titulo: 'Diagnóstico',      texto: 'Un técnico está localizando la avería.' },
  { estado: 'EN_REPARACION', titulo: 'En reparación',    texto: 'Estamos sustituyendo o reparando las piezas.' },
  { estado: 'LISTA',         titulo: 'Lista para recoger', texto: 'Ya puedes pasar por la tienda.' },
  { estado: 'ENTREGADA',     titulo: 'Entregada',        texto: 'Reparación finalizada.' },
];

// Teléfonos, tablets y accesorios de audio → Telefonía; el resto → Consolas
export function departamentoDe(tipo: TipoDispositivo): Departamento {
  return ['MOVIL', 'TABLET', 'RELOJ', 'AURICULARES'].includes(tipo) ? 'TELEFONIA' : 'CONSOLAS';
}
