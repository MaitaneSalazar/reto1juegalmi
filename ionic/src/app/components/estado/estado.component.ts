import { Component, input, output } from '@angular/core';
import { IonButton } from '@ionic/angular';

// Pantalla de lista vacía (con botón de acción opcional) o de error al cargar (con Reintentar)
@Component({
  selector: 'app-estado',
  template: `
    <div class="estado" [class.error]="error()">
      <h2>{{ error() ? 'Algo ha fallado' : titulo() }}</h2>
      <p>{{ error() ? 'No se puede conectar con el servidor.' : texto() }}</p>
      @if (error()) {
        <ion-button (click)="reintentar.emit()">Reintentar</ion-button>
      }
      @if (!error() && boton()) {
        <ion-button (click)="accion.emit()">{{ boton() }}</ion-button>
      }
    </div>
  `,
  styles: [`
    .estado { display: flex; flex-direction: column; align-items: center; text-align: center; padding: 48px 12px; }
    h2 { margin: 0 0 8px; color: var(--ion-text-color); font-size: 22px; font-weight: 700; letter-spacing: -0.03em; }
    p { margin: 0; max-width: 300px; color: var(--jg-texto-sec); font-size: 14px; line-height: 1.45; }
    ion-button { margin-top: 22px; min-height: 48px; --padding-start: 24px; --padding-end: 24px; }
  `],
  imports: [IonButton],
})
export class EstadoComponent {
  error = input(false);              // true = sin conexión
  icono = input('');                 // ya no se pinta (Android no lleva icono); se deja por compatibilidad
  titulo = input('No hay nada');
  texto = input('');
  reintentar = output<void>();
  boton = input('');                 // texto del botón de las listas vacías (vacío = sin botón)
  accion = output<void>();

}
