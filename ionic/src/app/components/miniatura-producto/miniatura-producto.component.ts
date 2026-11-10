import { Component, computed, input, signal } from '@angular/core';
import { IonImg } from '@ionic/angular';
import { COLOR_PLATAFORMA, COLOR_PORTADA, TipoProducto } from '../../models/producto.model';

// Vale para un Producto de la API o para un resumen con nombre e imagen
interface ProductoMini {
  id?: number; nombre: string; tipo?: TipoProducto; empresa?: string; plataforma?: string | null;
  imagen_url?: string | null; miniatura_url?: string | null;
}

// Formatos que se prueban para la foto local de respaldo (assets/productos/ID.ext)
const EXTENSIONES = ['jpg', 'png', 'webp', 'jpeg'];

@Component({
  selector: 'app-miniatura-producto',
  imports: [IonImg],
  template: `
    <!-- Portada generada: se ve mientras carga o si no hay foto (la BD manda imagen_url: null) -->
    <div class="arte" [style.background]="color()" aria-hidden="true">
      <span class="letra">{{ producto().nombre[0] }}</span>
      @if (marca() && !sinMarca()) { <span class="marca">{{ marca() }}</span> }
      <span class="titulo" [style.font-size.cqw]="tamTitulo()">{{ producto().nombre }}</span>
    </div>
    <!-- ion-img = carga diferida de imágenes (como Glide en Android): solo se descarga al verse -->
    @if (src()) {
      <ion-img [src]="src()" [alt]="producto().nombre"
               [class.visible]="cargada()" (ionImgDidLoad)="cargada.set(true)" (ionError)="siguiente()"></ion-img>
    }
  `,
  styles: [`
    :host {
      position: relative; flex-shrink: 0; display: block;
      width: var(--tam, 80px); height: var(--tam, 80px);
      border-radius: var(--radio, 14px); overflow: hidden;
      background: var(--fondo, var(--jg-gris));
    }
    /* Las medidas en cqw dependen del ancho de la portada: vale igual para 64 px que para 300 px */
    .arte { position: absolute; inset: 0; overflow: hidden; color: #ffffff; container-type: inline-size; }
    .letra {
      position: absolute; top: -18%; right: -8%;
      font-size: 70cqw; line-height: 1; font-weight: 700; opacity: .09; user-select: none;
    }
    .marca {
      position: absolute; top: 7%; right: 7%;
      font-size: 8cqw; font-weight: 600; letter-spacing: .08em; text-transform: uppercase; opacity: .75;
    }
    .titulo {
      position: absolute; left: 7%; right: 7%; bottom: 7%;
      font-weight: 700; line-height: .86;
      letter-spacing: -.055em; text-transform: uppercase; text-wrap: balance; overflow-wrap: normal;
    }
    ion-img {
      position: absolute; inset: 0; width: 100%; height: 100%;
      background: var(--fondo, #ffffff);
      opacity: 0; transition: opacity .3s;          /* aparece suave al cargar */
    }
    ion-img::part(image) { width: 100%; height: 100%; object-fit: var(--ajuste, cover); }
    ion-img.visible { opacity: 1; }
  `],
})
export class MiniaturaProductoComponent {
  producto = input.required<ProductoMini>();
  grande = input(false);
  sinMarca = input(false);       // true = no escribir la plataforma/marca en la portada (ya va en píldoras)
  cargada = signal(false);
  intento = signal(0);           // 0 = imagen de la API · 1.. = fotos locales de respaldo

  // Videojuegos: color y nombre de la plataforma · resto: oscuro y la marca (SONY, APPLE...)
  color = computed(() => COLOR_PLATAFORMA[this.producto().plataforma ?? ''] ?? COLOR_PORTADA);
  marca = computed(() => {
    const p = this.producto();
    return p.tipo === 'videojuego' || p.plataforma ? p.plataforma : p.empresa;
  });

  // Título lo más grande posible sin partir palabras: "PLAYSTATION" (11 letras) cabe en el ancho
  tamTitulo = computed(() => {
    const larga = Math.max(...this.producto().nombre.split(/\s+/).map(p => p.length));
    return Math.min(15, 84 / (larga * 0.62));
  });

  // 1º imagen de la API (miniatura en listados, original en la ficha); si no hay o falla → foto local → portada
  src = computed(() => {
    const p = this.producto();
    const api = this.grande() ? (p.imagen_url ?? p.miniatura_url) : (p.miniatura_url ?? p.imagen_url);
    const opciones = [...(api ? [api] : []), ...(p.id ? EXTENSIONES.map(e => `assets/productos/${p.id}.${e}`) : [])];
    return opciones[this.intento()] ?? '';
  });

  // La foto ha fallado: se prueba la siguiente opción
  siguiente(): void {
    this.cargada.set(false);
    this.intento.update(i => i + 1);
  }
}
