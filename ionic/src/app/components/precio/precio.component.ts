import { Component, computed, input } from '@angular/core';

// El tamaño se controla con font-size desde fuera
@Component({
  selector: 'app-precio',
  template: `<b>{{ partes()[0] }}</b><sup>,{{ partes()[1] }} €</sup>@if (sufijo()) {<span>{{ sufijo() }}</span>}`,
  styles: [`
    :host { display: inline-flex; align-items: flex-start; line-height: 1; white-space: nowrap; }
    b { font-weight: 700; letter-spacing: -0.04em; }
    sup { position: static; font-size: .42em; font-weight: 500; margin: .1em 0 0 .06em; }
    span { align-self: flex-end; margin-left: .3em; font-size: .42em; color: var(--jg-texto-sec); }
  `],
})
export class PrecioComponent {
  valor = input.required<number>();
  sufijo = input('');                       // p. ej. "/ día"

  // [entero con puntos de miles, céntimos]
  partes = computed(() => {
    const [entero, cent] = (this.valor() ?? 0).toFixed(2).split('.');
    return [Number(entero).toLocaleString('es-ES'), cent];
  });
}
