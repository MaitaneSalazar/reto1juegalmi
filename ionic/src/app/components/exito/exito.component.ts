import { Component, Input, inject } from '@angular/core';
import { ModalController } from '@ionic/angular';
import { LottieComponent } from '../lottie/lottie.component';

// Diálogo con el check de «hecho» que se cierra solo (como Exito en Android)
@Component({
  selector: 'app-exito',
  standalone: true,
  imports: [LottieComponent],
  template: `
    <div class="exito">
      <app-lottie nombre="hecho" [bucle]="false" (terminada)="cerrar()"></app-lottie>
      <strong>{{ texto }}</strong>
    </div>`,
  styles: [`
    .exito { display: flex; flex-direction: column; align-items: center; padding: 28px; }
    app-lottie { width: 120px; height: 120px; }
    strong { margin-top: 12px; font-size: 17px; text-align: center; }`],
})
export class ExitoComponent {
  // @Input clásico: ModalController pasa componentProps asignando la propiedad (con input() fallaría)
  @Input() texto = '';
  private modal = inject(ModalController);

  // El check se queda medio segundo a la vista antes de cerrar
  cerrar(): void {
    setTimeout(() => this.modal.dismiss(), 500);
  }
}
