#!/bin/bash
# =====================================================================
# PASO 17 · Las 7 mejoras del prototipo (Abrir_mockup.html)
#   1 Carga / vacío / «Sin conexión» + Reintentar   2 Portada generada si imagen_url es null
#   3 Stock visible («Quedan 2», «Última unidad», «Agotado» → «Avísame»)
#   4 «Añadido a la cesta · Ver cesta» + número sobre la cesta   5 Cancelar pedido en cada tarjeta
#   6 Cálculo del alquiler (días × precio + devolución)          7 Textos grises con buen contraste
#   + Tienda en rejilla de 2 columnas (sin producto destacado)
# Uso (desde la carpeta ionic/):   bash paso17-mejoras-mockup.sh
# =====================================================================
set -e
if [ ! -f angular.json ] || ! grep -q "buscarPorVoz" src/app/pages/tienda/tienda.page.ts 2>/dev/null; then
  echo "✘ Ejecútalo dentro de ionic/ y con el paso 16 (voz solo en Tienda) aplicado"; exit 1
fi
tar czf ../ionic-src-antes-paso17.tgz src PRUEBAS.md 2>/dev/null || tar czf ../ionic-src-antes-paso17.tgz src
echo "• Copia de seguridad: ../ionic-src-antes-paso17.tgz"

mkdir -p $(dirname src/app/components/estado/estado.component.ts)
cat > src/app/components/estado/estado.component.ts <<'JUEGALMI_EOF'
import { Component, input, output } from '@angular/core';
import { IonIcon, IonButton } from '@ionic/angular';
import { addIcons } from 'ionicons';
import { cloudOfflineOutline, refreshOutline, storefrontOutline, receiptOutline, timeOutline,
         buildOutline, searchOutline, bagHandleOutline } from 'ionicons/icons';

// Pantalla de "no hay nada" o "sin conexión" (con botón Reintentar)
@Component({
  selector: 'app-estado',
  template: `
    <div class="estado" [class.error]="error()">
      <span class="icono"><ion-icon [name]="error() ? 'cloud-offline-outline' : icono()"></ion-icon></span>
      <h2>{{ error() ? 'Sin conexión' : titulo() }}</h2>
      <p>{{ error() ? 'No hemos podido hablar con JuegAlmi. Revisa tu conexión e inténtalo otra vez.' : texto() }}</p>
      @if (error()) {
        <ion-button (click)="reintentar.emit()"><ion-icon slot="start" name="refresh-outline"></ion-icon>Reintentar</ion-button>
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

  constructor() {
    addIcons({ cloudOfflineOutline, refreshOutline, storefrontOutline, receiptOutline, timeOutline,
               buildOutline, searchOutline, bagHandleOutline });
  }
}
JUEGALMI_EOF

mkdir -p $(dirname src/app/components/miniatura-producto/miniatura-producto.component.ts)
cat > src/app/components/miniatura-producto/miniatura-producto.component.ts <<'JUEGALMI_EOF'
import { Component, computed, input, signal } from '@angular/core';
import { COLOR_PLATAFORMA, COLOR_PORTADA, TipoProducto } from '../../models/producto.model';

// Vale para un Producto de la API o para un resumen con nombre e imagen
interface ProductoMini {
  id?: number; nombre: string; tipo?: TipoProducto; empresa?: string; plataforma?: string;
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
      @if (marca()) { <span class="marca">{{ marca() }}</span> }
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
  grande = input(false);         // true = usar la imagen original (ficha) en vez de la miniatura
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

mkdir -p $(dirname src/app/models/producto.model.spec.ts)
cat > src/app/models/producto.model.spec.ts <<'JUEGALMI_EOF'
import { describe, it, expect } from 'vitest';
import { etiquetaStock } from './producto.model';

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

mkdir -p $(dirname src/app/pages/alquileres/alquileres.page.html)
cat > src/app/pages/alquileres/alquileres.page.html <<'JUEGALMI_EOF'
<ion-header class="ion-no-border">
  <ion-toolbar>
    <ion-buttons slot="start"><ion-back-button defaultHref="/inicio" text=""></ion-back-button></ion-buttons>
  </ion-toolbar>
</ion-header>

<ion-content class="ion-padding">
  <h1 class="titulo">Mis alquileres</h1>

  @if (error()) {
    <app-estado [error]="true" (reintentar)="cargar()"></app-estado>
  } @else if (cargando()) {
    <ion-skeleton-text [animated]="true" style="height: 260px; border-radius: 24px"></ion-skeleton-text>
  } @else {
    <!-- Alquileres en curso -->
    @for (a of activos(); track a.id) {
      <div class="tarjeta activo">
        <div class="arriba">
          @if (a.lineas[0]; as l) { <app-miniatura-producto [producto]="l.videojuego"></app-miniatura-producto> }
          <div>
            <strong>{{ titulo(a) }}</strong>
            @if (a.dias_restantes >= 0) {
              <p class="dias"><b>{{ a.dias_restantes }}</b> {{ a.dias_restantes === 1 ? 'día' : 'días' }}</p>
            } @else {
              <p class="vencido">Retrasado {{ -a.dias_restantes }} {{ a.dias_restantes === -1 ? 'día' : 'días' }}</p>
            }
          </div>
        </div>
        <div class="barra"><i [style.width.%]="progreso(a) * 100"></i></div>
        <div class="fechas"><span>{{ a.fecha_inicio | fechaCorta }}</span><span>Devolver antes del {{ a.fecha_fin_prevista | fechaCorta }}</span></div>
        <button type="button" class="devolver pulsable" (click)="devolver(a)">
          <ion-icon name="arrow-undo-outline"></ion-icon> Devolver
        </button>
      </div>
    } @empty {
      <app-estado icono="time-outline" titulo="Nada alquilado ahora" texto="Alquila un juego desde la Tienda y aquí verás los días que te quedan."></app-estado>
    }

    <!-- Devueltos -->
    @if (devueltos().length) {
      <h2>Devueltos</h2>
      <div class="cascada">
        @for (a of devueltos(); track a.id) {
          <div class="tarjeta fila">
            @if (a.lineas[0]; as l) { <app-miniatura-producto [producto]="l.videojuego"></app-miniatura-producto> }
            <div class="textos"><strong>{{ titulo(a) }}</strong><small>Devuelto el {{ devueltoEl(a) | fechaCorta }}</small></div>
            <app-precio [valor]="a.importe"></app-precio>
          </div>
        }
      </div>
    }
  }
</ion-content>
JUEGALMI_EOF

mkdir -p $(dirname src/app/pages/alquileres/alquileres.page.ts)
cat > src/app/pages/alquileres/alquileres.page.ts <<'JUEGALMI_EOF'
import { Component, computed, inject, signal } from '@angular/core';
import { IonHeader, IonToolbar, IonButtons, IonBackButton, IonContent, IonIcon, IonSkeletonText,
         AlertController, ToastController } from '@ionic/angular';
import { addIcons } from 'ionicons';
import { arrowUndoOutline } from 'ionicons/icons';
import { EstadoComponent } from '../../components/estado/estado.component';
import { MiniaturaProductoComponent } from '../../components/miniatura-producto/miniatura-producto.component';
import { PrecioComponent } from '../../components/precio/precio.component';
import { FechaCortaPipe } from '../../pipes/fecha-corta.pipe';
import { AlquilerService } from '../../services/alquiler.service';
import { SesionService } from '../../services/sesion.service';
import { ResumenService } from '../../services/resumen.service';
import { Alquiler } from '../../models/alquiler.model';

const DIA = 86400000;

@Component({
  selector: 'app-alquileres',
  templateUrl: './alquileres.page.html',
  styleUrls: ['../cuenta/subpagina.scss', './alquileres.page.scss'],
  imports: [IonHeader, IonToolbar, IonButtons, IonBackButton, IonContent, IonIcon, IonSkeletonText,
            EstadoComponent, MiniaturaProductoComponent, PrecioComponent, FechaCortaPipe],
})
export class AlquileresPage {
  private servicio = inject(AlquilerService);
  private sesion = inject(SesionService);
  private resumen = inject(ResumenService);
  private alerta = inject(AlertController);
  private toast = inject(ToastController);

  todos = signal<Alquiler[]>([]);
  cargando = signal(true);
  error = signal(false);                     // sin conexión → Reintentar

  activos = computed(() => this.todos().filter(a => a.estado !== 'devuelto'));     // activo o retrasado
  devueltos = computed(() => this.todos().filter(a => a.estado === 'devuelto'));

  constructor() {
    addIcons({ arrowUndoOutline });
  }

  ionViewWillEnter(): void {
    this.cargar();
  }

  // Parte del alquiler ya consumida (0 a 1) para la barra
  progreso(a: Alquiler): number {
    const total = this.fecha(a.fecha_fin_prevista) - this.fecha(a.fecha_inicio);
    if (total <= 0) return 1;
    return Math.min(1, Math.max(0, (this.hoy() - this.fecha(a.fecha_inicio)) / total));
  }

  async devolver(a: Alquiler): Promise<void> {
    const alerta = await this.alerta.create({
      header: 'Devolver alquiler',
      message: `¿Confirmas que has devuelto ${this.titulo(a)} en la tienda?`,
      buttons: [
        { text: 'Cancelar', role: 'cancel' },
        { text: 'Devolver', handler: () => {
          this.servicio.devolver(a.id).subscribe({
            next: () => { this.cargar(); this.resumen.refrescar(); this.aviso('Alquiler devuelto. ¡Gracias!', 'dark'); },
            error: e => this.aviso(this.sesion.mensaje(e), 'danger'),
          });
        } },
      ],
    });
    await alerta.present();
  }

  // "Elden Ring" o "Elden Ring +1" si el alquiler tiene varios juegos
  titulo(a: Alquiler): string {
    const n = a.lineas[0]?.videojuego.nombre ?? 'Alquiler';
    return a.lineas.length > 1 ? `${n} +${a.lineas.length - 1}` : n;
  }

  // Fecha real de devolución (la de la última línea devuelta)
  devueltoEl(a: Alquiler): string {
    return a.lineas.map(l => l.fecha_devolucion ?? '').sort().at(-1) || a.fecha_fin_prevista;
  }

  // GET /api/alquileres (el más reciente primero)
  cargar(): void {
    this.error.set(false);
    this.servicio.listar().subscribe({
      next: r => { this.todos.set(r.datos); this.cargando.set(false); },
      error: () => { this.cargando.set(false); this.error.set(true); },
    });
  }

  private async aviso(mensaje: string, color: string): Promise<void> {
    const t = await this.toast.create({ message: mensaje, duration: 2500, color });
    await t.present();
  }

  private fecha(s: string): number { return new Date(s.slice(0, 10) + 'T00:00:00').getTime(); }
  private hoy(): number { const d = new Date(); d.setHours(0, 0, 0, 0); return d.getTime(); }
}
JUEGALMI_EOF

mkdir -p $(dirname src/app/pages/cesta/cesta.page.ts)
cat > src/app/pages/cesta/cesta.page.ts <<'JUEGALMI_EOF'
import { Component, computed, inject, signal } from '@angular/core';
import { Router, RouterLink } from '@angular/router';
import { IonHeader, IonContent, IonIcon, IonButton, IonSpinner, ToastController } from '@ionic/angular';
import { addIcons } from 'ionicons';
import { locationOutline, bagHandleOutline } from 'ionicons/icons';
import { CabeceraComponent } from '../../components/cabecera/cabecera.component';
import { MiniaturaProductoComponent } from '../../components/miniatura-producto/miniatura-producto.component';
import { SelectorCantidadComponent } from '../../components/selector-cantidad/selector-cantidad.component';
import { PrecioComponent } from '../../components/precio/precio.component';
import { CestaService } from '../../services/cesta.service';
import { PedidoService } from '../../services/pedido.service';
import { SesionService } from '../../services/sesion.service';
import { DomicilioService } from '../../services/domicilio.service';

@Component({
  selector: 'app-cesta',
  templateUrl: './cesta.page.html',
  styleUrls: ['./cesta.page.scss'],
  imports: [RouterLink, IonHeader, IonContent, IonIcon, IonButton, IonSpinner,
            CabeceraComponent, MiniaturaProductoComponent, SelectorCantidadComponent, PrecioComponent],
})
export class CestaPage {
  cesta = inject(CestaService);
  private sesion = inject(SesionService);
  private pedidos = inject(PedidoService);
  private domicilios = inject(DomicilioService);
  private router = inject(Router);
  private toast = inject(ToastController);

  enviando = signal(false);
  // Domicilio de envío: el elegido en Direcciones o el más reciente
  direccion = computed(() => { this.domicilios.lista(); this.domicilios.elegidoId(); return this.domicilios.elegido(); });

  constructor() {
    addIcons({ locationOutline, bagHandleOutline });
  }

  // Al entrar se recargan los domicilios (por si se ha añadido o cambiado alguno)
  ionViewWillEnter(): void {
    this.domicilios.cargar().subscribe({ error: () => { /* sin conexión */ } });
  }

  cambiar(productoId: number, cambio: number): void {
    // si llega a 0 se quita; no deja pasar del stock
    if (!this.cesta.cambiarCantidad(productoId, cambio)) this.aviso('No quedan más unidades', 'dark');
  }

  // POST /api/pedidos { id_domicilio, lineas } → todo o nada (sin stock → 409 con el motivo)
  confirmar(): void {
    const d = this.direccion();
    if (!d) {
      this.aviso('Añade una dirección de envío antes de confirmar.', 'danger');
      return;
    }
    this.enviando.set(true);
    this.pedidos.crear(d.id, this.cesta.lineas()).subscribe({
      next: pedido => {
        this.enviando.set(false);
        this.cesta.vaciar();
        this.aviso(`Pedido #${pedido.id} confirmado. ¡Gracias!`, 'dark');
        this.router.navigateByUrl('/cuenta/pedidos');
      },
      error: e => {
        this.enviando.set(false);
        this.aviso(this.sesion.mensaje(e), 'danger');
      },
    });
  }

  private async aviso(mensaje: string, color: string): Promise<void> {
    const t = await this.toast.create({ message: mensaje, duration: 3000, position: 'bottom', color });
    await t.present();
  }
}
JUEGALMI_EOF

mkdir -p $(dirname src/app/pages/detalle-producto/detalle-producto.page.html)
cat > src/app/pages/detalle-producto/detalle-producto.page.html <<'JUEGALMI_EOF'
<ion-content [fullscreen]="true">
  <!-- Foto grande con degradado, botón volver y plataforma -->
  <div class="hero">
    <ion-back-button class="redondo volver" defaultHref="/tienda" text=""></ion-back-button>
    @if (producto(); as p) {
      <span class="plataforma">{{ etiqueta() }}</span>
      <app-miniatura-producto [producto]="p" [grande]="true"></app-miniatura-producto>
    }
  </div>

  <div class="cuerpo">
    @if (producto(); as p) {
      <h1>{{ p.nombre }}</h1>
      <div class="etiquetas">
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
.plataforma {
  position: absolute; z-index: 2;
  top: calc(14px + var(--ion-safe-area-top, 0px)); right: 18px;
  padding: 7px 14px; border-radius: 999px;
  background: rgba(255, 255, 255, .25); border: 1px solid rgba(255, 255, 255, .4);
  color: #ffffff; font-size: 13px; font-weight: 600;
}

.cuerpo { padding: 28px 22px 0; }
h1 { margin: 0 0 12px; font-size: 32px; line-height: 1.05; font-weight: 800; letter-spacing: -0.05em; }
.etiquetas { display: flex; gap: 8px; flex-wrap: wrap; }
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
            IonSpinner, IonSkeletonText, IonIcon, MiniaturaProductoComponent, PrecioComponent, EurosPipe, FechaCortaPipe],
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
  etiqueta = computed(() => {
    const p = this.producto();
    return p ? (p.plataforma ?? NOMBRE_TIPO[p.tipo]) : '';
  });

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

mkdir -p $(dirname src/app/pages/pedidos/pedidos.page.html)
cat > src/app/pages/pedidos/pedidos.page.html <<'JUEGALMI_EOF'
<ion-header class="ion-no-border">
  <ion-toolbar>
    <ion-buttons slot="start"><ion-back-button defaultHref="/inicio" text=""></ion-back-button></ion-buttons>
  </ion-toolbar>
</ion-header>

<ion-content class="ion-padding">
  <h1 class="titulo">Mis pedidos</h1>

  @if (error()) {
    <app-estado [error]="true" (reintentar)="cargar()"></app-estado>
  } @else if (cargando()) {
    @for (i of [1, 2]; track i) {
      <ion-skeleton-text [animated]="true" style="height: 190px; border-radius: 24px; margin-bottom: 14px"></ion-skeleton-text>
    }
  } @else {
    <div class="cascada">
      @for (p of pedidos(); track p.id) {
        <div class="tarjeta pedido">
          <div class="cabecera"><strong>Pedido #{{ p.id }}</strong><span>{{ p.fecha | fechaCorta }}</span></div>

          <!-- Barra de estado (o «Cancelado») -->
          @if (p.estado === 'cancelado') {
            <span class="cancelado">Cancelado</span>
          } @else {
            <div class="barra">
              @for (etapa of pasos; track etapa.estado; let i = $index) {
                <div class="tramo" [class.hecho]="i <= paso(p)" [class.ahora]="i === paso(p)">
                  <i></i><span>{{ etapa.texto }}</span>
                </div>
              }
            </div>
          }

          <div class="pie">
            <div class="minis">
              <app-miniatura-producto [producto]="mini(p)"></app-miniatura-producto>
              @if (p.unidades > 1) { <span class="mas">{{ p.unidades }} uds.</span> }
            </div>
            <app-precio [valor]="p.total"></app-precio>
          </div>

          <!-- Solo en pedidos que no han salido (pendiente / pagado) -->
          @if (p.se_puede_cancelar) {
            <button type="button" class="cancelar pulsable" (click)="cancelar(p)">Cancelar pedido</button>
          }
        </div>
      } @empty {
        <app-estado icono="receipt-outline" titulo="Aún no tienes pedidos" texto="Cuando compres algo en la Tienda lo verás aquí."></app-estado>
      }
    </div>
  }
</ion-content>
JUEGALMI_EOF

mkdir -p $(dirname src/app/pages/pedidos/pedidos.page.scss)
cat > src/app/pages/pedidos/pedidos.page.scss <<'JUEGALMI_EOF'
.pedido {
  padding: 20px 20px 18px; margin-bottom: 14px;
  .cabecera { display: flex; justify-content: space-between; align-items: baseline; }
  strong { font-size: 17px; font-weight: 600; }
  .cabecera span { color: var(--jg-texto-sec); font-size: 15px; }
  app-precio { font-size: 26px; }
}
// Barra de 4 tramos con su texto debajo
.barra { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); align-items: start; gap: 8px; margin: 18px 0 16px; }
.tramo {
  display: flex; flex-direction: column; gap: 10px;
  i { height: 6px; border-radius: 3px; background: var(--jg-segmento); }
  span { font-size: 12px; color: var(--jg-texto-sec); white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
  &.hecho i { background: var(--jg-acento); }
  &.ahora span { color: var(--ion-text-color); font-weight: 600; }
}
.cancelado {
  display: inline-block; margin: 14px 0; padding: 4px 12px; border-radius: 999px;
  background: var(--jg-gris); color: var(--jg-texto-sec); font-size: 13px; font-weight: 600;
}
.pie { display: flex; align-items: flex-end; justify-content: space-between; gap: 12px; }
.minis { display: flex; align-items: flex-end; gap: 10px; }
.minis app-miniatura-producto { --tam: 52px; --radio: 10px; height: 64px; }
.mas { color: var(--jg-texto-sec); font-size: 13px; }

// Cancelar: borde rojo suave, ancho completo
.cancelar {
  width: 100%; min-height: 44px; margin-top: 16px;
  border: 1.5px solid rgba(167, 33, 68, .4); border-radius: 999px;
  background: rgba(244, 228, 233, .6); color: #a72144;
  font: inherit; font-size: 15px; font-weight: 500;
}
JUEGALMI_EOF

mkdir -p $(dirname src/app/pages/pedidos/pedidos.page.ts)
cat > src/app/pages/pedidos/pedidos.page.ts <<'JUEGALMI_EOF'
import { Component, inject, signal } from '@angular/core';
import { IonHeader, IonToolbar, IonButtons, IonBackButton, IonContent, IonSkeletonText,
         AlertController, ToastController } from '@ionic/angular';
import { EstadoComponent } from '../../components/estado/estado.component';
import { MiniaturaProductoComponent } from '../../components/miniatura-producto/miniatura-producto.component';
import { PrecioComponent } from '../../components/precio/precio.component';
import { FechaCortaPipe } from '../../pipes/fecha-corta.pipe';
import { PedidoService } from '../../services/pedido.service';
import { SesionService } from '../../services/sesion.service';
import { EstadoPedido, PedidoResumen } from '../../models/pedido.model';

// Pasos de la barra del pedido en curso
const PASOS: { estado: EstadoPedido; texto: string }[] = [
  { estado: 'pendiente', texto: 'Pendiente' },
  { estado: 'pagado',    texto: 'Preparando' },
  { estado: 'enviado',   texto: 'Enviado' },
  { estado: 'entregado', texto: 'Entregado' },
];

@Component({
  selector: 'app-pedidos',
  templateUrl: './pedidos.page.html',
  styleUrls: ['../cuenta/subpagina.scss', './pedidos.page.scss'],
  imports: [IonHeader, IonToolbar, IonButtons, IonBackButton, IonContent, IonSkeletonText,
            EstadoComponent, MiniaturaProductoComponent, PrecioComponent, FechaCortaPipe],
})
export class PedidosPage {
  private servicio = inject(PedidoService);
  private sesion = inject(SesionService);
  private alerta = inject(AlertController);
  private toast = inject(ToastController);

  pedidos = signal<PedidoResumen[]>([]);     // GET /api/pedidos (el más reciente primero)
  cargando = signal(true);
  error = signal(false);                     // sin conexión → Reintentar
  pasos = PASOS;

  ionViewWillEnter(): void {
    this.cargar();
  }

  // Posición del estado en la barra (0..3)
  paso(p: PedidoResumen): number {
    return PASOS.findIndex(x => x.estado === p.estado);
  }

  estadoTexto(p: PedidoResumen): string {
    return p.estado === 'cancelado' ? 'Cancelado' : PASOS.find(x => x.estado === p.estado)?.texto ?? p.estado;
  }

  // Miniatura del listado: la API trae el nombre y la imagen del primer producto
  mini(p: PedidoResumen) {
    return { nombre: p.primer_producto, imagen_url: p.imagen_url };
  }

  // PUT /api/pedidos/{id}/cancelar (solo pendiente/pagado: se_puede_cancelar)
  async cancelar(p: PedidoResumen): Promise<void> {
    const a = await this.alerta.create({
      header: `¿Cancelar el pedido #${p.id}?`,
      message: 'Se anulará el pedido y se devolverá el stock.',
      buttons: [
        { text: 'No', role: 'cancel' },
        { text: 'Sí, cancelar', role: 'destructive', handler: () => {
          this.servicio.cancelar(p.id).subscribe({
            next: () => { this.aviso('Pedido cancelado.', 'dark'); this.cargar(); },
            error: e => this.aviso(this.sesion.mensaje(e), 'danger'),
          });
        } },
      ],
    });
    await a.present();
  }

  cargar(): void {
    this.error.set(false);
    this.servicio.listar().subscribe({
      next: r => { this.pedidos.set(r.datos); this.cargando.set(false); },
      error: () => { this.cargando.set(false); this.error.set(true); },
    });
  }

  private async aviso(mensaje: string, color: string): Promise<void> {
    const t = await this.toast.create({ message: mensaje, duration: 2500, color });
    await t.present();
  }
}
JUEGALMI_EOF

mkdir -p $(dirname src/app/pages/taller/taller.page.html)
cat > src/app/pages/taller/taller.page.html <<'JUEGALMI_EOF'
<ion-header class="ion-no-border">
  <app-cabecera></app-cabecera>
</ion-header>

<ion-content class="ion-padding">
  <ion-segment [value]="vista()" (ionChange)="cambiarVista($event.detail.value)">
    <ion-segment-button value="nueva"><ion-label>Nueva reparación</ion-label></ion-segment-button>
    <ion-segment-button value="mis"><ion-label>Mis reparaciones</ion-label></ion-segment-button>
  </ion-segment>

  @if (vista() === 'nueva') {
    <!-- Barra de 3 pasos -->
    <div class="pasos" aria-label="Paso {{ paso() }} de 3">
      @for (n of [1, 2, 3]; track n) { <span [class.hecho]="paso() >= n"></span> }
    </div>

    @switch (paso()) {
      <!-- ============ PASO 1: dispositivo ============ -->
      @case (1) {
        <h1 class="titulo">¿Qué reparamos?</h1>

        <div class="tipos">
          @for (t of tipos; track t.valor) {
            <button type="button" class="tipo pulsable" [class.activo]="tipo() === t.valor" (click)="elegirTipo(t.valor)">
              <ion-icon [name]="t.icono"></ion-icon>
              <span>{{ t.texto }}</span>
            </button>
          }
        </div>
        @if (intentado() && errorTipo()) { <p class="error">Elige el tipo de dispositivo.</p> }

        <!-- Marca y Modelo en dos columnas -->
        <div class="dos-campos">
          <div>
            <label class="etiqueta">Marca</label>
            <ion-input [value]="marca()" (ionInput)="marca.set($event.detail.value ?? '')"
                       placeholder="Sony" aria-label="Marca"
                       [class.mal]="intentado() && errorMarca()"></ion-input>
            @if (intentado() && errorMarca()) { <p class="error">Indica la marca.</p> }
          </div>
          <div>
            <label class="etiqueta">Modelo</label>
            <ion-input [value]="modelo()" (ionInput)="modelo.set($event.detail.value ?? '')"
                       placeholder="PlayStation 5" aria-label="Modelo"
                       [class.mal]="intentado() && errorModelo()"></ion-input>
            @if (intentado() && errorModelo()) { <p class="error">Indica el modelo.</p> }
          </div>
        </div>

        @if (tipo()) {
          <label class="etiqueta">Componente afectado</label>
          <div class="chips envolver">
            @for (c of componentes(); track c) {
              <ion-chip class="filtro" [class.activo]="componente() === c" (click)="componente.set(c)">{{ c }}</ion-chip>
            }
          </div>
          @if (intentado() && errorComponente()) { <p class="error">Elige el componente afectado.</p> }
        }
      }

      <!-- ============ PASO 2: avería y fotos ============ -->
      @case (2) {
        <h1 class="titulo">¿Qué le pasa?</h1>

        <label class="etiqueta">Describe el problema</label>
        <ion-textarea [value]="descripcion()" (ionInput)="descripcion.set($event.detail.value ?? '')"
                      [autoGrow]="true" rows="4" placeholder="¿Qué falla? ¿Desde cuándo?" aria-label="Descripción de la avería"
                      [class.mal]="intentado() && errorDescripcion()"></ion-textarea>
        @if (intentado() && errorDescripcion()) { <p class="error">Escribe al menos 10 caracteres.</p> }

        <label class="etiqueta">Fotos ({{ listaFotos().length }}/{{ maxFotos }})</label>
        <div class="fotos">
          @for (f of listaFotos(); track $index) {
            <div class="foto">
              <img [src]="f" alt="Foto {{ $index + 1 }}">
              <button type="button" (click)="quitarFoto($index)" aria-label="Quitar foto"><ion-icon name="close"></ion-icon></button>
            </div>
          }
          @if (listaFotos().length < maxFotos) {
            <button type="button" class="hacer-foto pulsable" (click)="anadirFoto()">
              <ion-icon name="camera-outline"></ion-icon>
              <span>Hacer foto</span>
            </button>
          }
        </div>
        <p class="nota">Opcional, pero ayuda mucho al técnico.</p>
      }

      <!-- ============ PASO 3: resumen ============ -->
      @case (3) {
        <h1 class="titulo">Revisa y envía</h1>

        <div class="tarjeta resumen">
          <div><span>Dispositivo</span><strong>{{ textoTipo() }} · {{ marca() }} {{ modelo() }}</strong></div>
          <div><span>Componente</span><strong>{{ componente() }}</strong></div>
          <div class="bloque"><span>Avería</span><p>{{ descripcion() }}</p></div>
          <div><span>Fotos</span><strong>{{ listaFotos().length }}</strong></div>
        </div>
        <p class="nota">Te avisaremos con el presupuesto antes de reparar.</p>
      }
    }

    <div class="acciones">
      @if (paso() > 1) {
        <ion-button fill="clear" color="dark" (click)="atras()" [disabled]="enviando()">Atrás</ion-button>
      }
      @if (paso() < 3) {
        <ion-button (click)="siguiente()">Siguiente</ion-button>
      } @else {
        <ion-button (click)="enviar()" [disabled]="enviando()">
          @if (enviando()) { <ion-spinner name="crescent"></ion-spinner> } @else { Enviar solicitud }
        </ion-button>
      }
    </div>
  } @else {
    <!-- ============ MIS REPARACIONES ============ -->
    @if (errorMias()) {
      <app-estado [error]="true" (reintentar)="cargarMias()"></app-estado>
    } @else if (cargandoMias()) {
      @for (i of [1, 2]; track i) {
        <ion-skeleton-text [animated]="true" style="height: 150px; border-radius: 24px; margin-bottom: 14px"></ion-skeleton-text>
      }
    } @else {
      @if (enCurso().length) {
        <h1 class="titulo">En curso</h1>
        <div class="cascada">
          @for (r of enCurso(); track r.id) {
            <button type="button" class="tarjeta en-curso pulsable" (click)="abrir(r)">
              <span class="arriba">
                <span class="progreso">
                  <svg viewBox="0 0 60 60" aria-hidden="true">
                    <circle cx="30" cy="30" r="26" class="pista"></circle>
                    <circle cx="30" cy="30" r="26" class="valor" [attr.stroke-dasharray]="vuelta" [attr.stroke-dashoffset]="hueco(r)"></circle>
                  </svg>
                  <b>{{ r.paso }}/{{ r.total_pasos }}</b>
                </span>
                <span class="textos"><strong>{{ tipoTexto(r) }} · {{ r.marca }} {{ r.modelo }}</strong><small>{{ r.estado_texto }}</small></span>
                <ion-icon name="chevron-forward"></ion-icon>
              </span>
              <span class="dato"><span>Entrada</span><span>{{ r.fecha | fechaCorta }}</span></span>
              <span class="dato"><span>Nº</span><span>{{ r.numero }}</span></span>
            </button>
          }
        </div>
      }

      @if (entregadas().length) {
        <div class="seccion"><h2>Entregadas</h2></div>
        @for (r of entregadas(); track r.id) {
          <button type="button" class="tarjeta entregada pulsable" (click)="abrir(r)">
            <ion-icon name="checkmark-circle-outline"></ion-icon>
            <span class="textos"><strong>{{ tipoTexto(r) }} · {{ r.marca }} {{ r.modelo }}</strong><small>{{ r.numero }} · entrada el {{ r.fecha | fechaCorta }}</small></span>
            @if (r.presupuesto != null) { <span class="precio">{{ r.presupuesto | euros }}</span> }
          </button>
        }
      }

      @if (!enCurso().length && !entregadas().length) {
        <app-estado icono="build-outline" titulo="Sin reparaciones" texto="Cuando nos dejes algo para arreglar, aquí verás cómo va."></app-estado>
      }
    }
  }
</ion-content>
JUEGALMI_EOF

mkdir -p $(dirname src/app/pages/taller/taller.page.ts)
cat > src/app/pages/taller/taller.page.ts <<'JUEGALMI_EOF'
import { Component, computed, inject, signal } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { concatMap, from, last, of, switchMap } from 'rxjs';
import { IonHeader, IonContent, IonSegment, IonSegmentButton, IonLabel, IonIcon, IonInput, IonTextarea,
         IonChip, IonButton, IonSpinner, IonSkeletonText, ToastController } from '@ionic/angular';
import { addIcons } from 'ionicons';
import { gameControllerOutline, phonePortraitOutline, tabletLandscapeOutline, laptopOutline, tvOutline,
         headsetOutline, watchOutline, ellipsisHorizontal, cameraOutline, close, chevronForward, keypadOutline, checkmarkCircleOutline } from 'ionicons/icons';
import { EstadoComponent } from '../../components/estado/estado.component';
import { CabeceraComponent } from '../../components/cabecera/cabecera.component';
import { EurosPipe } from '../../pipes/euros.pipe';
import { FechaCortaPipe } from '../../pipes/fecha-corta.pipe';
import { SesionService } from '../../services/sesion.service';
import { ReparacionService } from '../../services/reparacion.service';
import { FotoService } from '../../services/foto.service';
import { NOMBRE_DISPOSITIVO, Reparacion, TipoDispositivo } from '../../models/reparacion.model';

interface OpcionTipo { valor: TipoDispositivo; texto: string; icono: string; }

const MAX_FOTOS = 5;   // la API admite hasta 5 fotos por reparación

// Componentes que se ofrecen según el dispositivo
const COMPONENTES: Record<TipoDispositivo, string[]> = {
  consola:     ['HDMI', 'Ventilador', 'Lector de discos', 'Placa base', 'Puerto de carga', 'Botones'],
  movil:       ['Pantalla', 'Batería', 'Puerto de carga', 'Cámara', 'Botones', 'Altavoz'],
  tablet:      ['Pantalla', 'Batería', 'Puerto de carga', 'Cámara', 'Botones', 'Altavoz'],
  ordenador:   ['Pantalla', 'Batería', 'Teclado', 'Ventilador', 'Placa base', 'Disco duro'],
  mando:       ['Joystick', 'Botones', 'Gatillos', 'Batería', 'Puerto de carga'],
  auriculares: ['Batería', 'Altavoz', 'Micrófono', 'Puerto de carga', 'Bluetooth'],
  reloj:       ['Pantalla', 'Batería', 'Correa', 'Botones'],
  otro:        ['Pantalla', 'Batería', 'Puerto de carga', 'Botones', 'Otro'],
};

@Component({
  selector: 'app-taller',
  templateUrl: './taller.page.html',
  styleUrls: ['./taller.page.scss'],
  imports: [IonHeader, IonContent, IonSegment, IonSegmentButton, IonLabel, IonIcon, IonInput, IonTextarea,
            IonChip, IonButton, IonSpinner, IonSkeletonText, CabeceraComponent, EstadoComponent, EurosPipe, FechaCortaPipe],
})
export class TallerPage {
  private sesion = inject(SesionService);
  private reparaciones = inject(ReparacionService);
  private fotos = inject(FotoService);
  private router = inject(Router);
  private ruta = inject(ActivatedRoute);
  private toast = inject(ToastController);

  vista = signal<'nueva' | 'mis'>('nueva');

  // ----- Formulario en 3 pasos (estado con signals)
  paso = signal(1);
  intentado = signal(false);                 // true al pulsar Siguiente → muestra errores
  tipo = signal<TipoDispositivo | null>(null);
  marca = signal('');                        // "Sony"
  modelo = signal('');                       // "PlayStation 5"
  componente = signal('');
  descripcion = signal('');
  listaFotos = signal<string[]>([]);          // dataURL de cada foto
  enviando = signal(false);
  maxFotos = MAX_FOTOS;

  tipos: OpcionTipo[] = [
    { valor: 'consola', texto: 'Consola', icono: 'game-controller-outline' },
    { valor: 'movil', texto: 'Móvil', icono: 'phone-portrait-outline' },
    { valor: 'tablet', texto: 'Tablet', icono: 'tablet-landscape-outline' },
    { valor: 'ordenador', texto: 'Ordenador', icono: 'laptop-outline' },
    { valor: 'mando', texto: 'Mando', icono: 'keypad-outline' },
    { valor: 'auriculares', texto: 'Auriculares', icono: 'headset-outline' },
    { valor: 'reloj', texto: 'Reloj', icono: 'watch-outline' },
    { valor: 'otro', texto: 'Otro', icono: 'ellipsis-horizontal' },
  ];

  componentes = computed(() => [...COMPONENTES[this.tipo() ?? 'otro'], 'No lo sé']);
  textoTipo = computed(() => this.tipos.find(t => t.valor === this.tipo())?.texto ?? '');

  // Errores de cada paso
  errorTipo = computed(() => !this.tipo());
  errorMarca = computed(() => this.marca().trim().length < 2);
  errorModelo = computed(() => this.modelo().trim().length < 1);
  errorComponente = computed(() => !this.componente());
  errorDescripcion = computed(() => this.descripcion().trim().length < 10);
  pasoValido = computed(() => this.paso() === 1
    ? !this.errorTipo() && !this.errorMarca() && !this.errorModelo() && !this.errorComponente()
    : this.paso() === 2 ? !this.errorDescripcion() : true);

  // ----- Mis reparaciones
  mias = signal<Reparacion[]>([]);
  cargandoMias = signal(true);
  errorMias = signal(false);                 // sin conexión → Reintentar
  enCurso = computed(() => this.mias().filter(r => r.estado !== 'entregada' && r.estado !== 'cancelada'));
  entregadas = computed(() => this.mias().filter(r => r.estado === 'entregada'));
  vuelta = 2 * Math.PI * 26;                 // perímetro del círculo de progreso (radio 26)

  constructor() {
    addIcons({ gameControllerOutline, phonePortraitOutline, tabletLandscapeOutline, laptopOutline, tvOutline,
               headsetOutline, watchOutline, ellipsisHorizontal, cameraOutline, close, chevronForward, keypadOutline, checkmarkCircleOutline });
  }

  ionViewWillEnter(): void {
    if (this.ruta.snapshot.queryParamMap.get('vista') === 'mis') this.vista.set('mis');   // viene del menú lateral
    this.cargarMias();
  }

  cambiarVista(valor: unknown): void {
    this.vista.set(valor === 'mis' ? 'mis' : 'nueva');
    if (valor === 'mis') this.cargarMias();
  }

  elegirTipo(t: TipoDispositivo): void {
    this.tipo.set(t);
    if (!COMPONENTES[t].includes(this.componente())) this.componente.set('');   // el componente depende del tipo
  }

  siguiente(): void {
    this.intentado.set(true);
    if (!this.pasoValido()) return;
    this.intentado.set(false);
    this.paso.update(p => p + 1);
  }

  atras(): void {
    this.intentado.set(false);
    this.paso.update(p => Math.max(1, p - 1));
  }

  // ----- Cámara
  async anadirFoto(): Promise<void> {
    if (this.listaFotos().length >= MAX_FOTOS) return;
    try {
      const foto = await this.fotos.hacerFoto();
      if (foto) this.listaFotos.update(l => [...l, foto]);
    } catch {
      this.aviso('No se ha podido usar la cámara. Revisa los permisos.', 'danger');
    }
  }

  quitarFoto(i: number): void {
    this.listaFotos.update(l => l.filter((_, pos) => pos !== i));
  }

  // ----- Enviar: POST /api/reparaciones y después sube las fotos con su id
  enviar(): void {
    const tipo = this.tipo();
    if (!tipo) return;
    this.enviando.set(true);
    const componente = this.componente() === 'No lo sé' ? undefined : this.componente();

    this.reparaciones.crear({
      tipo_dispositivo: tipo,
      marca: this.marca().trim(),
      modelo: this.modelo().trim(),
      componente,
      descripcion_averia: this.descripcion().trim(),
    }).pipe(
      // Fotos una detrás de otra (multipart, campo "imagen")
      switchMap(rep => this.listaFotos().length
        ? from(this.listaFotos()).pipe(
            concatMap((f, i) => this.reparaciones.subirFoto(rep.id, this.fotos.aBlob(f), `foto${i + 1}.${this.fotos.extension(f)}`)),
            last())
        : of(rep)),
    ).subscribe({
      next: rep => {
        this.enviando.set(false);
        this.reiniciar();
        this.aviso(`Solicitud ${rep.numero} enviada. Te avisaremos con el presupuesto.`, 'dark');
        this.router.navigate(['/taller/reparacion', rep.id]);    // directo al seguimiento
      },
      error: e => {
        this.enviando.set(false);
        this.aviso(this.sesion.mensaje(e), 'danger');
      },
    });
  }

  abrir(rep: Reparacion): void {
    this.router.navigate(['/taller/reparacion', rep.id]);
  }

  // Ayudas para la plantilla (paso, total_pasos y estado_texto ya vienen calculados de la API)
  hueco(r: Reparacion): number { return this.vuelta * (1 - r.paso / r.total_pasos); }
  tipoTexto(r: Reparacion): string { return NOMBRE_DISPOSITIVO[r.tipo_dispositivo] ?? ''; }

  // GET /api/reparaciones (la más reciente primero)
  cargarMias(): void {
    this.errorMias.set(false);
    this.reparaciones.listar(1, 50).subscribe({
      next: r => { this.mias.set(r.datos); this.cargandoMias.set(false); },
      error: () => { this.cargandoMias.set(false); this.errorMias.set(true); },
    });
  }

  private reiniciar(): void {
    this.paso.set(1); this.intentado.set(false); this.tipo.set(null);
    this.marca.set(''); this.modelo.set(''); this.componente.set(''); this.descripcion.set(''); this.listaFotos.set([]);
  }

  private async aviso(mensaje: string, color: string): Promise<void> {
    const t = await this.toast.create({ message: mensaje, duration: 3000, position: 'bottom', color });
    await t.present();
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
        <button type="button" class="producto pulsable" (click)="abrir(p)">
          <span class="foto">
            <app-miniatura-producto [producto]="p"></app-miniatura-producto>
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
            CabeceraComponent, MiniaturaProductoComponent, PrecioComponent, EstadoComponent],
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
      next: lista => this.filtrosAlquilar = [{ etiqueta: 'Todas', valor: '' }, ...lista.map(p => ({ etiqueta: p, valor: p }))],
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
    const peticion$ = this.modo() === 'alquilar'
      ? this.servicio.alquiler({ plataforma: this.filtro() || undefined, page: this.pagina, limit: POR_PAGINA })
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

mkdir -p $(dirname src/app/services/cesta.service.spec.ts)
cat > src/app/services/cesta.service.spec.ts <<'JUEGALMI_EOF'
import { describe, it, expect, beforeEach } from 'vitest';
import { TestBed } from '@angular/core/testing';
import { CestaService } from './cesta.service';
import { Producto } from '../models/producto.model';

// Productos de prueba (solo los campos que usa la cesta)
const zelda = { id: 1, tipo: 'videojuego', nombre: 'Zelda', precio_venta: 59.99, stock: 2 } as Producto;
const ps5 = { id: 4, tipo: 'consola', nombre: 'PS5 Slim', precio_venta: 499.99, stock: 5 } as Producto;

describe('CestaService', () => {
  let cesta: CestaService;

  beforeEach(() => {
    localStorage.clear();                        // cada prueba empieza con la cesta vacía
    TestBed.configureTestingModule({});
    cesta = TestBed.inject(CestaService);
  });

  it('empieza vacía', () => {
    expect(cesta.lineas()).toEqual([]);
    expect(cesta.unidades()).toBe(0);
    expect(cesta.total()).toBe(0);
  });

  it('añade productos y calcula unidades y total', () => {
    cesta.anadir(zelda);
    cesta.anadir(ps5, 2);
    expect(cesta.unidades()).toBe(3);
    expect(cesta.total()).toBe(1059.97);        // 59,99 + 2 × 499,99
  });

  it('si el producto ya está, suma la cantidad en la misma línea', () => {
    cesta.anadir(zelda);
    cesta.anadir(zelda);
    expect(cesta.lineas().length).toBe(1);
    expect(cesta.lineas()[0].cantidad).toBe(2);
  });

  it('quita la línea cuando la cantidad llega a 0', () => {
    cesta.anadir(zelda);
    cesta.cambiarCantidad(zelda.id, -1);
    expect(cesta.lineas()).toEqual([]);
  });

  it('guarda la cesta en localStorage (sobrevive al cerrar la app)', () => {
    cesta.anadir(ps5);
    const guardada = JSON.parse(localStorage.getItem('juegalmi_cesta') ?? '[]');
    expect(guardada[0].producto.id).toBe(4);
  });

  it('vaciar deja la cesta a 0', () => {
    cesta.anadir(zelda);
    cesta.vaciar();
    expect(cesta.unidades()).toBe(0);
  });
  it('no deja añadir más unidades que el stock', () => {
    expect(cesta.anadir(zelda, 2)).toBe(true);
    expect(cesta.anadir(zelda)).toBe(false);          // Zelda tiene stock 2
    expect(cesta.unidades()).toBe(2);
    expect(cesta.cambiarCantidad(1, 1)).toBe(false);
  });
});
JUEGALMI_EOF

mkdir -p $(dirname src/app/services/cesta.service.ts)
cat > src/app/services/cesta.service.ts <<'JUEGALMI_EOF'
import { Injectable, computed, signal } from '@angular/core';
import { LineaCesta } from '../models/pedido.model';
import { Producto } from '../models/producto.model';

const CLAVE = 'juegalmi_cesta';   // clave en localStorage

@Injectable({ providedIn: 'root' })
export class CestaService {
  // Estado de la cesta (signal: la barra inferior y la pantalla Cesta se actualizan solas)
  readonly lineas = signal<LineaCesta[]>(this.leer());

  readonly unidades = computed(() => this.lineas().reduce((s, l) => s + l.cantidad, 0));               // badge
  readonly total = computed(() => +this.lineas().reduce((s, l) => s + l.producto.precio_venta * l.cantidad, 0).toFixed(2));

  // Añade un producto (si ya está, suma cantidad)
  // Devuelve false si se pasaría del stock (no se añade)
  anadir(producto: Producto, cantidad = 1): boolean {
    const lista = this.lineas();
    const existe = lista.find(l => l.producto.id === producto.id);
    if ((existe?.cantidad ?? 0) + cantidad > producto.stock) return false;
    this.guardar(existe
      ? lista.map(l => l.producto.id === producto.id ? { ...l, cantidad: l.cantidad + cantidad } : l)
      : [...lista, { producto, cantidad }]);
    return true;
  }

  // Botones − y + de la cesta (si llega a 0 se quita)
  // Devuelve false si se pasaría del stock
  cambiarCantidad(productoId: number, cambio: number): boolean {
    const linea = this.lineas().find(l => l.producto.id === productoId);
    if (linea && cambio > 0 && linea.cantidad + cambio > linea.producto.stock) return false;
    this.guardar(this.lineas()
      .map(l => l.producto.id === productoId ? { ...l, cantidad: l.cantidad + cambio } : l)
      .filter(l => l.cantidad > 0));
    return true;
  }

  quitar(productoId: number): void {
    this.guardar(this.lineas().filter(l => l.producto.id !== productoId));
  }

  vaciar(): void {
    this.guardar([]);
  }

  // Actualiza el signal y lo guarda en localStorage (la cesta sobrevive al cerrar la app)
  private guardar(lista: LineaCesta[]): void {
    this.lineas.set(lista);
    try { localStorage.setItem(CLAVE, JSON.stringify(lista)); } catch { /* sin almacenamiento */ }
  }

  private leer(): LineaCesta[] {
    try { return JSON.parse(localStorage.getItem(CLAVE) ?? '[]'); } catch { return []; }
  }
}
JUEGALMI_EOF

mkdir -p $(dirname src/app/tabs/tabs.page.html)
cat > src/app/tabs/tabs.page.html <<'JUEGALMI_EOF'
<ion-tabs>
  <ion-tab-bar slot="bottom">
    @for (p of pestanas; track p.ruta) {
      <ion-tab-button [tab]="p.ruta" layout="icon-start" [attr.aria-label]="p.titulo">
        <ion-icon [name]="p.icono"></ion-icon>
        <ion-label>{{ p.titulo }}</ion-label>
        <!-- Número de productos en la cesta -->
        @if (p.ruta === 'cesta' && cesta.unidades() > 0) {
          <span #badge class="punto" aria-hidden="true">{{ cesta.unidades() > 9 ? '9+' : cesta.unidades() }}</span>
        }
      </ion-tab-button>
    }
  </ion-tab-bar>
</ion-tabs>
JUEGALMI_EOF

mkdir -p $(dirname src/app/tabs/tabs.page.scss)
cat > src/app/tabs/tabs.page.scss <<'JUEGALMI_EOF'
// Barra flotante redondeada
ion-tab-bar {
  --background: #1f2329;                // barra oscura (mockup final)
  --border: 0;
  height: 64px;
  margin: 0 14px calc(12px + var(--ion-safe-area-bottom, 0px));
  padding: 0 8px !important;
  border-radius: 999px;
  box-shadow: var(--jg-sombra);
}

// Pestañas inactivas: solo icono
ion-tab-button {
  --color: rgba(255, 255, 255, 0.78);   // iconos claros sobre la barra oscura
  --color-selected: #1f2329;
  --ripple-color: transparent;
  flex: 1 1 0;
  min-width: 0;
  max-width: none;
  overflow: visible;

  ion-icon { font-size: 22px; margin: 0; }
  ion-label { display: none; }
}

// Pestaña activa: píldora turquesa con icono + texto
ion-tab-button.tab-selected {
  flex: 0 0 auto;
  align-self: center;
  height: 48px;
  padding: 0 18px 0 14px;
  border-radius: 999px;
  background: var(--jg-acento);

  ion-label { display: block; margin: 0 0 0 8px; font-size: 15px; font-weight: 600; }
}

// Número de la cesta
.punto {
  position: absolute;
  top: 6px;
  right: 4px;
  min-width: 20px; height: 20px; padding: 0 5px;
  display: grid; place-items: center;
  border-radius: 999px;
  background: #a72144; color: #ffffff;
  font-size: 11px; font-weight: 700; line-height: 1;
  border: 2px solid #1f2329;
}
ion-tab-button.tab-selected .punto { top: 0; right: 0; }

// Sin cambio de color al pasar el ratón ni al enfocar (Ionic usaba el color "seleccionado", que es oscuro)
ion-tab-button:not(.tab-selected) {
  --color-selected: rgba(255, 255, 255, 0.78);   // hover: mismo color que en reposo
  --color-focused: rgba(255, 255, 255, 0.78);    // foco con teclado: igual
}
ion-tab-button {
  --background-focused: transparent;             // sin fondo al enfocar
  --background-focused-opacity: 0;
}
ion-tab-button.tab-selected { --color-focused: #1f2329; }
JUEGALMI_EOF

mkdir -p $(dirname src/app/tabs/tabs.page.ts)
cat > src/app/tabs/tabs.page.ts <<'JUEGALMI_EOF'
import { Component, ElementRef, effect, inject, viewChild } from '@angular/core';
import { IonTabs, IonTabBar, IonTabButton, IonIcon, IonLabel, AnimationController } from '@ionic/angular';
import { addIcons } from 'ionicons';
import { homeOutline, storefrontOutline, buildOutline, bagHandleOutline,
         informationCircleOutline, personOutline } from 'ionicons/icons';
import { CestaService } from '../services/cesta.service';

interface Pestana { ruta: string; titulo: string; icono: string; }

@Component({
  selector: 'app-tabs',
  templateUrl: 'tabs.page.html',
  styleUrls: ['tabs.page.scss'],
  imports: [IonTabs, IonTabBar, IonTabButton, IonIcon, IonLabel],
})
export class TabsPage {
  cesta = inject(CestaService);
  private animaciones = inject(AnimationController);
  private badge = viewChild('badge', { read: ElementRef });   // <span #badge>
  private anterior = this.cesta.unidades();

  pestanas: Pestana[] = [
    { ruta: 'inicio',   titulo: 'Inicio',   icono: 'home-outline' },
    { ruta: 'tienda',   titulo: 'Tienda',   icono: 'storefront-outline' },
    { ruta: 'taller',   titulo: 'Taller',   icono: 'build-outline' },
    { ruta: 'cesta',    titulo: 'Cesta',    icono: 'bag-handle-outline' },
    { ruta: 'nosotros', titulo: 'Nosotros', icono: 'information-circle-outline' },
  ];

  constructor() {
    addIcons({ homeOutline, storefrontOutline, buildOutline, bagHandleOutline,
               informationCircleOutline, personOutline });

    // Al añadir algo a la cesta, el punto rojo bota
    effect(() => {
      const unidades = this.cesta.unidades();
      if (unidades > this.anterior) setTimeout(() => this.botar());
      this.anterior = unidades;
    });
  }

  private botar(): void {
    const el = this.badge()?.nativeElement as HTMLElement | undefined;
    if (!el) return;
    this.animaciones.create()
      .addElement(el)
      .duration(450)
      .easing('cubic-bezier(.34, 1.56, .64, 1)')
      .keyframes([
        { offset: 0, transform: 'scale(1)' },
        { offset: 0.4, transform: 'scale(1.4)' },
        { offset: 1, transform: 'scale(1)' },
      ])
      .play();
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
| `models/producto.model.spec.ts` | Etiquetas de stock: «Quedan 2», «Última unidad/copia», «Agotado/Alquilado» | 4 |
| `components/precio/precio.component.spec.ts` | Precio con céntimos pequeños: 59,99 €, 35,00 €, punto de miles, sufijo "/ día" | 4 |
| `services/voz.service.spec.ts` | Buscador por voz de la Tienda: texto a buscar, quitar «buscar» y signos, frase vacía, navegador sin voz | 5 |
| `pipes/euros.pipe.spec.ts` | Formato en euros y valor vacío | 2 |
| **Total** | | **33** |

Técnicas usadas:
- **TestBed** de Angular para crear servicios y componentes como en la app.
- **Dobles de prueba** (`vi.fn()`) para los avisos (`ToastController`): se comprueba que la app avisa sin mostrar nada en pantalla.
- `localStorage.clear()` antes de cada prueba para que no dependan unas de otras.

Resultado esperado: `Test Files 6 passed (6) · Tests 33 passed (33)`.

Pruebas manuales en dispositivo (no automatizables aquí): cámara, GPS, voz real y agitar el móvil → ver checklist de la defensa.
JUEGALMI_EOF

grep -rl "@ionic/angular/standalone" src | xargs -r sed -i "s#@ionic/angular/standalone#@ionic/angular#g"

echo ""
echo "✔ Paso 17 aplicado: mejoras del prototipo (portadas, stock, estados, aviso de cesta, cancelar, alquiler)."
echo "  Prueba: npx ng test --watch=false   y   ionic serve"
