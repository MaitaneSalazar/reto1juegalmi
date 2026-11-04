import { Component, computed, input, signal } from '@angular/core';
import { IonIcon } from '@ionic/angular';
import { addIcons } from 'ionicons';
import { discOutline, gameControllerOutline, phonePortraitOutline, tabletPortraitOutline } from 'ionicons/icons';
import { ICONO_TIPO, TipoProducto } from '../../models/producto.model';

// Vale para un Producto de la API o para un resumen con nombre e imagen
interface ProductoMini { id?: number; nombre: string; tipo?: TipoProducto; imagen_url?: string | null; miniatura_url?: string | null; }

// Formatos que se prueban para la foto local de respaldo (assets/productos/ID.ext)
const EXTENSIONES = ['jpg', 'png', 'webp', 'jpeg'];

@Component({
  selector: 'app-miniatura-producto',
  template: `
    <!-- Icono provisional: se ve mientras carga o si no hay foto (requisito del reto) -->
    <ion-icon [name]="icono()" aria-hidden="true"></ion-icon>
    @if (src()) {
      <img [src]="src()" [alt]="producto().nombre" loading="lazy"
           [class.visible]="cargada()" (load)="cargada.set(true)" (error)="siguiente()">
    }
  `,
  styles: [`
    :host {
      position: relative; flex-shrink: 0;
      display: flex; align-items: center; justify-content: center;
      width: var(--tam, 80px); height: var(--tam, 80px);
      border-radius: var(--radio, 14px); overflow: hidden;
      background: var(--fondo, var(--jg-gris));
    }
    ion-icon { font-size: var(--icono, 30px); color: var(--jg-texto-sec); opacity: .7; }
    img {
      position: absolute; inset: 0; width: 100%; height: 100%;
      object-fit: var(--ajuste, cover);
      opacity: 0; transition: opacity .3s;          /* aparece suave al cargar */
    }
    img.visible { opacity: 1; }
  `],
  imports: [IonIcon],
})
export class MiniaturaProductoComponent {
  producto = input.required<ProductoMini>();
  grande = input(false);         // true = usar la imagen original (ficha) en vez de la miniatura
  cargada = signal(false);
  intento = signal(0);           // 0 = imagen de la API · 1.. = fotos locales de respaldo

  icono = computed(() => ICONO_TIPO[this.producto().tipo ?? 'videojuego']);

  // 1º imagen de la API (miniatura en listados, original en la ficha); si no hay o falla → foto local → icono
  src = computed(() => {
    const p = this.producto();
    const api = this.grande() ? (p.imagen_url ?? p.miniatura_url) : (p.miniatura_url ?? p.imagen_url);
    const opciones = [...(api ? [api] : []), ...(p.id ? EXTENSIONES.map(e => `assets/productos/${p.id}.${e}`) : [])];
    return opciones[this.intento()] ?? '';
  });

  constructor() {
    addIcons({ discOutline, gameControllerOutline, phonePortraitOutline, tabletPortraitOutline });
  }

  // La foto ha fallado: se prueba la siguiente opción
  siguiente(): void {
    this.cargada.set(false);
    this.intento.update(i => i + 1);
  }
}
