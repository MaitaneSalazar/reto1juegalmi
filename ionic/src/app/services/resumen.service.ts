import { Injectable, inject, signal } from '@angular/core';
import { SesionService } from './sesion.service';
import { AlquilerService } from './alquiler.service';
import { Alquiler } from '../models/alquiler.model';

// Contadores del menú y de Cuenta: vienen en GET /api/yo
@Injectable({ providedIn: 'root' })
export class ResumenService {
  private sesion = inject(SesionService);
  private alquileres = inject(AlquilerService);

  readonly pedidos = signal(0);
  readonly alquileresActivos = signal(0);
  readonly reparacionesEnCurso = signal(0);
  readonly alquilerActivo = signal<Alquiler | null>(null);   // tarjeta de Cuenta

  // Se llama al abrir el menú y al entrar en Cuenta
  refrescar(): void {
    if (!this.sesion.logueado()) return;
    this.sesion.refrescar().subscribe({
      next: u => {
        this.pedidos.set(u.contadores?.pedidos ?? 0);
        this.alquileresActivos.set(u.contadores?.alquileres_activos ?? 0);
        this.reparacionesEnCurso.set(u.contadores?.reparaciones_en_curso ?? 0);
      },
      error: () => { /* sin conexión: se quedan los últimos valores */ },
    });
    this.alquileres.listar('activo', 1, 1).subscribe({
      next: r => this.alquilerActivo.set(r.datos[0] ?? null),
      error: () => this.alquilerActivo.set(null),
    });
  }
}
