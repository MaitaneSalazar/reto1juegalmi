import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { FUENTE_DATOS } from '../factories/fuente-datos.factory';
import { EstadoReparacion, PASOS_REPARACION, Reparacion, TipoDispositivo, departamentoDe } from '../models/reparacion.model';

// Datos que rellena el cliente en "Nueva reparación"
export interface NuevaReparacion {
  usuarioId: number;
  clienteNombre: string;
  tipoDispositivo: TipoDispositivo;
  marcaModelo: string;
  componente: string;
  descripcion: string;
  fotos: string[];
}

@Injectable({ providedIn: 'root' })
export class ReparacionService {
  private fuente = inject(FUENTE_DATOS);

  // Reparaciones del cliente (Taller · Mis reparaciones)
  delUsuario(usuarioId: number): Observable<Reparacion[]> {
    return this.fuente.listar<Reparacion>('reparaciones', { usuarioId });
  }

  // Panel del técnico: filtrar por estado
  porEstado(estado: EstadoReparacion): Observable<Reparacion[]> {
    return this.fuente.listar<Reparacion>('reparaciones', { estado });
  }

  // Todas (panel del técnico)
  todas(): Observable<Reparacion[]> {
    return this.fuente.listar<Reparacion>('reparaciones');
  }

  // Seguimiento de una reparación
  obtener(id: number): Observable<Reparacion> {
    return this.fuente.obtener<Reparacion>('reparaciones', id);
  }

  // Alta: entra como RECIBIDA con la fecha de hoy
  crear(datos: NuevaReparacion): Observable<Reparacion> {
    const hoy = new Date().toISOString().slice(0, 10);
    return this.fuente.crear<Reparacion>('reparaciones', {
      ...datos,
      departamento: departamentoDe(datos.tipoDispositivo),
      estado: 'RECIBIDA',
      fechaEntrada: hoy,
      historial: [{ estado: 'RECIBIDA', fecha: hoy }],
    });
  }

  // Técnico: pasa al siguiente estado y guarda el presupuesto
  avanzar(rep: Reparacion, presupuesto?: number): Observable<Reparacion> {
    const orden = PASOS_REPARACION.map(p => p.estado);
    const siguiente = orden[Math.min(orden.indexOf(rep.estado) + 1, orden.length - 1)];
    const hoy = new Date().toISOString().slice(0, 10);
    return this.fuente.actualizar<Reparacion>('reparaciones', rep.id, {
      estado: siguiente,
      presupuesto: presupuesto ?? rep.presupuesto,
      historial: [...rep.historial, { estado: siguiente, fecha: hoy }],
    });
  }

  // Baja: cancelar una solicitud
  borrar(id: number): Observable<void> {
    return this.fuente.borrar('reparaciones', id);
  }
}
