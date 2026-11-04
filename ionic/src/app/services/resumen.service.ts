import { Injectable, inject, signal } from '@angular/core';
import { forkJoin } from 'rxjs';
import { SesionService } from './sesion.service';
import { PedidoService } from './pedido.service';
import { AlquilerService } from './alquiler.service';
import { ReparacionService } from './reparacion.service';
import { Alquiler } from '../models/alquiler.model';

@Injectable({ providedIn: 'root' })
export class ResumenService {
  private sesion = inject(SesionService);
  private pedidosSrv = inject(PedidoService);
  private alquileresSrv = inject(AlquilerService);
  private reparacionesSrv = inject(ReparacionService);

  readonly pedidos = signal(0);
  readonly alquileresActivos = signal(0);
  readonly reparacionesEnCurso = signal(0);
  readonly alquilerActivo = signal<Alquiler | null>(null);   // el que se muestra en Cuenta

  // Recalcula los contadores (se llama al abrir el menú y al entrar en Cuenta)
  refrescar(): void {
    const id = this.sesion.usuario()?.id;
    if (!id) return;
    forkJoin({
      pedidos: this.pedidosSrv.delUsuario(id),
      alquileres: this.alquileresSrv.activos(id),
      reparaciones: this.reparacionesSrv.delUsuario(id),
    }).subscribe(({ pedidos, alquileres, reparaciones }) => {
      this.pedidos.set(pedidos.length);
      this.alquileresActivos.set(alquileres.length);
      this.alquilerActivo.set(alquileres[0] ?? null);
      this.reparacionesEnCurso.set(reparaciones.filter(r => r.estado !== 'ENTREGADA').length);
    });
  }
}
