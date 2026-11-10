import { Component, input, output } from '@angular/core';
import { IonIcon, IonButton } from '@ionic/angular';
import { addIcons } from 'ionicons';
import { cloudOfflineOutline, refreshOutline, storefrontOutline, receiptOutline, timeOutline,
         buildOutline, searchOutline, bagHandleOutline } from 'ionicons/icons';

// Pantalla de lista vacía (con botón de acción opcional) o de error al cargar (con Reintentar)
@Component({
  selector: 'app-estado',
  template: `
    <div class="estado" [class.error]="error()">
      <span class="icono"><ion-icon [name]="error() ? 'cloud-offline-outline' : icono()"></ion-icon></span>
      <h2>{{ error() ? 'Algo ha fallado' : titulo() }}</h2>
      <p>{{ error() ? 'No se puede conectar con el servidor.' : texto() }}</p>
      @if (error()) {
        <ion-button (click)="reintentar.emit()"><ion-icon slot="start" name="refresh-outline"></ion-icon>Reintentar</ion-button>
      }
      @if (!error() && boton()) {
        <ion-button (click)="accion.emit()">{{ boton() }}</ion-button>
      }
    </div>
  `,
  styles: [`
    .estado { display: flex; flex-direction: column; align-items: center; text-align: center; padding: 48px 12px; }
    .icono {
      display: grid; place-items: center; width: 80px; height: 80px; border-radius: 50%;
      background: var(--jg-acento-suave); color: var(--ion-text-color); font-size: 34px;
    }
    .error .icono { background: #f4e4e9; color: #a72144; }
    h2 { margin: 22px 0 8px; color: var(--ion-text-color); font-size: 22px; font-weight: 700; letter-spacing: -0.03em; }
    p { margin: 0; max-width: 300px; color: var(--jg-texto-sec); font-size: 15px; line-height: 1.45; }
    ion-button { margin-top: 22px; min-height: 48px; --padding-start: 24px; --padding-end: 24px; }
  `],
  imports: [IonIcon, IonButton],
})
export class EstadoComponent {
  error = input(false);              // true = sin conexión
  icono = input('storefront-outline');
  titulo = input('No hay nada');
  texto = input('');
  reintentar = output<void>();
  boton = input('');                 // texto del botón de las listas vacías (vacío = sin botón)
  accion = output<void>();

  constructor() {
    addIcons({ cloudOfflineOutline, refreshOutline, storefrontOutline, receiptOutline, timeOutline,
               buildOutline, searchOutline, bagHandleOutline });
  }
}
