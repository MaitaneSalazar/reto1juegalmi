import { Router } from '@angular/router';
import { Component, computed, inject, signal } from '@angular/core';
import { IonHeader, IonToolbar, IonButtons, IonBackButton, IonContent, AlertController, ToastController, IonList, IonCard } from '@ionic/angular';
import { EstadoComponent } from '../../components/estado/estado.component';
import { MiniaturaProductoComponent } from '../../components/miniatura-producto/miniatura-producto.component';
import { PrecioComponent } from '../../components/precio/precio.component';
import { FechaCortaPipe } from '../../pipes/fecha-corta.pipe';
import { AlquilerService } from '../../services/alquiler.service';
import { SesionService } from '../../services/sesion.service';
import { ResumenService } from '../../services/resumen.service';
import { Alquiler } from '../../models/alquiler.model';
import { LottieComponent } from '../../components/lottie/lottie.component';
import { alAgitar } from '../../services/agitar.service';

const DIA = 86400000;

@Component({
  selector: 'app-alquileres',
  templateUrl: './alquileres.page.html',
  styleUrls: ['../subpagina.scss', './alquileres.page.scss'],
  imports: [LottieComponent, IonList, IonCard, IonHeader, IonToolbar, IonButtons, IonBackButton, IonContent, EstadoComponent, MiniaturaProductoComponent, PrecioComponent, FechaCortaPipe],
})
export class AlquileresPage {
  private agitar = alAgitar(() => { this.cargando.set(true); this.cargar(); });   // agitar el móvil = recargar esta pantalla (como Android)
  private router = inject(Router);
  irATienda(): void { this.router.navigateByUrl('/tienda'); }

  private servicio = inject(AlquilerService);
  private sesion = inject(SesionService);
  private resumen = inject(ResumenService);
  private alerta = inject(AlertController);
  private toast = inject(ToastController);

  todos = signal<Alquiler[]>([]);
  cargando = signal(true);
  error = signal(false);                     // sin conexión → Reintentar

  activos = computed(() => this.todos().filter(a => a.estado !== 'devuelto'));     // activo o retrasado
  devueltos = computed(() => this.todos().filter(a => a.estado === 'devuelto'));


  ionViewWillEnter(): void {
    this.cargar();
  }

  // Parte del alquiler ya consumida (0 a 1) para la barra
  progreso(a: Alquiler): number {
    const total = this.fecha(a.fecha_fin_prevista) - this.fecha(a.fecha_inicio);
    if (total <= 0) return 1;
    return Math.min(1, Math.max(0, (this.hoy() - this.fecha(a.fecha_inicio)) / total));
  }

  async devolver(a: Alquiler): Promise<void> {
    const alerta = await this.alerta.create({
      header: '¿Devolver el juego?',
      message: `Se marcará ${this.titulo(a)} como devuelto.`,
      buttons: [
        { text: 'Devolver', handler: () => {
          this.servicio.devolver(a.id).subscribe({
            next: () => { this.cargar(); this.resumen.refrescar(); this.aviso('Juego devuelto'); },
            error: e => this.aviso(this.sesion.mensaje(e)),
          });
        } },
        { text: 'Cancelar', role: 'cancel' },
      ],
    });
    await alerta.present();
  }

  // "Elden Ring" o "Elden Ring +1" si el alquiler tiene varios juegos
  titulo(a: Alquiler): string {
    const n = a.lineas[0]?.videojuego.nombre ?? 'Alquiler';          // sin plataforma, como Android
    return a.lineas.length > 1 ? `${n} +${a.lineas.length - 1}` : n;
  }

  // Fecha real de devolución (la de la última línea devuelta)
  devueltoEl(a: Alquiler): string {
    return a.lineas.map(l => l.fecha_devolucion ?? '').sort().at(-1) || a.fecha_fin_prevista;
  }

  // GET /api/alquileres (el más reciente primero)
  cargar(): void {
    this.error.set(false);
    this.servicio.listar().subscribe({
      next: r => { this.todos.set(r.datos); this.cargando.set(false); },
      error: () => { this.cargando.set(false); this.error.set(true); },
    });
  }

  private async aviso(mensaje: string): Promise<void> {
    const t = await this.toast.create({ message: mensaje, duration: 2500 });
    await t.present();
  }

  private fecha(s: string): number { return new Date(s.slice(0, 10) + 'T00:00:00').getTime(); }
  private hoy(): number { const d = new Date(); d.setHours(0, 0, 0, 0); return d.getTime(); }
}
