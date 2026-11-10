import { Component, inject, signal } from '@angular/core';
import { Router, RouterLink } from '@angular/router';
import { IonHeader, IonToolbar, IonButtons, IonBackButton, IonContent, IonFooter, IonButton, IonIcon,
         AlertController, ToastController, IonList, IonCard } from '@ionic/angular';
import { addIcons } from 'ionicons';
import { locationOutline, pencilOutline, trashOutline, add, checkmarkCircle } from 'ionicons/icons';
import { SesionService } from '../../services/sesion.service';
import { DomicilioService } from '../../services/domicilio.service';
import { Domicilio } from '../../models/domicilio.model';
import { EstadoComponent } from '../../components/estado/estado.component';
import { LottieComponent } from '../../components/lottie/lottie.component';

@Component({
  selector: 'app-direcciones',
  templateUrl: './direcciones.page.html',
  styleUrls: ['../subpagina.scss', './direcciones.page.scss'],
  imports: [LottieComponent, EstadoComponent, IonList, IonCard, RouterLink, IonHeader, IonToolbar, IonButtons, IonBackButton, IonContent, IonFooter, IonButton, IonIcon],
})
export class DireccionesPage {
  domicilios = inject(DomicilioService);
  private sesion = inject(SesionService);
  private router = inject(Router);
  private alerta = inject(AlertController);
  private toast = inject(ToastController);

  cargando = signal(true);

  constructor() {
    addIcons({ locationOutline, pencilOutline, trashOutline, add, checkmarkCircle });
  }

  // GET /api/domicilios (activos, el más reciente primero)
  ionViewWillEnter(): void {
    this.domicilios.cargar().subscribe({
      next: () => this.cargando.set(false),
      error: e => { this.cargando.set(false); this.aviso(this.sesion.mensaje(e)); },
    });
  }

  esElegido(d: Domicilio): boolean {
    return this.domicilios.elegido()?.id === d.id;
  }

  // Tocar la tarjeta = usarla para enviar los pedidos
  elegir(d: Domicilio): void {
    this.domicilios.elegir(d.id);
    this.aviso('Enviaremos tus pedidos aquí');
  }

  editar(d: Domicilio, e: Event): void {
    e.stopPropagation();
    this.router.navigate(['/cuenta/direcciones', d.id]);
  }

  // DELETE /api/domicilios/{id}: baja lógica (los pedidos antiguos la conservan)
  async borrar(d: Domicilio, e: Event): Promise<void> {
    e.stopPropagation();
    const alerta = await this.alerta.create({
      header: 'Borrar dirección',
      message: `¿Seguro que quieres borrar ${d.texto}?`,
      buttons: [
        { text: 'Cancelar', role: 'cancel' },
        { text: 'Borrar', role: 'destructive', handler: () => {
          this.domicilios.borrar(d.id).subscribe({
            next: () => { this.aviso('Dirección borrada.'); this.domicilios.cargar().subscribe(); },
            error: err => this.aviso(this.sesion.mensaje(err)),
          });
        } },
      ],
    });
    await alerta.present();
  }

  private async aviso(m: string): Promise<void> {
    const t = await this.toast.create({ message: m, duration: 2000 });
    await t.present();
  }
}
