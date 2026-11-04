import { Component, inject, signal } from '@angular/core';
import { RouterLink } from '@angular/router';
import { forkJoin } from 'rxjs';
import { IonHeader, IonContent, IonIcon, IonSkeletonText,
         IonRefresher, IonRefresherContent, RefresherCustomEvent } from '@ionic/angular';
import { addIcons } from 'ionicons';
import { storefrontOutline, timeOutline, chevronForward, arrowForward, buildOutline } from 'ionicons/icons';
import { CabeceraComponent } from '../../components/cabecera/cabecera.component';
import { MiniaturaProductoComponent } from '../../components/miniatura-producto/miniatura-producto.component';
import { PrecioComponent } from '../../components/precio/precio.component';
import { SesionService } from '../../services/sesion.service';
import { AlquilerService } from '../../services/alquiler.service';
import { ReparacionService } from '../../services/reparacion.service';
import { ProductoService } from '../../services/producto.service';
import { PASOS_REPARACION, Reparacion } from '../../models/reparacion.model';
import { Alquiler } from '../../models/alquiler.model';
import { Producto } from '../../models/producto.model';

const VUELTA = 2 * Math.PI * 26;   // perímetro del círculo de progreso (radio 26)

@Component({
  selector: 'app-home',
  templateUrl: './home.page.html',
  styleUrls: ['./home.page.scss'],
  imports: [RouterLink, IonHeader, IonContent, IonIcon, IonSkeletonText, IonRefresher, IonRefresherContent,
            CabeceraComponent, MiniaturaProductoComponent, PrecioComponent],
})
export class HomePage {
  sesion = inject(SesionService);
  private alquileres = inject(AlquilerService);
  private reparaciones = inject(ReparacionService);
  private productos = inject(ProductoService);

  cargando = signal(true);
  reparacion = signal<Reparacion | null>(null);   // la reparación en curso más reciente
  alquiler = signal<Alquiler | null>(null);       // el alquiler activo
  novedades = signal<Producto[]>([]);

  categorias = ['Consolas', 'Móviles', 'Mandos', 'Tablets'];
  vuelta = VUELTA;

  constructor() {
    addIcons({ storefrontOutline, timeOutline, chevronForward, arrowForward, buildOutline });
  }

  ionViewWillEnter(): void { this.cargar(); }

  refrescar(evento: RefresherCustomEvent): void {
    this.cargar(() => evento.target.complete());
  }

  private cargar(alTerminar?: () => void): void {
    const id = this.sesion.usuario()?.id;
    if (!id) return;

    // Todo a la vez (no bloquea la interfaz)
    forkJoin({
      alquileres: this.alquileres.activos(id),
      reparaciones: this.reparaciones.delUsuario(id),
      novedades: this.productos.listar({ page: 1, limit: 6 }),
    }).subscribe({
      next: ({ alquileres, reparaciones, novedades }) => {
        const enCurso = reparaciones.filter(r => r.estado !== 'ENTREGADA');
        this.reparacion.set(enCurso[enCurso.length - 1] ?? null);
        this.alquiler.set(alquileres[0] ?? null);
        this.novedades.set(novedades);
        this.cargando.set(false);
        alTerminar?.();
      },
      error: () => { this.cargando.set(false); alTerminar?.(); },
    });
  }

  // ----- Ayudas para la plantilla
  paso(r: Reparacion): number {
    return PASOS_REPARACION.findIndex(p => p.estado === r.estado) + 1;   // 1..5
  }
  // Trazo del círculo: cuánto queda sin pintar
  hueco(r: Reparacion): number {
    return VUELTA * (1 - this.paso(r) / PASOS_REPARACION.length);
  }
  estado(r: Reparacion): string {
    return PASOS_REPARACION.find(p => p.estado === r.estado)?.titulo ?? r.estado;
  }
  tipo(r: Reparacion): string {
    return r.tipoDispositivo.charAt(0) + r.tipoDispositivo.slice(1).toLowerCase();
  }
  // Días que faltan para devolver (0 si vence hoy)
  diasRestantes(a: Alquiler): number {
    const hoy = new Date(); hoy.setHours(0, 0, 0, 0);
    return Math.max(0, Math.round((new Date(a.fechaFin + 'T00:00:00').getTime() - hoy.getTime()) / 86400000));
  }
}
