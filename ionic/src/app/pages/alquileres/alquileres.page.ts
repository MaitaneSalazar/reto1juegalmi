import { Component, computed, inject, signal } from '@angular/core';
import { IonHeader, IonToolbar, IonButtons, IonBackButton, IonTitle, IonContent, IonSegment, IonSegmentButton,
         IonLabel, IonButton, IonSkeletonText, AlertController, ToastController } from '@ionic/angular';
import { EurosPipe } from '../../pipes/euros.pipe';
import { AlquilerService } from '../../services/alquiler.service';
import { SesionService } from '../../services/sesion.service';
import { ResumenService } from '../../services/resumen.service';
import { Alquiler } from '../../models/alquiler.model';

@Component({
  selector: 'app-alquileres',
  templateUrl: './alquileres.page.html',
  styleUrls: ['../cuenta/subpagina.scss', './alquileres.page.scss'],
  imports: [IonHeader, IonToolbar, IonButtons, IonBackButton, IonTitle, IonContent, IonSegment, IonSegmentButton,
            IonLabel, IonButton, IonSkeletonText, EurosPipe],
})
export class AlquileresPage {
  private servicio = inject(AlquilerService);
  private sesion = inject(SesionService);
  private resumen = inject(ResumenService);
  private alerta = inject(AlertController);
  private toast = inject(ToastController);

  todos = signal<Alquiler[]>([]);
  cargando = signal(true);
  filtro = signal<'activos' | 'historial'>('activos');

  // Activos (incluye vencidos sin devolver) / historial (devueltos)
  visibles = computed(() => this.todos().filter(a =>
    this.filtro() === 'activos' ? a.estado !== 'DEVUELTO' : a.estado === 'DEVUELTO'));

  ionViewWillEnter(): void {
    this.cargar();
  }

  cambiarFiltro(v: unknown): void {
    this.filtro.set(v === 'historial' ? 'historial' : 'activos');
  }

  async devolver(a: Alquiler): Promise<void> {
    const alerta = await this.alerta.create({
      header: 'Devolver alquiler',
      message: `¿Confirmas que has devuelto ${a.producto.nombre} en la tienda?`,
      buttons: [
        { text: 'Cancelar', role: 'cancel' },
        { text: 'Devolver', handler: () => {
          this.servicio.devolver(a.id).subscribe(async () => {
            this.cargar();
            this.resumen.refrescar();
            const t = await this.toast.create({ message: 'Alquiler devuelto. ¡Gracias!', duration: 2000, color: 'dark' });
            await t.present();
          });
        } },
      ],
    });
    await alerta.present();
  }

  private cargar(): void {
    const id = this.sesion.usuario()?.id;
    if (!id) return;
    this.servicio.delUsuario(id).subscribe(lista => {
      this.todos.set([...lista].reverse());
      this.cargando.set(false);
    });
  }
}
