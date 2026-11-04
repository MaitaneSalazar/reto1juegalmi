import { Component, input, output } from '@angular/core';
import { IonIcon } from '@ionic/angular';
import { addIcons } from 'ionicons';
import { add, remove } from 'ionicons/icons';

@Component({
  selector: 'app-selector-cantidad',
  host: { '[class.vertical]': 'vertical()' },
  template: `
    <button type="button" (click)="cambio.emit(-1)" [disabled]="valor() <= min()" aria-label="Quitar uno">
      <ion-icon name="remove"></ion-icon>
    </button>
    <span aria-live="polite">{{ valor() }}</span>
    <button type="button" (click)="cambio.emit(1)" [disabled]="valor() >= max()" aria-label="Añadir uno">
      <ion-icon name="add"></ion-icon>
    </button>
  `,
  styles: [`
    :host {
      display: inline-flex; align-items: center; gap: 2px; padding: 4px;
      background: var(--jg-acento-suave); border-radius: 999px;
    }
    :host(.vertical) { flex-direction: column-reverse; }   /* + arriba, − abajo */
    button {
      width: 34px; height: 34px; border: 0; border-radius: 50%;
      background: transparent; color: var(--ion-text-color);
      display: flex; align-items: center; justify-content: center; font-size: 18px;
    }
    button:disabled { opacity: .3; }
    span { min-width: 26px; text-align: center; font-size: 16px; font-weight: 600; }
  `],
  imports: [IonIcon],
})
export class SelectorCantidadComponent {
  valor = input.required<number>();
  min = input(1);
  max = input(99);
  vertical = input(false);
  cambio = output<number>();   // -1 o +1

  constructor() {
    addIcons({ add, remove });
  }
}
