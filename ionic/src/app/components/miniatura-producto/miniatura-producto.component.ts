import { Component, computed, input, signal } from '@angular/core';
import { IonIcon } from '@ionic/angular';
import { addIcons } from 'ionicons';
import { discOutline, gameControllerOutline, phonePortraitOutline, tabletPortraitOutline } from 'ionicons/icons';
import { ICONO_TIPO, TipoProducto } from '../../models/producto.model';

// Vale para un Producto completo o para el resumen que trae un alquiler
interface ProductoMini { id?: number; nombre: string; tipo?: TipoProducto; imagenUrl?: string; }

// Formatos que se prueban en orden para la foto local (assets/productos/ID.ext)
const EXTENSIONES = ['jpg', 'png', 'webp', 'jpeg'];

@Component({
  selector: 'app-miniatura-producto',
  template: `
    <!-- Icono provisional: se ve mientras carga o si no hay foto -->
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
  cargada = signal(false);       // la foto ya se ha descargado
  intento = signal(0);           // qué extensión se está probando

  icono = computed(() => ICONO_TIPO[this.producto().tipo ?? 'VIDEOJUEGO']);

  // 1º la URL de la API; si no hay, assets/productos/ID.jpg → .png → .webp → .jpeg
  src = computed(() => {
    const p = this.producto();
    const i = this.intento();
    if (p.imagenUrl) return i === 0 ? p.imagenUrl : '';
    if (!p.id || i >= EXTENSIONES.length) return '';           // sin foto → se queda el icono
    return `assets/productos/${p.id}.${EXTENSIONES[i]}`;
  });

  constructor() {
    addIcons({ discOutline, gameControllerOutline, phonePortraitOutline, tabletPortraitOutline });
  }

  // La foto ha fallado: se prueba el siguiente formato
  siguiente(): void {
    this.cargada.set(false);
    this.intento.update(i => i + 1);
  }
}