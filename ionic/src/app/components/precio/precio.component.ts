import { Component, computed, input } from '@angular/core';

// Precio en texto normal, como Android: «49,99 €». El tamaño se pone con font-size desde fuera
@Component({
  selector: 'app-precio',
  template: `<b>{{ texto() }}</b>@if (sufijo()) {<span>{{ sufijo() }}</span>}`,
  styles: [`
    :host { display: inline-flex; align-items: baseline; white-space: nowrap; }
    b { font-weight: 700; }
    span { margin-left: .3em; font-size: 13px; font-weight: 400; color: var(--jg-texto-sec); }
  `],
})
export class PrecioComponent {
  valor = input.required<number>();
  sufijo = input('');                       // p. ej. "/ día"

  // "49,99 €", "1.398,00 €": igual que FormatosReparacion.precio() en Android
  texto = computed(() => (this.valor() ?? 0).toLocaleString('es-ES', { minimumFractionDigits: 2, maximumFractionDigits: 2 }) + ' €');
}
