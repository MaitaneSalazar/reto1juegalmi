import { Injectable, inject } from '@angular/core';
import { Observable } from 'rxjs';
import { FUENTE_DATOS } from '../factories/fuente-datos.factory';
import { Alquiler } from '../models/alquiler.model';
import { Producto } from '../models/producto.model';

@Injectable({ providedIn: 'root' })
export class AlquilerService {
  private fuente = inject(FUENTE_DATOS);

  // Alquileres del usuario (Cuenta y menú lateral)
  delUsuario(usuarioId: number): Observable<Alquiler[]> {
    return this.fuente.listar<Alquiler>('alquileres', { usuarioId });
  }

  // Solo los activos (Inicio · "En curso")
  activos(usuarioId: number): Observable<Alquiler[]> {
    return this.fuente.listar<Alquiler>('alquileres', { usuarioId, estado: 'ACTIVO' });
  }

  // Fecha límite de devolución en formato AAAA-MM-DD
  fechaDevolucion(dias: number, desde = new Date()): string {
    const fin = new Date(desde);
    fin.setDate(fin.getDate() + dias);
    return fin.toISOString().slice(0, 10);
  }

  // Alta de un alquiler (ficha de videojuego)
  crear(producto: Producto, dias: number, usuarioId: number): Observable<Alquiler> {
    return this.fuente.crear<Alquiler>('alquileres', {
      usuarioId,
      producto: { id: producto.id, nombre: producto.nombre, plataforma: producto.plataforma },
      fechaInicio: new Date().toISOString().slice(0, 10),
      fechaFin: this.fechaDevolucion(dias),
      dias,
      precioTotal: +(dias * (producto.precioAlquilerDia ?? 0)).toFixed(2),
      estado: 'ACTIVO',
    });
  }

  // Modificación: devolver el juego
  devolver(id: number): Observable<Alquiler> {
    return this.fuente.actualizar<Alquiler>('alquileres', id, { estado: 'DEVUELTO' });
  }
}
