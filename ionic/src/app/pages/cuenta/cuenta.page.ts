import { Component, inject } from '@angular/core';
import { Router, RouterLink } from '@angular/router';
import { IonHeader, IonContent, IonIcon, AlertController, ToastController } from '@ionic/angular';
import { addIcons } from 'ionicons';
import { receiptOutline, timeOutline, buildOutline, personOutline, locationOutline,
         settingsOutline, chevronForward, logOutOutline } from 'ionicons/icons';
import { CabeceraComponent } from '../../components/cabecera/cabecera.component';
import { MiniaturaProductoComponent } from '../../components/miniatura-producto/miniatura-producto.component';
import { SesionService } from '../../services/sesion.service';
import { ResumenService } from '../../services/resumen.service';
import { AlquilerService } from '../../services/alquiler.service';
import { Alquiler } from '../../models/alquiler.model';

@Component({
  selector: 'app-cuenta',
  templateUrl: './cuenta.page.html',
  styleUrls: ['./cuenta.page.scss'],
  imports: [RouterLink, IonHeader, IonContent, IonIcon, CabeceraComponent, MiniaturaProductoComponent],
})
export class CuentaPage {
  sesion = inject(SesionService);
  resumen = inject(ResumenService);
  private alquileres = inject(AlquilerService);
  private alerta = inject(AlertController);
  private toast = inject(ToastController);
  private router = inject(Router);

  constructor() {
    addIcons({ receiptOutline, timeOutline, buildOutline, personOutline, locationOutline,
               settingsOutline, chevronForward, logOutOutline });
  }

  ionViewWillEnter(): void {
    this.resumen.refrescar();
  }

  // Devolver el alquiler activo (con confirmación)
  async devolver(a: Alquiler): Promise<void> {
    const alerta = await this.alerta.create({
      header: 'Devolver alquiler',
      message: `¿Confirmas que has devuelto ${a.producto.nombre} en la tienda?`,
      buttons: [
        { text: 'Cancelar', role: 'cancel' },
        { text: 'Devolver', handler: () => {
          this.alquileres.devolver(a.id).subscribe(async () => {
            this.resumen.refrescar();
            const t = await this.toast.create({ message: 'Alquiler devuelto. ¡Gracias!', duration: 2000, color: 'dark' });
            await t.present();
          });
        } },
      ],
    });
    await alerta.present();
  }

  cerrarSesion(): void {
    this.sesion.cerrar();
    this.router.navigateByUrl('/login', { replaceUrl: true });
  }
}
