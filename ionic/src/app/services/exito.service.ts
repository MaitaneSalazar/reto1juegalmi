import { Injectable, inject } from '@angular/core';
import { ModalController } from '@ionic/angular';
import { ExitoComponent } from '../components/exito/exito.component';

@Injectable({ providedIn: 'root' })
export class ExitoService {
  private modal = inject(ModalController);

  // Muestra el check y espera a que se cierre solo
  async mostrar(texto: string): Promise<void> {
    const m = await this.modal.create({
      component: ExitoComponent,
      componentProps: { texto },
      cssClass: 'modal-exito',
      backdropDismiss: false,
    });
    await m.present();
    await m.onDidDismiss();
  }
}
