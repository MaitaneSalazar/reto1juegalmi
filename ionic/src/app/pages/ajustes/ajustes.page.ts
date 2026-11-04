import { Component, inject } from '@angular/core';
import { IonHeader, IonToolbar, IonButtons, IonBackButton, IonTitle, IonContent, IonIcon,
         AlertController, ToastController } from '@ionic/angular';
import { addIcons } from 'ionicons';
import { serverOutline, trashOutline, informationCircleOutline, languageOutline } from 'ionicons/icons';
import { environment } from '../../../environments/environment';
import { CestaService } from '../../services/cesta.service';

@Component({
  selector: 'app-ajustes',
  templateUrl: './ajustes.page.html',
  styleUrls: ['../cuenta/subpagina.scss'],
  imports: [IonHeader, IonToolbar, IonButtons, IonBackButton, IonTitle, IonContent, IonIcon],
})
export class AjustesPage {
  private cesta = inject(CestaService);
  private alerta = inject(AlertController);
  private toast = inject(ToastController);

  // Útil en la demo: a qué API está conectada la app
  origenDatos = environment.apiUrl;   // dirección de la API que usa la app
  version = '1.0.0';

  constructor() {
    addIcons({ serverOutline, trashOutline, informationCircleOutline, languageOutline });
  }

  async vaciarCesta(): Promise<void> {
    const a = await this.alerta.create({
      header: 'Vaciar cesta',
      message: '¿Quieres quitar todos los productos de la cesta?',
      buttons: [
        { text: 'Cancelar', role: 'cancel' },
        { text: 'Vaciar', role: 'destructive', handler: async () => {
          this.cesta.vaciar();
          const t = await this.toast.create({ message: 'Cesta vaciada.', duration: 2000, color: 'dark' });
          await t.present();
        } },
      ],
    });
    await a.present();
  }
}
