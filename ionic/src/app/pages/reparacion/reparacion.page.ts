import { Component, computed, inject, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { ActivatedRoute } from '@angular/router';
import { IonHeader, IonToolbar, IonButtons, IonBackButton, IonContent, IonIcon, IonButton,
         IonRefresher, IonRefresherContent, RefresherCustomEvent,
         AlertController, ToastController } from '@ionic/angular';
import { addIcons } from 'ionicons';
import { imageOutline, callOutline } from 'ionicons/icons';
import { ReparacionService } from '../../services/reparacion.service';
import { SesionService } from '../../services/sesion.service';
import { NOMBRE_DISPOSITIVO, Reparacion } from '../../models/reparacion.model';
import { LottieComponent } from '../../components/lottie/lottie.component';
import { alAgitar } from '../../services/agitar.service';

@Component({
  selector: 'app-reparacion',
  templateUrl: './reparacion.page.html',
  styleUrls: ['./reparacion.page.scss'],
  imports: [LottieComponent, IonHeader, IonToolbar, IonButtons, IonBackButton, IonContent, IonIcon, IonButton,
            IonRefresher, IonRefresherContent],
})
export class ReparacionPage {
  private agitar = alAgitar(() => this.cargar());   // agitar el móvil = recargar esta pantalla (como Android)
  private servicio = inject(ReparacionService);
  private sesion = inject(SesionService);
  private alerta = inject(AlertController);
  private toast = inject(ToastController);
  private id = 0;

  rep = signal<Reparacion | null>(null);
  cancelando = signal(false);

  tipo = computed(() => NOMBRE_DISPOSITIVO[this.rep()?.tipo_dispositivo ?? 'otro']);
  // Solo el teléfono del técnico, como en Android: sin técnico no hay botón de llamar
  telefono = computed(() => {
    const t = this.rep()?.trabajador?.telefono;
    return t ? `tel:${t.replace(/\s/g, '')}` : null;
  });

  // Presupuesto partido como Android: «120» grande y «,00 €» pequeño
  euros(v: number): string { return Math.trunc(v).toLocaleString('es-ES'); }
  centimos(v: number): string { return ',' + v.toFixed(2).split('.')[1] + ' €'; }

  constructor() {
    addIcons({ imageOutline, callOutline });
    inject(ActivatedRoute).paramMap.pipe(takeUntilDestroyed()).subscribe(p => {
      this.id = Number(p.get('id'));
      this.cargar();
    });
  }

  refrescar(e: RefresherCustomEvent): void {
    this.cargar(() => e.target.complete());
  }

  // DELETE /api/reparaciones/{id} (solo en "recibida": se_puede_cancelar)
  async cancelar(): Promise<void> {
    const a = await this.alerta.create({
      header: '¿Cancelar la solicitud?',
      message: 'Solo se puede cancelar mientras no hayamos empezado a revisarla.',
      buttons: [
        { text: 'Sí, cancelar', role: 'destructive', handler: () => this.confirmarCancelar() },
        { text: 'No', role: 'cancel' },
      ],
    });
    await a.present();
  }

  private confirmarCancelar(): void {
    this.cancelando.set(true);
    this.servicio.cancelar(this.id).subscribe({
      next: r => { this.cancelando.set(false); this.rep.set(r); this.aviso('Solicitud cancelada'); },
      error: e => { this.cancelando.set(false); this.aviso(this.sesion.mensaje(e)); },
    });
  }

  private cargar(alTerminar?: () => void): void {
    this.servicio.obtener(this.id).subscribe({
      next: r => { this.rep.set(r); alTerminar?.(); },
      error: () => alTerminar?.(),
    });
  }

  private async aviso(mensaje: string): Promise<void> {
    const t = await this.toast.create({ message: mensaje, duration: 3000, position: 'bottom' });
    await t.present();
  }
}
