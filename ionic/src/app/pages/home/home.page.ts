import { NombreProductoPipe } from '../../pipes/nombre-producto.pipe';
import { Component, inject, signal } from '@angular/core';
import { RouterLink } from '@angular/router';
import { forkJoin } from 'rxjs';
import { IonHeader, IonContent, IonIcon, IonRefresher, IonRefresherContent, RefresherCustomEvent, IonCard } from '@ionic/angular';
import { addIcons } from 'ionicons';
import { storefrontOutline, timeOutline, chevronForward, arrowForward, buildOutline } from 'ionicons/icons';
import { CabeceraComponent } from '../../components/cabecera/cabecera.component';
import { MiniaturaProductoComponent } from '../../components/miniatura-producto/miniatura-producto.component';
import { PrecioComponent } from '../../components/precio/precio.component';
import { SesionService } from '../../services/sesion.service';
import { AlquilerService } from '../../services/alquiler.service';
import { ReparacionService } from '../../services/reparacion.service';
import { ProductoService } from '../../services/producto.service';
import { NOMBRE_DISPOSITIVO, Reparacion } from '../../models/reparacion.model';
import { Alquiler } from '../../models/alquiler.model';
import { Producto } from '../../models/producto.model';
import { avisoStock } from '../../models/producto.model';

const VUELTA = 2 * Math.PI * 26;   // perímetro del círculo de progreso (radio 26)

@Component({
  selector: 'app-home',
  templateUrl: './home.page.html',
  styleUrls: ['./home.page.scss'],
  imports: [IonCard, RouterLink, IonHeader, IonContent, IonIcon, IonRefresher, IonRefresherContent,
            CabeceraComponent, MiniaturaProductoComponent, PrecioComponent, NombreProductoPipe],
})
export class HomePage {
  // Etiqueta de stock de las novedades (la misma regla que la Tienda y Android)
  aviso = (p: Producto) => avisoStock(p, false);

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
  dispositivo = NOMBRE_DISPOSITIVO;

  constructor() {
    addIcons({ storefrontOutline, timeOutline, chevronForward, arrowForward, buildOutline });
  }

  ionViewWillEnter(): void { this.cargar(); }

  refrescar(evento: RefresherCustomEvent): void {
    this.cargar(() => evento.target.complete());
  }

  private cargar(alTerminar?: () => void): void {
    // Las tres peticiones a la vez (no bloquea la interfaz)
    forkJoin({
      alquileres: this.alquileres.listar('activo', 1, 1),
      reparaciones: this.reparaciones.listar(1, 20),
      novedades: this.productos.listar({ page: 1, limit: 6 }),
    }).subscribe({
      next: ({ alquileres, reparaciones, novedades }) => {
        // La más reciente que siga en el taller (la API las da de la más nueva a la más antigua)
        this.reparacion.set(reparaciones.datos.find(r => r.estado !== 'entregada' && r.estado !== 'cancelada') ?? null);
        this.alquiler.set(alquileres.datos[0] ?? null);
        this.novedades.set(novedades.datos);
        this.cargando.set(false);
        alTerminar?.();
      },
      error: () => { this.cargando.set(false); alTerminar?.(); },
    });
  }

  // Trazo del círculo que queda sin pintar
  hueco(r: Reparacion): number {
    return VUELTA * (1 - r.paso / r.total_pasos);
  }
}
