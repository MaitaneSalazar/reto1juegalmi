import { Component, computed, input } from '@angular/core';
import { colorPlataforma, nombrePlataforma, plataformasDe } from '../../models/producto.model';

// Píldoras de color con las plataformas de un juego: Xbox (verde), PS5 (azul), Switch (rojo)
@Component({
  selector: 'app-plataformas',
  template: `
    @for (pl of lista(); track pl) {
      <span class="pildora" [style.background]="color(pl)">{{ nombre(pl) }}</span>
    }
  `,
  styles: [`
    :host { display: flex; flex-wrap: wrap; gap: 6px; }
    :host(.columna) { flex-direction: column; align-items: flex-end; gap: 4px; }   /* en las tarjetas, una debajo de otra */
    .pildora {
      padding: 4px 10px; border-radius: 999px;
      color: #ffffff; font-size: 11px; font-weight: 700; line-height: 1.2;
      box-shadow: 0 2px 6px rgba(0, 0, 0, .15);
    }
    :host(.grande) .pildora { padding: 6px 14px; font-size: 13px; box-shadow: none; }
  `],
})
export class PlataformasComponent {
  producto = input.required<{ plataforma?: string | null; plataformas?: string[] }>();
  lista = computed(() => plataformasDe(this.producto()));
  color(pl: string): string { return colorPlataforma(pl); }
  nombre(pl: string): string { return nombrePlataforma(pl); }   // «Nintendo Switch», como Android
}
