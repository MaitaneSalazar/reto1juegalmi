#!/bin/bash
# =====================================================================
# PASO 19 · Plataformas de cada juego
#   - Alquilar: fuera el filtro «Multi» (esos juegos salen dentro de PS5, Xbox y Switch)
#   - Cada juego lleva sus plataformas arriba a la derecha: Xbox verde · PS5 azul · Switch rojo
#     («Multi» = las tres; si la API algún día manda una lista de plataformas, se usa tal cual)
#   - Ficha: la plataforma baja junto al género y el PEGI, en su color
# Uso (desde la carpeta ionic/):   bash paso19-plataformas.sh
# =====================================================================
set -e
if [ ! -f angular.json ] || ! grep -q "password_nueva" src/app/pages/editar-datos/editar-datos.page.ts 2>/dev/null; then
  echo "✘ Ejecútalo dentro de ionic/ y con el paso 18 aplicado"; exit 1
fi
tar czf ../ionic-src-antes-paso19.tgz src PRUEBAS.md
echo "• Copia de seguridad: ../ionic-src-antes-paso19.tgz"

mkdir -p $(dirname src/app/components/miniatura-producto/miniatura-producto.component.ts)
cat > src/app/components/miniatura-producto/miniatura-producto.component.ts <<'JUEGALMI_EOF'
import { Component, computed, input, signal } from '@angular/core';
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
  template: `
    <!-- Portada generada: se ve mientras carga o si no hay foto (la BD manda imagen_url: null) -->
    <div class="arte" [style.background]="color()" aria-hidden="true">
      <span class="letra">{{ producto().nombre[0] }}</span>
      @if (marca() && !sinMarca()) { <span class="marca">{{ marca() }}</span> }
      <span class="titulo" [style.font-size.cqw]="tamTitulo()">{{ producto().nombre }}</span>
    </div>
    @if (src()) {
      <img [src]="src()" [alt]="producto().nombre" loading="lazy"
           [class.visible]="cargada()" (load)="cargada.set(true)" (error)="siguiente()">
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
      font-size: 70cqw; line-height: 1; font-weight: 900; opacity: .09; user-select: none;
    }
    .marca {
      position: absolute; top: 7%; right: 7%;
      font-size: 8cqw; font-weight: 600; letter-spacing: .08em; text-transform: uppercase; opacity: .75;
    }
    .titulo {
      position: absolute; left: 7%; right: 7%; bottom: 7%;
      font-weight: 850; line-height: .86;
      letter-spacing: -.055em; text-transform: uppercase; text-wrap: balance; overflow-wrap: normal;
    }
    img {
      position: absolute; inset: 0; width: 100%; height: 100%;
      object-fit: var(--ajuste, cover); background: var(--fondo, #ffffff);
      opacity: 0; transition: opacity .3s;          /* aparece suave al cargar */
    }
    img.visible { opacity: 1; }
  `],
})
export class MiniaturaProductoComponent {
  producto = input.required<ProductoMini>();
  grande = input(false);
  sinMarca = input(false);       // true = no escribir la plataforma/marca en la portada (ya va en píldoras)         // true = usar la imagen original (ficha) en vez de la miniatura
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
JUEGALMI_EOF

mkdir -p $(dirname src/app/components/plataformas/plataformas.component.ts)
cat > src/app/components/plataformas/plataformas.component.ts <<'JUEGALMI_EOF'
import { Component, computed, input } from '@angular/core';
import { COLOR_PILDORA, plataformasDe } from '../../models/producto.model';

// Píldoras de color con las plataformas de un juego: Xbox (verde), PS5 (azul), Switch (rojo)
@Component({
  selector: 'app-plataformas',
  template: `
    @for (pl of lista(); track pl) {
      <span class="pildora" [style.background]="color(pl)">{{ pl }}</span>
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
  color(pl: string): string { return COLOR_PILDORA[pl] ?? '#5c616c'; }
}
JUEGALMI_EOF

mkdir -p $(dirname src/app/models/producto.model.spec.ts)
cat > src/app/models/producto.model.spec.ts <<'JUEGALMI_EOF'
import { describe, it, expect } from 'vitest';
import { etiquetaStock, plataformasDe } from './producto.model';

describe('Etiqueta de stock', () => {
  it('3 o más: sin etiqueta', () => {
    expect(etiquetaStock(3)).toBeNull();
  });

  it('2: «Quedan 2» en rojo', () => {
    expect(etiquetaStock(2)).toEqual({ texto: 'Quedan 2', tipo: 'aviso' });
  });

  it('1: «Última unidad» (en alquiler, «Última copia»)', () => {
    expect(etiquetaStock(1)?.texto).toBe('Última unidad');
    expect(etiquetaStock(1, true)?.texto).toBe('Última copia');
  });

  it('0: «Agotado» (en alquiler, «Alquilado»)', () => {
    expect(etiquetaStock(0)).toEqual({ texto: 'Agotado', tipo: 'off' });
    expect(etiquetaStock(0, true)?.texto).toBe('Alquilado');
  });
});

describe('Plataformas de un juego', () => {
  it('«Multi» se juega en PS5, Xbox y Switch', () => {
    expect(plataformasDe({ plataforma: 'Multi' })).toEqual(['PS5', 'Xbox', 'Switch']);
  });

  it('una sola plataforma', () => {
    expect(plataformasDe({ plataforma: 'Xbox' })).toEqual(['Xbox']);
  });

  it('si la API manda una lista (p. ej. dos plataformas) se usa tal cual', () => {
    expect(plataformasDe({ plataforma: 'Multi', plataformas: ['PS5', 'Xbox'] })).toEqual(['PS5', 'Xbox']);
  });
});
JUEGALMI_EOF

mkdir -p $(dirname src/app/models/producto.model.ts)
cat > src/app/models/producto.model.ts <<'JUEGALMI_EOF'
// Producto tal como lo devuelve la API (tarjeta del listado + datos de la ficha)
export type TipoProducto = 'videojuego' | 'consola' | 'movil' | 'tablet';

export interface Producto {
  id: number;
  tipo: TipoProducto;
  nombre: string;
  empresa: string;               // Nintendo, Sony...
  precio_venta: number;
  stock: number;
  disponible: boolean;
  imagen_url: string | null;     // null → imagen provisional
  miniatura_url?: string | null; // ~400 px, para listados
  plataforma?: string;           // videojuegos
  precio_alquiler_dia?: number | null;
  alquilado?: boolean;           // listado de alquiler: no queda copia libre
  // Ficha (GET /api/productos/{id})
  descripcion?: string;
  genero?: string;
  pegi?: number;
  copias_alquiler?: number;
  copias_disponibles?: number;
  almacenamiento_gb?: number;
  color?: string;
  edicion?: string;
  pantalla_pulgadas?: number;
  ram_gb?: number;
  sistema_operativo?: string;
  bateria_mah?: number;
  conectividad?: string;
}

// Texto de cada tipo
export const NOMBRE_TIPO: Record<TipoProducto, string> = {
  videojuego: 'Videojuego',
  consola: 'Consola',
  movil: 'Móvil',
  tablet: 'Tablet',
};

// Color de la portada generada (cuando la API manda imagen_url: null)
export const COLOR_PLATAFORMA: Record<string, string> = {
  PS5: '#375e60', Xbox: '#5c616c', Switch: '#5ea0a2', Multi: '#8a8c84',
};
export const COLOR_PORTADA = '#1f2329';          // consolas, móviles, tablets y sin plataforma

// Plataformas en las que se juega: "Multi" = las tres (si algún día la API manda una lista, se usa tal cual)
export const PLATAFORMAS = ['PS5', 'Xbox', 'Switch'] as const;
export function plataformasDe(p: { plataforma?: string | null; plataformas?: string[] }): string[] {
  if (p.plataformas?.length) return p.plataformas;
  if (!p.plataforma) return [];
  return p.plataforma === 'Multi' ? [...PLATAFORMAS] : [p.plataforma];
}
// Xbox verde · PlayStation azul · Switch rojo
export const COLOR_PILDORA: Record<string, string> = { Xbox: '#107c10', PS5: '#0070d1', Switch: '#e60012' };

// Etiqueta de stock: «Quedan 2», «Última unidad», «Agotado» (en alquiler: «Última copia», «Alquilado»)
export interface EtiquetaStock { texto: string; tipo: 'aviso' | 'off'; }
export function etiquetaStock(n: number, alquiler = false): EtiquetaStock | null {
  if (n <= 0) return { texto: alquiler ? 'Alquilado' : 'Agotado', tipo: 'off' };
  if (n === 1) return { texto: alquiler ? 'Última copia' : 'Última unidad', tipo: 'aviso' };
  if (n === 2) return { texto: 'Quedan 2', tipo: 'aviso' };
  return null;                                   // 3 o más: sin etiqueta
}

// Un videojuego se puede alquilar si tiene precio por día
export function esAlquilable(p: Producto): boolean {
  return p.tipo === 'videojuego' && p.precio_alquiler_dia != null;
}
JUEGALMI_EOF

mkdir -p $(dirname src/app/pages/detalle-producto/detalle-producto.page.html)
cat > src/app/pages/detalle-producto/detalle-producto.page.html <<'JUEGALMI_EOF'
<ion-content [fullscreen]="true">
  <!-- Foto grande con degradado y botón volver -->
  <div class="hero">
    <ion-back-button class="redondo volver" defaultHref="/tienda" text=""></ion-back-button>
    @if (producto(); as p) {
      <app-miniatura-producto [producto]="p" [grande]="true" [sinMarca]="p.tipo === 'videojuego'"></app-miniatura-producto>
    }
  </div>

  <div class="cuerpo">
    @if (producto(); as p) {
      <h1>{{ p.nombre }}</h1>
      <div class="etiquetas">
        <!-- Plataformas en su color (Xbox verde, PS5 azul, Switch rojo) junto al resto -->
        @if (p.tipo === 'videojuego') { <app-plataformas class="grande" [producto]="p"></app-plataformas> }
        @for (c of chips(); track c) { <span class="etiqueta-mini">{{ c }}</span> }
      </div>
      <p class="descripcion">{{ p.descripcion }}</p>
      <!-- Stock visible: «¡Date prisa! Queda 1 unidad», «Agotado»... -->
      <p class="disponible" [class.aviso]="quedan() <= 2">{{ textoStock() }}</p>

      @if (alquilable()) {
        <ion-segment [value]="modo()" (ionChange)="cambiarModo($event.detail.value)">
          <ion-segment-button value="comprar"><ion-label>Comprar · {{ p.precio_venta | euros }}</ion-label></ion-segment-button>
          <ion-segment-button value="alquilar"><ion-label>Alquilar</ion-label></ion-segment-button>
        </ion-segment>
      }

      @if (modo() === 'alquilar') {
        <!-- Días de alquiler -->
        <div class="dias">
          @for (d of opcionesDias; track d) {
            <button type="button" class="pulsable" [class.activo]="dias() === d" (click)="dias.set(d)">
              <b>{{ d }}</b><span>{{ d === 1 ? 'día' : 'días' }}</span>
            </button>
          }
        </div>
        <!-- Cálculo antes de pagar: días × precio y fecha de devolución -->
        <div class="calculo tarjeta">
          <div><span>{{ dias() }} {{ dias() === 1 ? 'día' : 'días' }} × {{ p.precio_alquiler_dia | euros }}</span><b>{{ totalAlquiler() | euros }}</b></div>
          <div><span>Devolución antes del</span><b>{{ devolucion() | fechaCorta }}</b></div>
        </div>
      }
    } @else {
      <ion-skeleton-text [animated]="true" style="width: 80%; height: 34px"></ion-skeleton-text>
      <ion-skeleton-text [animated]="true" style="width: 60%; height: 18px"></ion-skeleton-text>
    }
  </div>
</ion-content>

<!-- Tarjeta flotante inferior: precio + botón -->
@if (producto(); as p) {
  <ion-footer class="ion-no-border">
    <div class="compra">
      <div class="importe">
        <app-precio [valor]="modo() === 'alquilar' ? totalAlquiler() : p.precio_venta"></app-precio>
        <small>{{ modo() === 'alquilar' ? dias() + (dias() === 1 ? ' día de alquiler' : ' días de alquiler') : 'Envío gratis' }}</small>
      </div>
      @if (quedan() <= 0) {
        <!-- Agotado: el botón pasa a «Avísame» -->
        <ion-button fill="outline" class="avisame" (click)="avisame()">
          <ion-icon slot="start" name="notifications-outline"></ion-icon>Avísame
        </ion-button>
      } @else {
        <ion-button (click)="confirmar()" [disabled]="enviando()">
          @if (enviando()) { <ion-spinner name="crescent"></ion-spinner> }
          @else { {{ modo() === 'alquilar' ? 'Alquilar' : 'Añadir a la cesta' }} }
        </ion-button>
      }
    </div>
  </ion-footer>
}
JUEGALMI_EOF

mkdir -p $(dirname src/app/pages/detalle-producto/detalle-producto.page.scss)
cat > src/app/pages/detalle-producto/detalle-producto.page.scss <<'JUEGALMI_EOF'
ion-content { --padding-bottom: 24px; }

.hero {
  position: relative;
  display: flex; align-items: center; justify-content: center;
  height: calc(470px + var(--ion-safe-area-top, 0px));
  padding-top: var(--ion-safe-area-top, 0px);
  border-radius: 0 0 36px 36px; overflow: hidden;
  background: radial-gradient(circle at 50% 35%, #b7cfce 0%, #5f7978 100%);

  app-miniatura-producto {
    --tam: 286px; --radio: 16px; --fondo: rgba(255, 255, 255, .25); --icono: 80px;
    height: 396px; max-width: 66%;
    box-shadow: 0 24px 50px rgba(0, 0, 0, .3);
  }
}
.volver {
  position: absolute; z-index: 2;
  top: calc(14px + var(--ion-safe-area-top, 0px)); left: 18px;
  width: 50px; height: 50px;
  --background: rgba(255, 255, 255, .25); --color: #ffffff;
  background: rgba(255, 255, 255, .25); box-shadow: none;
  border: 1px solid rgba(255, 255, 255, .4);
}
.cuerpo { padding: 28px 22px 0; }
h1 { margin: 0 0 12px; font-size: 32px; line-height: 1.05; font-weight: 800; letter-spacing: -0.05em; }
.etiquetas { display: flex; gap: 8px; flex-wrap: wrap; align-items: center; }
.descripcion { margin: 18px 0 22px; color: var(--jg-texto-sec); font-size: 17px; line-height: 1.5; }
.nota { margin: 0; color: var(--jg-texto-sec); font-size: 14px; }
ion-segment-button { --padding-start: 4px; --padding-end: 4px; font-size: 14px; }

// 1 · 3 · 5 · 7 días
.dias {
  display: grid; grid-template-columns: repeat(4, 1fr); gap: 10px; margin-bottom: 12px;
  button {
    display: flex; flex-direction: column; align-items: center; gap: 4px;
    padding: 14px 0; border: 0; border-radius: 20px;
    background: var(--jg-tarjeta); color: var(--ion-text-color); font: inherit;
  }
  b { font-size: 24px; font-weight: 700; }
  span { font-size: 12px; color: var(--jg-texto-sec); }
  .activo { background: var(--jg-inverso); color: var(--jg-inverso-texto); span { color: inherit; opacity: .8; } }
}

// Tarjeta inferior
ion-footer { padding: 0 14px calc(14px + var(--ion-safe-area-bottom, 0px)); background: var(--ion-background-color); }
.compra {
  display: flex; align-items: center; gap: 16px;
  padding: 12px 12px 12px 26px; border-radius: 30px;
  background: var(--jg-tarjeta); box-shadow: var(--jg-sombra);

  .importe { display: flex; flex-direction: column; gap: 4px; }
  app-precio { font-size: 32px; }
  small { color: var(--jg-texto-sec); font-size: 13px; }
  ion-button { flex-grow: 1; margin: 0; min-height: 58px; }
}

// Stock visible
.disponible { margin: -8px 0 20px; font-size: 14px; font-weight: 600; color: #375e60; }
.disponible.aviso { color: #a72144; }

// Cálculo del alquiler
.calculo {
  display: flex; flex-direction: column; gap: 10px; padding: 16px 18px;
  div { display: flex; justify-content: space-between; gap: 12px; font-size: 15px; }
  span { color: var(--jg-texto-sec); }
}
.compra .avisame { --border-radius: 999px; --border-width: 1.5px; }
JUEGALMI_EOF

mkdir -p $(dirname src/app/pages/detalle-producto/detalle-producto.page.ts)
cat > src/app/pages/detalle-producto/detalle-producto.page.ts <<'JUEGALMI_EOF'
import { FechaCortaPipe } from '../../pipes/fecha-corta.pipe';
import { Component, computed, inject, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { ActivatedRoute, Router } from '@angular/router';
import { IonContent, IonFooter, IonBackButton, IonSegment, IonSegmentButton, IonLabel, IonButton,
         IonSpinner, IonSkeletonText, IonIcon, ToastController } from '@ionic/angular';
import { addIcons } from 'ionicons';
import { notificationsOutline } from 'ionicons/icons';
import { PlataformasComponent } from '../../components/plataformas/plataformas.component';
import { MiniaturaProductoComponent } from '../../components/miniatura-producto/miniatura-producto.component';
import { PrecioComponent } from '../../components/precio/precio.component';
import { EurosPipe } from '../../pipes/euros.pipe';
import { ProductoService } from '../../services/producto.service';
import { AlquilerService } from '../../services/alquiler.service';
import { CestaService } from '../../services/cesta.service';
import { SesionService } from '../../services/sesion.service';
import { NOMBRE_TIPO, Producto, esAlquilable } from '../../models/producto.model';

@Component({
  selector: 'app-detalle-producto',
  templateUrl: './detalle-producto.page.html',
  styleUrls: ['./detalle-producto.page.scss'],
  imports: [IonContent, IonFooter, IonBackButton, IonSegment, IonSegmentButton, IonLabel, IonButton,
            IonSpinner, IonSkeletonText, IonIcon, PlataformasComponent, MiniaturaProductoComponent, PrecioComponent, EurosPipe, FechaCortaPipe],
})
export class DetalleProductoPage {
  private productos = inject(ProductoService);
  private alquileres = inject(AlquilerService);
  private cesta = inject(CestaService);
  private sesion = inject(SesionService);
  private router = inject(Router);
  private toast = inject(ToastController);

  producto = signal<Producto | null>(null);
  modo = signal<'comprar' | 'alquilar'>('comprar');
  dias = signal(5);
  enviando = signal(false);
  opcionesDias = [1, 3, 5, 7];

  totalAlquiler = computed(() => +(this.dias() * (this.producto()?.precio_alquiler_dia ?? 0)).toFixed(2));
  devolucion = computed(() => this.alquileres.fechaDevolucion(this.dias()));
  // Lo que queda: unidades para comprar o copias libres para alquilar
  quedan = computed(() => {
    const p = this.producto();
    return !p ? 0 : this.modo() === 'alquilar' ? (p.copias_disponibles ?? 0) : p.stock;
  });
  textoStock = computed(() => {
    const n = this.quedan(), alq = this.modo() === 'alquilar';
    if (n <= 0) return alq ? 'Todas las copias están alquiladas' : 'Agotado';
    if (n === 1) return `¡Date prisa! Queda 1 ${alq ? 'copia' : 'unidad'}`;
    if (n === 2) return `¡Date prisa! Quedan 2 ${alq ? 'copias' : 'unidades'}`;
    return alq ? 'Disponible para alquilar' : 'En stock · envío en 24 h';
  });
  alquilable = computed(() => { const p = this.producto(); return !!p && esAlquilable(p); });

  // Pastilla de arriba a la derecha: "Switch", "Consola"...
  // Chips bajo el título
  chips = computed(() => {
    const p = this.producto();
    if (!p) return [];
    return p.tipo === 'videojuego'
      ? [p.genero, p.pegi ? `PEGI ${p.pegi}` : ''].filter(Boolean) as string[]
      : [p.empresa, NOMBRE_TIPO[p.tipo]];
  });

  constructor() {
    addIcons({ notificationsOutline });
    const ruta = inject(ActivatedRoute);
    this.modo.set(ruta.snapshot.queryParamMap.get('modo') === 'alquilar' ? 'alquilar' : 'comprar');

    ruta.paramMap.pipe(takeUntilDestroyed()).subscribe(params => {
      this.producto.set(null);
      this.productos.obtener(Number(params.get('id'))).subscribe(p => {
        if (!esAlquilable(p)) this.modo.set('comprar');      // los que no se alquilan, solo compra
        this.producto.set(p);
      });
    });
  }

  cambiarModo(valor: unknown): void {
    this.modo.set(valor === 'alquilar' ? 'alquilar' : 'comprar');
  }

  confirmar(): void {
    const p = this.producto();
    if (!p) return;
    this.modo() === 'comprar' ? this.anadirCesta(p) : this.alquilar(p);
  }

  // Agotado: de momento solo se avisa (la API no tiene avisos de stock)
  async avisame(): Promise<void> {
    const t = await this.toast.create({ message: 'Te avisaremos cuando vuelva a estar disponible', duration: 2500, color: 'dark' });
    await t.present();
  }

  private async anadirCesta(p: Producto): Promise<void> {
    if (!this.cesta.anadir(p)) {                       // ya tienes en la cesta todas las que quedan
      const t = await this.toast.create({ message: 'No quedan más unidades', duration: 2000, color: 'dark' });
      await t.present();
      return;
    }
    const t = await this.toast.create({
      message: 'Añadido a la cesta',
      duration: 2500, position: 'bottom', color: 'dark',
      buttons: [{ text: 'Ver cesta', handler: () => { this.router.navigateByUrl('/cesta'); } }],
    });
    await t.present();
  }

  private alquilar(p: Producto): void {
    this.enviando.set(true);

    this.alquileres.crear(this.dias(), [p.id]).subscribe({
      next: async alquiler => {
        this.enviando.set(false);
        const t = await this.toast.create({
          message: `Alquiler confirmado. Devuélvelo antes del ${new FechaCortaPipe().transform(alquiler.fecha_fin_prevista)}.`,
          duration: 3000, position: 'bottom', color: 'dark',
        });
        await t.present();
        this.router.navigateByUrl('/inicio', { replaceUrl: true });
      },
      error: async e => {
        this.enviando.set(false);
        // 409: "No quedan copias libres de ..." (mensaje de la API)
        const t = await this.toast.create({ message: this.sesion.mensaje(e), duration: 3000, color: 'danger' });
        await t.present();
      },
    });
  }
}
JUEGALMI_EOF

mkdir -p $(dirname src/app/pages/tienda/tienda.page.html)
cat > src/app/pages/tienda/tienda.page.html <<'JUEGALMI_EOF'
<ion-header class="ion-no-border">
  <app-cabecera>
    <!-- Buscador por voz: se pone turquesa y late mientras escucha -->
    <button type="button" class="redondo microfono" [class.activo]="voz.escuchando()" (click)="buscarPorVoz()"
            [attr.aria-label]="voz.escuchando() ? 'Escuchando…' : 'Buscar por voz'">
      <ion-icon name="mic-outline"></ion-icon>
    </button>
    <button type="button" class="redondo" (click)="alternarBuscador()" [attr.aria-label]="buscando() ? 'Cerrar buscador' : 'Buscar'">
      <ion-icon [name]="buscando() ? 'close-outline' : 'search-outline'"></ion-icon>
    </button>
  </app-cabecera>
</ion-header>

<ion-content class="ion-padding">
  <h1 class="titulo">{{ modo() === 'alquilar' ? 'Alquilar' : 'Tienda' }}</h1>

  @if (buscando()) {
    <ion-searchbar placeholder="Buscar productos" [debounce]="300" [value]="texto()"
                   (ionInput)="buscar($event.detail.value)"></ion-searchbar>
  }

  <ion-segment [value]="modo()" (ionChange)="cambiarModo($event.detail.value)">
    <ion-segment-button value="comprar"><ion-label>Comprar</ion-label></ion-segment-button>
    <ion-segment-button value="alquilar"><ion-label>Alquilar</ion-label></ion-segment-button>
  </ion-segment>

  <div class="chips">
    @for (f of (modo() === 'comprar' ? filtrosComprar : filtrosAlquilar); track f.valor) {
      <ion-chip class="filtro" [class.activo]="filtro() === f.valor" (click)="elegirFiltro(f.valor)">{{ f.etiqueta }}</ion-chip>
    }
  </div>

  @if (error()) {
    <app-estado [error]="true" (reintentar)="cargar()"></app-estado>
  } @else if (cargando()) {
    <!-- Huesos grises mientras llega la API -->
    <div class="rejilla">
      @for (i of [1, 2, 3, 4]; track i) {
        <div class="hueso"><ion-skeleton-text [animated]="true" class="esq-foto"></ion-skeleton-text>
          <ion-skeleton-text [animated]="true" style="width: 80%"></ion-skeleton-text>
          <ion-skeleton-text [animated]="true" style="width: 40%"></ion-skeleton-text></div>
      }
    </div>
  } @else if (!productos().length) {
    @if (texto()) {
      <app-estado icono="search-outline" titulo="Sin resultados" [texto]="'No encontramos nada con «' + texto() + '». Prueba con otra palabra.'"></app-estado>
    } @else {
      <app-estado titulo="Aún no hay productos" texto="Estamos reponiendo la tienda. Vuelve en un rato o mira otra categoría."></app-estado>
    }
  } @else {
    <!-- Rejilla de 2 columnas -->
    <div class="rejilla cascada">
      @for (p of productos(); track p.id) {
        <button type="button" class="producto pulsable" [class.alquilado]="modo() === 'alquilar' && stock(p)?.tipo === 'off'" (click)="abrir(p)">
          <span class="foto">
            <app-miniatura-producto [producto]="p" [sinMarca]="p.tipo === 'videojuego'"></app-miniatura-producto>
            @if (p.tipo === 'videojuego') { <app-plataformas class="columna" [producto]="p"></app-plataformas> }
            @if (stock(p); as e) { <span class="stock" [class.aviso]="e.tipo === 'aviso'">{{ e.texto }}</span> }
          </span>
          <span class="nombre">{{ p.nombre }}</span>
          @if (modo() === 'alquilar') { <app-precio [valor]="p.precio_alquiler_dia ?? 0" sufijo="/ día"></app-precio> }
          @else { <app-precio [valor]="p.precio_venta"></app-precio> }
        </button>
      }
    </div>

    <ion-infinite-scroll [disabled]="!hayMas()" (ionInfinite)="cargarMas($event)">
      <ion-infinite-scroll-content loadingSpinner="crescent"></ion-infinite-scroll-content>
    </ion-infinite-scroll>
  }
</ion-content>
JUEGALMI_EOF

mkdir -p $(dirname src/app/pages/tienda/tienda.page.scss)
cat > src/app/pages/tienda/tienda.page.scss <<'JUEGALMI_EOF'
ion-searchbar { --background: var(--jg-tarjeta); --border-radius: 999px; --box-shadow: none; padding: 0 0 14px; }

.producto { border: 0; padding: 0; background: none; font: inherit; color: var(--ion-text-color); text-align: left; }

// Rejilla de 2 columnas
.rejilla { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 14px; }
.producto {
  display: flex; flex-direction: column; gap: 4px; min-width: 0;
  .nombre { font-size: 15px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; margin-top: 6px; }
  app-precio { font-size: 22px; }
}
.foto {
  position: relative; display: block; aspect-ratio: 4 / 5;
  app-miniatura-producto { --tam: 100%; --radio: 22px; --fondo: var(--jg-tarjeta); width: 100%; height: 100%; }
}

// Alquilar: sin copias libres → apagado y textos en gris legible (#686A62, contraste 4,8:1)
.producto.alquilado {
  app-miniatura-producto { opacity: .55; }
  .nombre, app-precio { color: #686a62; }
}

// Plataformas del juego arriba a la derecha (una debajo de otra si son varias)
.foto app-plataformas { position: absolute; top: 10px; right: 10px; z-index: 1; }

// Etiqueta de stock: «Quedan 2», «Última unidad» (rojo) · «Agotado», «Alquilado» (blanco)
.stock {
  position: absolute; top: 10px; left: 10px; z-index: 1;
  padding: 4px 10px; border-radius: 999px;
  background: #ffffff; color: #1f2329; font-size: 11px; font-weight: 600;
  box-shadow: 0 2px 8px rgba(0, 0, 0, .12);
  &.aviso { background: #a72144; color: #ffffff; }
}

// Huesos grises mientras carga
.hueso { display: flex; flex-direction: column; gap: 6px; }
.esq-foto { aspect-ratio: 4 / 5; height: auto; border-radius: 22px; margin: 0 0 4px; }

// Micrófono del buscador: turquesa y latiendo mientras escucha
.microfono.activo {
  background: var(--jg-acento);
  color: #1f2329;
  animation: latido 1s ease-in-out infinite;
}
@keyframes latido {
  0%, 100% { box-shadow: 0 0 0 0 rgba(120, 205, 208, .6); }
  50%      { box-shadow: 0 0 0 10px rgba(120, 205, 208, 0); }
}
JUEGALMI_EOF

mkdir -p $(dirname src/app/pages/tienda/tienda.page.ts)
cat > src/app/pages/tienda/tienda.page.ts <<'JUEGALMI_EOF'
import { Component, inject, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { ActivatedRoute, Router } from '@angular/router';
import { IonHeader, IonContent, IonSegment, IonSegmentButton, IonLabel, IonSearchbar, IonChip, IonIcon,
         IonSkeletonText, IonInfiniteScroll, IonInfiniteScrollContent, InfiniteScrollCustomEvent } from '@ionic/angular';
import { addIcons } from 'ionicons';
import { searchOutline, closeOutline, micOutline } from 'ionicons/icons';
import { CabeceraComponent } from '../../components/cabecera/cabecera.component';
import { MiniaturaProductoComponent } from '../../components/miniatura-producto/miniatura-producto.component';
import { PrecioComponent } from '../../components/precio/precio.component';
import { PlataformasComponent } from '../../components/plataformas/plataformas.component';
import { forkJoin, map } from 'rxjs';
import { ProductoService } from '../../services/producto.service';
import { VozService } from '../../services/voz.service';
import { EtiquetaStock, Producto, TipoProducto, etiquetaStock } from '../../models/producto.model';
import { EstadoComponent } from '../../components/estado/estado.component';

type Modo = 'comprar' | 'alquilar';
interface Filtro { etiqueta: string; valor: string; }   // valor '' = todos

const POR_PAGINA = 8;   // carga progresiva

@Component({
  selector: 'app-tienda',
  templateUrl: './tienda.page.html',
  styleUrls: ['./tienda.page.scss'],
  imports: [IonHeader, IonContent, IonSegment, IonSegmentButton, IonLabel, IonSearchbar, IonChip, IonIcon,
            IonSkeletonText, IonInfiniteScroll, IonInfiniteScrollContent,
            CabeceraComponent, MiniaturaProductoComponent, PrecioComponent, EstadoComponent, PlataformasComponent],
})
export class TiendaPage {
  private servicio = inject(ProductoService);
  private router = inject(Router);
  voz = inject(VozService);

  modo = signal<Modo>('comprar');
  filtro = signal('');
  texto = signal('');
  buscando = signal(false);          // muestra el buscador (botón lupa)
  productos = signal<Producto[]>([]);
  cargando = signal(true);
  error = signal(false);             // la API no responde → «Sin conexión» + Reintentar
  hayMas = signal(true);

  filtrosComprar: Filtro[] = [
    { etiqueta: 'Todo', valor: '' },
    { etiqueta: 'Videojuegos', valor: 'videojuego' },
    { etiqueta: 'Consolas', valor: 'consola' },
    { etiqueta: 'Móviles', valor: 'movil' },
    { etiqueta: 'Tablets', valor: 'tablet' },
  ];
  // Plataformas de alquiler: se piden a la API (GET /api/videojuegos/plataformas)
  filtrosAlquilar: Filtro[] = [{ etiqueta: 'Todas', valor: '' }];

  private pagina = 1;
  private peticion = 0;   // descarta respuestas antiguas

  constructor() {
    addIcons({ searchOutline, closeOutline, micOutline });
    this.servicio.plataformas().subscribe({
      // «Multi» no es una plataforma: esos juegos salen dentro de PS5, Xbox y Switch
      next: lista => this.filtrosAlquilar = [{ etiqueta: 'Todas', valor: '' },
        ...lista.filter(p => p !== 'Multi').map(p => ({ etiqueta: p, valor: p }))],
      error: () => { /* sin conexión: solo "Todas" */ },
    });
    // ?modo=alquilar (desde la tarjeta "Alquilar" de Inicio)
    inject(ActivatedRoute).queryParamMap.pipe(takeUntilDestroyed()).subscribe(params => {
      this.modo.set(params.get('modo') === 'alquilar' ? 'alquilar' : 'comprar');
      this.filtro.set('');
      this.cargar();
    });
  }

  cambiarModo(valor: unknown): void {
    this.modo.set(valor === 'alquilar' ? 'alquilar' : 'comprar');
    this.filtro.set('');
    this.cargar();
  }

  elegirFiltro(valor: string): void {
    this.filtro.set(valor);
    this.cargar();
  }

  alternarBuscador(): void {
    this.buscando.update(b => !b);
    if (!this.buscando() && this.texto()) this.buscar('');   // al cerrar se limpia
  }

  // Micrófono: lo que se dice se escribe en el buscador y se busca
  async buscarPorVoz(): Promise<void> {
    const texto = await this.voz.escuchar();
    if (!texto) return;
    this.buscando.set(true);
    this.buscar(texto);
  }

  buscar(texto: string | null | undefined): void {
    this.texto.set(texto ?? '');
    this.cargar();
  }

  cargarMas(evento: InfiniteScrollCustomEvent): void {
    this.cargar(false, evento);
  }

  // Comprar: unidades en stock · Alquilar: copias libres
  stock(p: Producto): EtiquetaStock | null {
    return this.modo() === 'alquilar'
      ? etiquetaStock(p.copias_disponibles ?? (p.alquilado ? 0 : 3), true)
      : etiquetaStock(p.stock);
  }

  abrir(p: Producto): void {
    this.router.navigate(['/producto', p.id], { queryParams: { modo: this.modo() } });
  }

  cargar(reiniciar = true, evento?: InfiniteScrollCustomEvent): void {
    if (reiniciar) {
      this.pagina = 1;
      this.cargando.set(true);
      this.error.set(false);
      this.hayMas.set(true);
    }
    const id = ++this.peticion;
    const texto = this.texto().trim();

    // Comprar: GET /api/productos (con q= para buscar) · Alquilar: GET /api/videojuegos/alquiler
    const plataforma = this.modo() === 'alquilar' ? this.filtro() : '';
    const peticion$ = plataforma
      // Una plataforma: sus juegos + los «Multi» (se pueden jugar en las tres), sin paginar
      ? forkJoin([this.servicio.alquiler({ plataforma, limit: 50 }), this.servicio.alquiler({ plataforma: 'Multi', limit: 50 })]).pipe(
          map(([propios, multi]) => ({
            datos: [...propios.datos, ...multi.datos].sort((a, b) => a.nombre.localeCompare(b.nombre)),
            paginacion: { pagina: 1, por_pagina: 100, total: 0, paginas: 1 },
          })))
      : this.modo() === 'alquilar'
      ? this.servicio.alquiler({ page: this.pagina, limit: POR_PAGINA })
      : this.servicio.listar({ tipo: (this.filtro() || undefined) as TipoProducto | undefined, q: texto || undefined,
                               page: this.pagina, limit: POR_PAGINA });

    peticion$.subscribe({
      next: r => {
        if (id !== this.peticion) return;                         // llegó tarde: se ignora
        // En alquiler la API no tiene búsqueda: se filtra lo recibido por el nombre
        const lista = this.modo() === 'alquilar' && texto
          ? r.datos.filter(p => p.nombre.toLowerCase().includes(texto.toLowerCase()))
          : r.datos;
        this.productos.update(actual => reiniciar ? lista : [...actual, ...lista]);
        this.hayMas.set(r.paginacion.pagina < r.paginacion.paginas);   // quedan más páginas
        this.pagina++;
        this.cargando.set(false);
        evento?.target.complete();
      },
      error: () => {
        if (id !== this.peticion) return;
        this.cargando.set(false);
        if (reiniciar) this.error.set(true);
        evento?.target.complete();
      },
    });
  }
}
JUEGALMI_EOF

mkdir -p $(dirname PRUEBAS.md)
cat > PRUEBAS.md <<'JUEGALMI_EOF'
# Pruebas unitarias · JuegAlmi Ionic

Herramienta: **Vitest** con el builder oficial de Angular (`@angular/build:unit-test`) y **jsdom** como navegador simulado.

```bash
cd ionic
npx ng test --watch=false     # una pasada (para la documentación / CI)
npx ng test                   # modo vigilancia: repite al guardar
```

| Archivo | Qué se prueba | Casos |
|---|---|---|
| `validators/validadores.spec.ts` | DNI y NIE (letra correcta/incorrecta, formato, vacío) y teléfono (9 cifras, empieza por 6-9, espacios) | 11 |
| `services/cesta.service.spec.ts` | Cesta: vacía, añadir, sumar cantidad, quitar al llegar a 0, total, guardado en localStorage, vaciar, límite de stock | 7 |
| `models/producto.model.spec.ts` | Etiquetas de stock («Quedan 2», «Última unidad/copia», «Agotado/Alquilado») y plataformas de cada juego («Multi» = las tres) | 7 |
| `components/precio/precio.component.spec.ts` | Precio con céntimos pequeños: 59,99 €, 35,00 €, punto de miles, sufijo "/ día" | 4 |
| `services/voz.service.spec.ts` | Buscador por voz de la Tienda: texto a buscar, quitar «buscar» y signos, frase vacía, navegador sin voz | 5 |
| `pipes/euros.pipe.spec.ts` | Formato en euros y valor vacío | 2 |
| **Total** | | **36** |

Técnicas usadas:
- **TestBed** de Angular para crear servicios y componentes como en la app.
- **Dobles de prueba** (`vi.fn()`) para los avisos (`ToastController`): se comprueba que la app avisa sin mostrar nada en pantalla.
- `localStorage.clear()` antes de cada prueba para que no dependan unas de otras.

Resultado esperado: `Test Files 6 passed (6) · Tests 36 passed (36)`.

Pruebas manuales en dispositivo (no automatizables aquí): cámara, GPS, voz real y agitar el móvil → ver checklist de la defensa.
JUEGALMI_EOF

grep -rl "@ionic/angular/standalone" src | xargs -r sed -i "s#@ionic/angular/standalone#@ionic/angular#g"

echo ""
echo "✔ Paso 19 aplicado: plataformas en color en la Tienda y en la ficha, sin el filtro Multi."
echo "  Prueba: npx ng test --watch=false   y   ionic serve"
