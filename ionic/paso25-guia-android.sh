#!/bin/bash
# =====================================================================
# PASO 25 · Guía de cambios de Maitane: Ionic igual que Android
#   1 Diseño de Android: Roboto, 4 colores, tamaños (título 40, botón 48, campos 44, barra 56)
#   2 ion-list + ion-card (RecyclerView/CardView) e ion-img en las 8 páginas con listas
#   3 Nueva reparación en una sola pantalla con 13 componentes y un único mensaje de error
#   4 Textos de Android: seguimiento, listas vacías con botón, «Algo ha fallado», formularios,
#     «Sin teléfono»
#   5 Etiquetas de stock en Tienda e Inicio (avisoStock) y tarjeta agotada en gris
#   6 Mis pedidos: el último arriba + «Anteriores» con «Ver más»
#   7 Mapa fijo con Esri, sin distancia (la ubicación se sigue enviando a la API)
#   8 Ficha: animaciones «aparecer» y «latido»
#   9 Fuera las páginas cuenta, ajustes, ayuda y notificaciones
# Uso (desde la carpeta ionic/):   bash paso25-guia-android.sh
# =====================================================================
set -e
if [ ! -f angular.json ] || ! grep -q "abierto = signal" src/app/pages/pedidos/pedidos.page.ts 2>/dev/null; then
  echo "✘ Ejecútalo dentro de ionic/ y con el paso 22 o posterior aplicado"; exit 1
fi
mkdir -p ~/Escritorio/copias-ionic
tar czf ~/Escritorio/copias-ionic/ionic-src-antes-paso25.tgz src PRUEBAS.md package.json package-lock.json
echo "• Copia de seguridad: ~/Escritorio/copias-ionic/ionic-src-antes-paso25.tgz"

# 1.1 Fuente Roboto (la de Android) en vez de Inter
npm install @fontsource/roboto
npm uninstall @fontsource/inter

# 9. Páginas que no se usan (subpagina.scss pasa a pages/, la usan las demás subpáginas)
rm -rf src/app/pages/ajustes
rm -rf src/app/pages/ayuda
rm -rf src/app/pages/cuenta
rm -rf src/app/pages/notificaciones

mkdir -p $(dirname src/app/components/estado/estado.component.ts)
cat > src/app/components/estado/estado.component.ts <<'JUEGALMI_EOF'
import { Component, input, output } from '@angular/core';
import { IonIcon, IonButton } from '@ionic/angular';
import { addIcons } from 'ionicons';
import { cloudOfflineOutline, refreshOutline, storefrontOutline, receiptOutline, timeOutline,
         buildOutline, searchOutline, bagHandleOutline } from 'ionicons/icons';

// Pantalla de lista vacía (con botón de acción opcional) o de error al cargar (con Reintentar)
@Component({
  selector: 'app-estado',
  template: `
    <div class="estado" [class.error]="error()">
      <span class="icono"><ion-icon [name]="error() ? 'cloud-offline-outline' : icono()"></ion-icon></span>
      <h2>{{ error() ? 'Algo ha fallado' : titulo() }}</h2>
      <p>{{ error() ? 'No se puede conectar con el servidor.' : texto() }}</p>
      @if (error()) {
        <ion-button (click)="reintentar.emit()"><ion-icon slot="start" name="refresh-outline"></ion-icon>Reintentar</ion-button>
      }
      @if (!error() && boton()) {
        <ion-button (click)="accion.emit()">{{ boton() }}</ion-button>
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
  boton = input('');                 // texto del botón de las listas vacías (vacío = sin botón)
  accion = output<void>();

  constructor() {
    addIcons({ cloudOfflineOutline, refreshOutline, storefrontOutline, receiptOutline, timeOutline,
               buildOutline, searchOutline, bagHandleOutline });
  }
}
JUEGALMI_EOF

mkdir -p $(dirname src/app/components/miniatura-producto/miniatura-producto.component.ts)
cat > src/app/components/miniatura-producto/miniatura-producto.component.ts <<'JUEGALMI_EOF'
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
JUEGALMI_EOF

mkdir -p $(dirname src/app/models/producto.model.spec.ts)
cat > src/app/models/producto.model.spec.ts <<'JUEGALMI_EOF'
import { describe, it, expect } from 'vitest';
import { Producto, avisoStock, colorPlataforma, etiquetaStock, plataformasDe } from './producto.model';

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
  it('«Multi» (antiguo) se juega en las tres', () => {
    expect(plataformasDe({ plataforma: 'Multi' })).toEqual(['PlayStation', 'Xbox', 'Switch']);
  });

  it('una sola plataforma', () => {
    expect(plataformasDe({ plataforma: 'Xbox' })).toEqual(['Xbox']);
  });

  it('si la API manda una lista (p. ej. dos plataformas) se usa tal cual', () => {
    expect(plataformasDe({ plataforma: 'Multi', plataformas: ['PS5', 'Xbox'] })).toEqual(['PS5', 'Xbox']);
  });
});

describe('Color de cada plataforma', () => {
  it('PlayStation en azul, la escriba como la escriba', () => {
    for (const pl of ['PlayStation', 'PS5', 'ps5', 'PlayStation 5']) expect(colorPlataforma(pl)).toBe('#0070d1');
  });

  it('Xbox en verde y Switch en rojo', () => {
    expect(colorPlataforma('Xbox Series X')).toBe('#107c10');
    expect(colorPlataforma('Nintendo Switch')).toBe('#e60012');
  });
});

describe('avisoStock (la misma regla que Android)', () => {
  const p = (stock: number, extra = {}) => ({ id: 1, tipo: 'videojuego', nombre: 'Zelda', stock, disponible: true, ...extra }) as unknown as Producto;

  it('comprar: Agotado si no hay stock o no está disponible', () => {
    expect(avisoStock(p(0), false)).toEqual({ texto: 'Agotado', agotado: true });
    expect(avisoStock(p(5, { disponible: false }), false)?.agotado).toBe(true);
  });

  it('alquilar: usa las copias libres', () => {
    expect(avisoStock(p(9, { copias_disponibles: 1 }), true)).toEqual({ texto: 'Última copia', agotado: false });
    expect(avisoStock(p(9, { copias_disponibles: 0 }), true)?.texto).toBe('Alquilado');
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
  PlayStation: '#375e60', PS5: '#375e60', Xbox: '#5c616c', Switch: '#5ea0a2', Multi: '#8a8c84',
};
export const COLOR_PORTADA = '#1f2329';          // consolas, móviles, tablets y sin plataforma

// Plataforma del juego. La API manda una por producto ("PlayStation", "Switch", "Xbox"): un juego de
// varias plataformas viene repetido, uno por cada una. "Multi" (antiguo) = las tres
export const PLATAFORMAS = ['PlayStation', 'Xbox', 'Switch'] as const;
export function plataformasDe(p: { plataforma?: string | null; plataformas?: string[] }): string[] {
  if (p.plataformas?.length) return p.plataformas;
  if (!p.plataforma) return [];
  return p.plataforma.trim().toLowerCase() === 'multi' ? [...PLATAFORMAS] : [p.plataforma.trim()];
}
// Xbox verde · PlayStation azul · Switch rojo. Se reconoce como venga escrito
// ("PS5", "PS4", "PlayStation 5", "ps5", "Nintendo Switch", "Xbox Series"...)
export function colorPlataforma(plataforma: string): string {
  const t = plataforma.toLowerCase();
  if (t.includes('xbox')) return '#107c10';                              // verde
  if (t.includes('ps') || t.includes('playstation')) return '#0070d1';   // azul
  if (t.includes('switch') || t.includes('nintendo')) return '#e60012';  // rojo
  return '#5c616c';                                                      // otra: gris
}

// Etiqueta de stock: «Quedan 2», «Última unidad», «Agotado» (en alquiler: «Última copia», «Alquilado»)
export interface EtiquetaStock { texto: string; tipo: 'aviso' | 'off'; }
export function etiquetaStock(n: number, alquiler = false): EtiquetaStock | null {
  if (n <= 0) return { texto: alquiler ? 'Alquilado' : 'Agotado', tipo: 'off' };
  if (n === 1) return { texto: alquiler ? 'Última copia' : 'Última unidad', tipo: 'aviso' };
  if (n === 2) return { texto: 'Quedan 2', tipo: 'aviso' };
  return null;                                   // 3 o más: sin etiqueta
}

// Etiqueta de stock de las tarjetas (la misma regla que ProductoAdapter.pintarAviso() de Android)
export function avisoStock(p: Producto, alquiler: boolean): { texto: string; agotado: boolean } | null {
  const quedan = alquiler ? (p.copias_disponibles ?? (p.alquilado ? 0 : 3)) : p.stock;
  if (quedan <= 0 || p.disponible === false) return { texto: alquiler ? 'Alquilado' : 'Agotado', agotado: true };
  const e = etiquetaStock(quedan, alquiler);
  return e ? { texto: e.texto, agotado: false } : null;
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
    @if (!activos().length && !devueltos().length) {
      <app-estado icono="time-outline" titulo="Sin alquileres" texto="Todavía no has alquilado ningún juego. Puedes hacerlo desde la tienda."
                  boton="Ir a la tienda" (accion)="irATienda()"></app-estado>
    }

    <!-- Alquileres en curso (ion-card = CardView) -->
    @for (a of activos(); track a.id) {
      <ion-card class="tarjeta activo">
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
      </ion-card>
    }

    <!-- Devueltos -->
    @if (devueltos().length) {
      <h2>Devueltos</h2>
      <!-- ion-list + ion-item = RecyclerView con filas sencillas -->
      <ion-list class="lista devueltos cascada">
        @for (a of devueltos(); track a.id) {
          <ion-item lines="full">
            @if (a.lineas[0]; as l) { <app-miniatura-producto slot="start" [producto]="l.videojuego"></app-miniatura-producto> }
            <ion-label><strong>{{ titulo(a) }}</strong><small>Devuelto el {{ devueltoEl(a) | fechaCorta }}</small></ion-label>
            <app-precio slot="end" [valor]="a.importe"></app-precio>
          </ion-item>
        }
      </ion-list>
    }
  }
</ion-content>
JUEGALMI_EOF

mkdir -p $(dirname src/app/pages/alquileres/alquileres.page.scss)
cat > src/app/pages/alquileres/alquileres.page.scss <<'JUEGALMI_EOF'
.activo { padding: 22px; margin: 0 0 14px; }
.arriba {
  display: flex; gap: 24px;
  app-miniatura-producto { --tam: 112px; --radio: 16px; height: 150px; }
  strong { font-size: 19px; font-weight: 600; }
}
.dias { margin: 34px 0 0; color: var(--jg-texto-sec); font-size: 15px; b { color: var(--ion-text-color); font-size: 56px; font-weight: 700; line-height: 1; letter-spacing: -0.04em; } }
.vencido { margin: 34px 0 0; color: var(--ion-color-danger); font-size: 22px; font-weight: 700; }
.barra { height: 8px; margin-top: 22px; border-radius: 4px; background: var(--jg-segmento); overflow: hidden;
  i { display: block; height: 100%; border-radius: 4px; background: var(--jg-acento); } }
.fechas { display: flex; justify-content: space-between; margin-top: 10px; color: var(--jg-texto-sec); font-size: 14px; }
.devolver {
  display: flex; align-items: center; justify-content: center; gap: 10px;
  width: 100%; height: 56px; margin-top: 22px; border-radius: 999px;
  border: 1px solid var(--jg-borde); background: var(--jg-tarjeta);
  color: var(--ion-text-color); font: inherit; font-size: 17px; font-weight: 500;
  ion-icon { font-size: 20px; }
}

// Devueltos: filas sencillas (ion-item) dentro de una tarjeta
.devueltos {
  border-radius: var(--jg-radio); overflow: hidden; background: var(--jg-tarjeta) !important;
  ion-item { --background: var(--jg-tarjeta); --padding-start: 14px; --inner-padding-end: 16px; --min-height: 84px; --border-color: var(--jg-borde); }
  app-miniatura-producto { --tam: 56px; --radio: 12px; --fondo: #ffffff; --ajuste: contain; margin: 10px 14px 10px 0; }
  ion-label { display: flex !important; flex-direction: column; gap: 4px; white-space: normal; }
  strong { font-size: 16px; font-weight: 500; }
  small { color: var(--jg-texto-sec); font-size: 14px; }
  app-precio { font-size: 20px; }
}
JUEGALMI_EOF

mkdir -p $(dirname src/app/pages/alquileres/alquileres.page.ts)
cat > src/app/pages/alquileres/alquileres.page.ts <<'JUEGALMI_EOF'
import { nombreProducto } from '../../pipes/nombre-producto.pipe';
import { Router } from '@angular/router';
import { Component, computed, inject, signal } from '@angular/core';
import { IonHeader, IonToolbar, IonButtons, IonBackButton, IonContent, IonIcon, IonSkeletonText,
         AlertController, ToastController, IonList, IonCard, IonItem, IonLabel } from '@ionic/angular';
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
  styleUrls: ['../subpagina.scss', './alquileres.page.scss'],
  imports: [IonList, IonCard, IonItem, IonLabel, IonHeader, IonToolbar, IonButtons, IonBackButton, IonContent, IonIcon, IonSkeletonText,
            EstadoComponent, MiniaturaProductoComponent, PrecioComponent, FechaCortaPipe],
})
export class AlquileresPage {
  private router = inject(Router);
  irATienda(): void { this.router.navigateByUrl('/tienda'); }

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
    const n = a.lineas[0] ? nombreProducto(a.lineas[0].videojuego) : 'Alquiler';
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

mkdir -p $(dirname src/app/pages/cesta/cesta.page.html)
cat > src/app/pages/cesta/cesta.page.html <<'JUEGALMI_EOF'
<ion-header class="ion-no-border">
  <app-cabecera></app-cabecera>
</ion-header>

<ion-content class="ion-padding">
  <h1 class="titulo">Cesta</h1>

  @if (cesta.lineas().length) {
    <div class="cascada">
      <!-- ion-list = RecyclerView · ion-card = CardView -->
      <ion-list class="lista">
      @for (l of cesta.lineas(); track l.producto.id) {
        <ion-card class="tarjeta">
        <div class="linea">
          <app-miniatura-producto [producto]="l.producto"></app-miniatura-producto>
          <div class="datos">
            <strong>{{ l.producto | nombreProducto }}</strong>
            <app-precio [valor]="l.producto.precio_venta"></app-precio>
          </div>
          <app-selector-cantidad [vertical]="true" [valor]="l.cantidad" [min]="0" [max]="l.producto.stock"
                                 (cambio)="cambiar(l.producto.id, $event)"></app-selector-cantidad>
        </div>
        </ion-card>
      }
      </ion-list>

      <!-- Dirección de envío -->
      <div class="tarjeta direccion">
        <ion-icon name="location-outline"></ion-icon>
        <span>
          @if (direccion(); as d) { {{ d.texto }} } @else { Sin dirección de envío }
        </span>
        <a routerLink="/cuenta/direcciones">{{ direccion() ? 'Cambiar' : 'Añadir' }}</a>
      </div>

      <!-- Total -->
      <div class="total">
        <div class="linea-total"><span>Envío</span><span>Gratis</span></div>
        <div class="linea-total"><span>Total</span><app-precio [valor]="cesta.total()"></app-precio></div>
        <ion-button expand="block" (click)="confirmar()" [disabled]="enviando()">
          @if (enviando()) { <ion-spinner name="crescent"></ion-spinner> } @else { Confirmar pedido }
        </ion-button>
      </div>
    </div>
  } @else {
    <app-estado icono="bag-handle-outline" titulo="Tu cesta está vacía" texto="Añade productos desde la tienda y aparecerán aquí."
                boton="Ir a la tienda" (accion)="irATienda()"></app-estado>
  }
</ion-content>
JUEGALMI_EOF

mkdir -p $(dirname src/app/pages/cesta/cesta.page.scss)
cat > src/app/pages/cesta/cesta.page.scss <<'JUEGALMI_EOF'
ion-list.lista ion-card { margin-bottom: 14px; }
.linea {
  display: flex; align-items: center; gap: 18px;
  padding: 14px;

  app-miniatura-producto { --tam: 92px; --radio: 16px; --fondo: #ffffff; --ajuste: contain; }
  .datos { flex-grow: 1; display: flex; flex-direction: column; gap: 6px; min-width: 0; }
  strong { font-size: 17px; font-weight: 600; }
  app-precio { font-size: 21px; }
}

.direccion {
  display: flex; align-items: center; gap: 14px;
  padding: 18px 22px; margin-bottom: 14px; font-size: 16px;
  ion-icon { font-size: 20px; color: var(--jg-texto-sec); flex-shrink: 0; }
  span { flex-grow: 1; }
  a { color: var(--ion-text-color); font-weight: 500; text-decoration: none; }
}

// Tarjeta oscura del total (clara en modo oscuro)
.total {
  padding: 22px 22px 22px; border-radius: 28px;
  background: var(--jg-inverso); color: var(--jg-inverso-texto);

  .linea-total { display: flex; align-items: flex-end; justify-content: space-between; margin-bottom: 10px; font-size: 16px; }
  .linea-total:first-child span:first-child { opacity: .5; }
  app-precio { font-size: 48px; }
  ion-button { margin-top: 12px; min-height: 58px; }
}

.vacia {
  display: flex; flex-direction: column; align-items: center; gap: 8px; margin-top: 60px;
  color: var(--jg-texto-sec);
  ion-icon { font-size: 56px; }
}
JUEGALMI_EOF

mkdir -p $(dirname src/app/pages/cesta/cesta.page.ts)
cat > src/app/pages/cesta/cesta.page.ts <<'JUEGALMI_EOF'
import { Component, computed, inject, signal } from '@angular/core';
import { Router, RouterLink } from '@angular/router';
import { IonHeader, IonContent, IonIcon, IonButton, IonSpinner, ToastController, IonList, IonCard } from '@ionic/angular';
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
import { NombreProductoPipe } from '../../pipes/nombre-producto.pipe';
import { EstadoComponent } from '../../components/estado/estado.component';

@Component({
  selector: 'app-cesta',
  templateUrl: './cesta.page.html',
  styleUrls: ['./cesta.page.scss'],
  imports: [EstadoComponent, IonList, IonCard, RouterLink, IonHeader, IonContent, IonIcon, IonButton, IonSpinner,
            CabeceraComponent, MiniaturaProductoComponent, SelectorCantidadComponent, PrecioComponent, NombreProductoPipe],
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

  irATienda(): void { this.router.navigateByUrl('/tienda'); }

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

mkdir -p $(dirname src/app/pages/datos-personales/datos-personales.page.html)
cat > src/app/pages/datos-personales/datos-personales.page.html <<'JUEGALMI_EOF'
<ion-header class="ion-no-border">
  <ion-toolbar>
    <ion-buttons slot="start"><ion-back-button defaultHref="/inicio" text=""></ion-back-button></ion-buttons>
  </ion-toolbar>
</ion-header>

<ion-content class="ion-padding">
  @if (sesion.usuario(); as u) {
    <div class="perfil">
      <div class="avatar">
        @if (u.foto_perfil_url; as foto) { <img [src]="foto" alt="Foto de perfil"> } @else { {{ sesion.iniciales() }} }
      </div>
      <h1>{{ sesion.nombreCompleto() }}</h1>
      <span>{{ desde() }}</span>
    </div>

    <div class="tarjeta datos">
      <div><span>Nombre completo</span><strong>{{ u.nombre }} {{ u.apellido1 }} {{ u.apellido2 }}</strong></div>
      <div><span>DNI</span><strong>{{ u.dni }}</strong></div>
      <div><span>Email</span><strong>{{ u.email }}</strong></div>
      <div><span>Teléfono</span><strong>{{ u.telefono || 'Sin teléfono' }}</strong></div>
      <div><span>Contraseña</span><strong>••••••••</strong></div>
    </div>
  }
</ion-content>

<ion-footer class="ion-no-border">
  <div class="pie-boton">
    <ion-button expand="block" routerLink="/cuenta/datos-personales/editar">
      <ion-icon slot="start" name="create-outline"></ion-icon>
      Editar datos
    </ion-button>
  </div>
</ion-footer>
JUEGALMI_EOF

mkdir -p $(dirname src/app/pages/datos-personales/datos-personales.page.scss)
cat > src/app/pages/datos-personales/datos-personales.page.scss <<'JUEGALMI_EOF'
.perfil {
  display: flex; flex-direction: column; align-items: center; text-align: center; margin: 4px 0 26px;
  h1 { margin: 20px 0 6px; font-size: 32px; font-weight: 700; letter-spacing: -0.05em; }
  span { color: var(--jg-texto-sec); font-size: 16px; }
}
.avatar {
  width: 112px; height: 112px; border-radius: 50%; overflow: hidden;
  display: flex; align-items: center; justify-content: center;
  background: var(--jg-acento); color: #1f2329; font-size: 46px; font-weight: 700; letter-spacing: -0.05em;
  img { width: 100%; height: 100%; object-fit: cover; }
}
.datos {
  padding: 4px 22px;
  div { display: flex; flex-direction: column; gap: 6px; padding: 16px 0; border-bottom: 1px solid var(--jg-borde); }
  div:last-child { border-bottom: 0; }
  span { color: var(--jg-texto-sec); font-size: 14px; }
  strong { font-size: 17px; font-weight: 500; }
}
JUEGALMI_EOF

mkdir -p $(dirname src/app/pages/datos-personales/datos-personales.page.ts)
cat > src/app/pages/datos-personales/datos-personales.page.ts <<'JUEGALMI_EOF'
import { Component, computed, inject } from '@angular/core';
import { RouterLink } from '@angular/router';
import { IonHeader, IonToolbar, IonButtons, IonBackButton, IonContent, IonFooter, IonButton, IonIcon } from '@ionic/angular';
import { addIcons } from 'ionicons';
import { createOutline } from 'ionicons/icons';
import { SesionService } from '../../services/sesion.service';

const FORMATO = new Intl.DateTimeFormat('es-ES', { day: 'numeric', month: 'short', year: 'numeric' });

@Component({
  selector: 'app-datos-personales',
  templateUrl: './datos-personales.page.html',
  styleUrls: ['../subpagina.scss', './datos-personales.page.scss'],
  imports: [RouterLink, IonHeader, IonToolbar, IonButtons, IonBackButton, IonContent, IonFooter, IonButton, IonIcon],
})
export class DatosPersonalesPage {
  sesion = inject(SesionService);

  // "Cliente desde 1 sept 2025"
  desde = computed(() => {
    const f = this.sesion.usuario()?.fecha_registro;
    return f ? 'Cliente desde ' + FORMATO.format(new Date(f.slice(0, 10) + 'T00:00:00')).replace('.', '') : 'Cliente de JuegAlmi';
  });

  constructor() {
    addIcons({ createOutline });
  }
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
      <!-- Datos: entran subiendo 24 px (Animaciones.aparecer() de Android) -->
      <div class="aparecer">
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
      </div>
    } @else {
      <ion-skeleton-text [animated]="true" style="width: 80%; height: 34px"></ion-skeleton-text>
      <ion-skeleton-text [animated]="true" style="width: 60%; height: 18px"></ion-skeleton-text>
    }
  </div>
</ion-content>

<!-- Tarjeta flotante inferior: precio + botón -->
@if (producto(); as p) {
  <ion-footer class="ion-no-border">
    <div class="compra aparecer">   <!-- entra subiendo, como en Android -->
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
        <ion-button (click)="confirmar()" [disabled]="enviando()" [class.latido]="latiendo()">
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
h1 { margin: 0 0 12px; font-size: 32px; line-height: 1.05; font-weight: 700; letter-spacing: -0.05em; }
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

  // Latido del botón al añadir (crece al 108 % y vuelve, 300 ms)
  latiendo = signal(false);
  private latir(): void {
    this.latiendo.set(false);
    setTimeout(() => { this.latiendo.set(true); setTimeout(() => this.latiendo.set(false), 300); });
  }

  private async anadirCesta(p: Producto): Promise<void> {
    if (!this.cesta.anadir(p)) {                       // ya tienes en la cesta todas las que quedan
      const t = await this.toast.create({ message: 'No quedan más unidades', duration: 2000, color: 'dark' });
      await t.present();
      return;
    }
    this.latir();                                      // el botón late, como en Android
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

mkdir -p $(dirname src/app/pages/direccion/direccion.page.html)
cat > src/app/pages/direccion/direccion.page.html <<'JUEGALMI_EOF'
<ion-header class="ion-no-border">
  <ion-toolbar>
    <ion-buttons slot="start"><ion-back-button defaultHref="/cuenta/direcciones" text=""></ion-back-button></ion-buttons>
  </ion-toolbar>
</ion-header>

<ion-content class="ion-padding">
  <h1 class="titulo">{{ titulo() }}</h1>

  <form [formGroup]="form" (ngSubmit)="guardar()" novalidate>
    <div class="campo">
      <label>Calle</label>
      <ion-input formControlName="calle" placeholder="Ej. Gran Vía" autocomplete="address-line1" aria-label="Calle" [class.mal]="invalido('calle')"></ion-input>
      @if (invalido('calle')) { <p class="error">Este campo es obligatorio</p> }
    </div>

    <div class="fila2">
      <div class="campo">
        <label>Número</label>
        <ion-input formControlName="numero" placeholder="12" aria-label="Número" [class.mal]="invalido('numero')"></ion-input>
        @if (invalido('numero')) { <p class="error">Este campo es obligatorio</p> }
      </div>
      <div class="campo">
        <label>Piso <small>(opcional)</small></label>
        <ion-input formControlName="piso" placeholder="3ºB" aria-label="Piso"></ion-input>
      </div>
    </div>

    <div class="fila2">
      <div class="campo">
        <label>Código postal</label>
        <ion-input formControlName="codigo_postal" placeholder="48001" inputmode="numeric" maxlength="5" aria-label="Código postal" [class.mal]="invalido('codigo_postal')"></ion-input>
        @if (invalido('codigo_postal')) { <p class="error">{{ errorCp() }}</p> }
      </div>
      <div class="campo">
        <label>Ciudad</label>
        <ion-input formControlName="ciudad" placeholder="Bilbao" aria-label="Ciudad" [class.mal]="invalido('ciudad')"></ion-input>
        @if (invalido('ciudad')) { <p class="error">Este campo es obligatorio</p> }
      </div>
    </div>

    <div class="campo">
      <label>Provincia</label>
      <ion-input formControlName="provincia" placeholder="Bizkaia" aria-label="Provincia" [class.mal]="invalido('provincia')"></ion-input>
      @if (invalido('provincia')) { <p class="error">Este campo es obligatorio</p> }
    </div>
  </form>
</ion-content>

<ion-footer class="ion-no-border">
  <div class="pie-boton">
    <ion-button expand="block" (click)="guardar()" [disabled]="guardando()">
      @if (guardando()) { <ion-spinner name="crescent"></ion-spinner> } @else { Guardar dirección }
    </ion-button>
  </div>
</ion-footer>
JUEGALMI_EOF

mkdir -p $(dirname src/app/pages/direccion/direccion.page.ts)
cat > src/app/pages/direccion/direccion.page.ts <<'JUEGALMI_EOF'
import { Component, computed, inject, signal } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { IonHeader, IonToolbar, IonButtons, IonBackButton, IonContent, IonFooter, IonInput, IonButton,
         IonSpinner, NavController, ToastController } from '@ionic/angular';
import { SesionService } from '../../services/sesion.service';
import { DomicilioService } from '../../services/domicilio.service';
import { DatosDireccion } from '../../models/domicilio.model';
import { textoError } from '../../validators/validadores';

type Campo = 'calle' | 'numero' | 'codigo_postal' | 'ciudad' | 'provincia';

@Component({
  selector: 'app-direccion',
  templateUrl: './direccion.page.html',
  styleUrls: ['../subpagina.scss'],
  imports: [ReactiveFormsModule, IonHeader, IonToolbar, IonButtons, IonBackButton, IonContent, IonFooter,
            IonInput, IonButton, IonSpinner],
})
export class DireccionPage {
  private sesion = inject(SesionService);
  private domicilios = inject(DomicilioService);
  private nav = inject(NavController);
  private toast = inject(ToastController);

  // Ruta /cuenta/direcciones/nueva → null · /cuenta/direcciones/3 → editar el domicilio 3
  id: number | null;
  guardando = signal(false);
  titulo = computed(() => this.id === null ? 'Nueva dirección' : 'Editar dirección');

  form = inject(FormBuilder).nonNullable.group({
    calle: ['', [Validators.required, Validators.minLength(3)]],
    numero: ['', Validators.required],
    piso: [''],
    codigo_postal: ['', [Validators.required, Validators.pattern(/^\d{5}$/)]],   // 5 cifras
    ciudad: ['', Validators.required],
    provincia: ['', Validators.required],
  });

  constructor() {
    const param = inject(ActivatedRoute).snapshot.paramMap.get('id');
    this.id = param === null || param === 'nueva' ? null : Number(param);
  }

  // Si se edita, rellena el formulario con el domicilio elegido
  ionViewWillEnter(): void {
    if (this.id === null) return;
    const d = this.domicilios.lista().find(x => x.id === this.id)?.direccion;
    if (d) this.form.reset({ ...d, piso: d.piso ?? '' });
  }

  // Código postal: vacío → genérico; mal escrito → el concreto (igual que Android)
  errorCp(): string {
    return textoError(this.form.controls.codigo_postal, 'El código postal tiene 5 números');
  }

  invalido(c: Campo): boolean {
    const control = this.form.controls[c];
    return control.invalid && control.touched;
  }

  // Nueva → POST /api/domicilios · Editar → PUT /api/domicilios/{id}
  guardar(): void {
    if (this.form.invalid) { this.form.markAllAsTouched(); return; }
    const v = this.form.getRawValue();
    const datos: DatosDireccion = {
      calle: v.calle.trim(), numero: v.numero.trim(), piso: v.piso.trim() || null,
      codigo_postal: v.codigo_postal, ciudad: v.ciudad.trim(), provincia: v.provincia.trim(),
    };
    if (this.id !== null && !Object.keys(this.cambios(datos)).length) { this.nav.back(); return; }   // nada que guardar
    const llamada = this.id === null ? this.domicilios.crear(datos) : this.domicilios.editar(this.id, this.cambios(datos));

    this.guardando.set(true);
    llamada.subscribe({
      next: d => {
        this.guardando.set(false);
        if (this.id === null) this.domicilios.elegir(d.id);   // la nueva pasa a ser la de envío
        this.aviso('Dirección guardada.', 'dark');
        this.nav.back();
      },
      error: e => { this.guardando.set(false); this.aviso(this.sesion.mensaje(e), 'danger'); },
    });
  }

  // Solo los campos que han cambiado, p. ej. { piso: '4ºC' }
  private cambios(datos: DatosDireccion): Partial<DatosDireccion> {
    const antes = this.domicilios.lista().find(x => x.id === this.id)?.direccion;
    if (!antes) return datos;
    const c: Record<string, string | null> = {};
    for (const k of Object.keys(datos) as (keyof DatosDireccion)[]) {
      if ((datos[k] ?? null) !== (antes[k] ?? null)) c[k] = datos[k] ?? null;
    }
    return c as Partial<DatosDireccion>;
  }

  private async aviso(m: string, color: string): Promise<void> {
    const t = await this.toast.create({ message: m, duration: 2000, color });
    await t.present();
  }
}
JUEGALMI_EOF

mkdir -p $(dirname src/app/pages/direcciones/direcciones.page.html)
cat > src/app/pages/direcciones/direcciones.page.html <<'JUEGALMI_EOF'
<ion-header class="ion-no-border">
  <ion-toolbar>
    <ion-buttons slot="start"><ion-back-button defaultHref="/inicio" text=""></ion-back-button></ion-buttons>
  </ion-toolbar>
</ion-header>

<ion-content class="ion-padding">
  <h1 class="titulo">Direcciones</h1>
  <p class="subtitulo">Toca una para enviar ahí tus pedidos.</p>

  @if (cargando()) {
    <ion-skeleton-text [animated]="true" style="height: 90px; border-radius: 24px"></ion-skeleton-text>
  } @else {
    <!-- ion-list = RecyclerView · ion-card = CardView -->
    <ion-list class="lista cascada">
      @for (d of domicilios.lista(); track d.id) {
        <ion-card class="tarjeta pulsable" [class.elegida]="esElegido(d)" (click)="elegir(d)">
        <div class="direccion">
          <span class="icono"><ion-icon [name]="esElegido(d) ? 'checkmark-circle' : 'location-outline'"></ion-icon></span>
          <div class="textos">
            <strong>{{ d.direccion.calle }} {{ d.direccion.numero }}@if (d.direccion.piso) {, {{ d.direccion.piso }}}</strong>
            <small>{{ d.direccion.codigo_postal }} {{ d.direccion.ciudad }} · {{ d.direccion.provincia }}</small>
          </div>
          <button type="button" (click)="editar(d, $event)" aria-label="Editar dirección"><ion-icon name="pencil-outline"></ion-icon></button>
          <button type="button" (click)="borrar(d, $event)" aria-label="Borrar dirección"><ion-icon name="trash-outline"></ion-icon></button>
        </div>
        </ion-card>
      } @empty {
        <app-estado icono="location-outline" titulo="Aún no tienes direcciones" texto="Añade una para que podamos enviarte los pedidos."></app-estado>
      }
    </ion-list>
  }
</ion-content>

<ion-footer class="ion-no-border">
  <div class="pie-boton">
    <ion-button expand="block" routerLink="/cuenta/direcciones/nueva">
      <ion-icon slot="start" name="add"></ion-icon>
      Añadir dirección
    </ion-button>
  </div>
</ion-footer>
JUEGALMI_EOF

mkdir -p $(dirname src/app/pages/direcciones/direcciones.page.scss)
cat > src/app/pages/direcciones/direcciones.page.scss <<'JUEGALMI_EOF'
.direccion {
  display: flex; align-items: center; gap: 14px; padding: 16px 14px 16px 16px;
  .icono {
    width: 48px; height: 48px; border-radius: 50%; flex-shrink: 0;
    display: flex; align-items: center; justify-content: center;
    background: var(--jg-acento-suave); color: #2f6f70; font-size: 20px;
  }
  .textos { flex-grow: 1; display: flex; flex-direction: column; gap: 4px; min-width: 0; }
  strong { font-size: 17px; font-weight: 600; }
  small { color: var(--jg-texto-sec); font-size: 15px; }
  button {
    width: 40px; height: 40px; border: 0; border-radius: 50%; flex-shrink: 0;
    background: none; color: var(--jg-texto-sec); font-size: 21px;
    display: flex; align-items: center; justify-content: center;
  }
  button:active { background: var(--jg-gris); }
}

ion-card { margin-bottom: 14px; cursor: pointer; border: 2px solid transparent; }
ion-card.elegida { border-color: var(--ion-color-primary); }
ion-card.elegida .icono ion-icon { color: var(--ion-color-primary); }
JUEGALMI_EOF

mkdir -p $(dirname src/app/pages/direcciones/direcciones.page.ts)
cat > src/app/pages/direcciones/direcciones.page.ts <<'JUEGALMI_EOF'
import { Component, inject, signal } from '@angular/core';
import { Router, RouterLink } from '@angular/router';
import { IonHeader, IonToolbar, IonButtons, IonBackButton, IonContent, IonFooter, IonButton, IonIcon,
         IonSkeletonText, AlertController, ToastController, IonList, IonCard } from '@ionic/angular';
import { addIcons } from 'ionicons';
import { locationOutline, pencilOutline, trashOutline, add, checkmarkCircle } from 'ionicons/icons';
import { SesionService } from '../../services/sesion.service';
import { DomicilioService } from '../../services/domicilio.service';
import { Domicilio } from '../../models/domicilio.model';
import { EstadoComponent } from '../../components/estado/estado.component';

@Component({
  selector: 'app-direcciones',
  templateUrl: './direcciones.page.html',
  styleUrls: ['../subpagina.scss', './direcciones.page.scss'],
  imports: [EstadoComponent, IonList, IonCard, RouterLink, IonHeader, IonToolbar, IonButtons, IonBackButton, IonContent, IonFooter, IonButton, IonIcon, IonSkeletonText],
})
export class DireccionesPage {
  domicilios = inject(DomicilioService);
  private sesion = inject(SesionService);
  private router = inject(Router);
  private alerta = inject(AlertController);
  private toast = inject(ToastController);

  cargando = signal(true);

  constructor() {
    addIcons({ locationOutline, pencilOutline, trashOutline, add, checkmarkCircle });
  }

  // GET /api/domicilios (activos, el más reciente primero)
  ionViewWillEnter(): void {
    this.domicilios.cargar().subscribe({
      next: () => this.cargando.set(false),
      error: e => { this.cargando.set(false); this.aviso(this.sesion.mensaje(e), 'danger'); },
    });
  }

  esElegido(d: Domicilio): boolean {
    return this.domicilios.elegido()?.id === d.id;
  }

  // Tocar la tarjeta = usarla para enviar los pedidos
  elegir(d: Domicilio): void {
    this.domicilios.elegir(d.id);
    this.aviso('Enviaremos tus pedidos a esta dirección.', 'dark');
  }

  editar(d: Domicilio, e: Event): void {
    e.stopPropagation();
    this.router.navigate(['/cuenta/direcciones', d.id]);
  }

  // DELETE /api/domicilios/{id}: baja lógica (los pedidos antiguos la conservan)
  async borrar(d: Domicilio, e: Event): Promise<void> {
    e.stopPropagation();
    const alerta = await this.alerta.create({
      header: 'Borrar dirección',
      message: `¿Seguro que quieres borrar ${d.texto}?`,
      buttons: [
        { text: 'Cancelar', role: 'cancel' },
        { text: 'Borrar', role: 'destructive', handler: () => {
          this.domicilios.borrar(d.id).subscribe({
            next: () => { this.aviso('Dirección borrada.', 'dark'); this.domicilios.cargar().subscribe(); },
            error: err => this.aviso(this.sesion.mensaje(err), 'danger'),
          });
        } },
      ],
    });
    await alerta.present();
  }

  private async aviso(m: string, color: string): Promise<void> {
    const t = await this.toast.create({ message: m, duration: 2000, color });
    await t.present();
  }
}
JUEGALMI_EOF

mkdir -p $(dirname src/app/pages/editar-datos/editar-datos.page.html)
cat > src/app/pages/editar-datos/editar-datos.page.html <<'JUEGALMI_EOF'
<ion-header class="ion-no-border">
  <ion-toolbar>
    <ion-buttons slot="start"><ion-back-button defaultHref="/cuenta/datos-personales" text=""></ion-back-button></ion-buttons>
  </ion-toolbar>
</ion-header>

<ion-content class="ion-padding">
  <h1 class="titulo">Editar datos</h1>

  <!-- Avatar con botón de cámara -->
  <div class="foto">
    <button type="button" class="avatar" (click)="cambiarFoto()" aria-label="Cambiar foto">
      @if (foto(); as f) { <img [src]="f" alt="Foto de perfil"> } @else { {{ sesion.iniciales() }} }
      <span class="camara"><ion-icon name="camera-outline"></ion-icon></span>
    </button>
    <span>Cambiar foto</span>
  </div>

  @if (sesion.usuario(); as u) {
    <form [formGroup]="form" (ngSubmit)="guardar()" novalidate>
      <div class="campo">
        <label>Nombre</label>
        <ion-input formControlName="nombre" autocomplete="given-name" aria-label="Nombre" [class.mal]="invalido('nombre')"></ion-input>
        @if (invalido('nombre')) { <p class="error">Este campo es obligatorio</p> }
      </div>

      <div class="fila2">
        <div class="campo">
          <label>Primer apellido</label>
          <ion-input formControlName="apellido1" aria-label="Primer apellido" [class.mal]="invalido('apellido1')"></ion-input>
          @if (invalido('apellido1')) { <p class="error">Este campo es obligatorio</p> }
        </div>
        <div class="campo">
          <label>Segundo <small>(opcional)</small></label>
          <ion-input formControlName="apellido2" aria-label="Segundo apellido"></ion-input>
        </div>
      </div>

      <div class="campo">
        <label>Teléfono <small>(opcional)</small></label>
        <ion-input formControlName="telefono" type="tel" inputmode="tel" aria-label="Teléfono" [class.mal]="invalido('telefono')"></ion-input>
        @if (invalido('telefono')) { <p class="error">El teléfono debe tener 9 números y empezar por 6, 7, 8 o 9.</p> }
      </div>

      <!-- DNI y email no se pueden cambiar -->
      <div class="campo">
        <label>DNI</label>
        <div class="fijo">{{ u.dni }} <ion-icon name="lock-closed-outline"></ion-icon></div>
      </div>
      <div class="campo">
        <label>Email</label>
        <div class="fijo">{{ u.email }} <ion-icon name="lock-closed-outline"></ion-icon></div>
      </div>
      <p class="nota">El DNI y el email no se pueden cambiar.</p>

      <!-- Contraseña: solo si se quiere cambiar (PUT /api/yo con password_actual y password_nueva) -->
      <h2>Contraseña</h2>
      <div class="campo">
        <label>Contraseña actual</label>
        <ion-input formControlName="password_actual" type="password" autocomplete="current-password"
                   aria-label="Contraseña actual" [class.mal]="invalido('password_actual')"></ion-input>
        @if (invalido('password_actual')) { <p class="error">Escribe tu contraseña actual</p> }
      </div>
      <div class="campo">
        <label>Nueva contraseña</label>
        <ion-input formControlName="password_nueva" type="password" autocomplete="new-password" placeholder="Mínimo 6 caracteres"
                   aria-label="Nueva contraseña" [class.mal]="invalido('password_nueva')"></ion-input>
        @if (invalido('password_nueva')) { <p class="error">Mínimo 6 caracteres</p> }
      </div>
    </form>
  }
</ion-content>

<ion-footer class="ion-no-border">
  <div class="pie-boton">
    <ion-button expand="block" (click)="guardar()" [disabled]="guardando()">
      @if (guardando()) { <ion-spinner name="crescent"></ion-spinner> } @else { Guardar cambios }
    </ion-button>
  </div>
</ion-footer>
JUEGALMI_EOF

mkdir -p $(dirname src/app/pages/editar-datos/editar-datos.page.ts)
cat > src/app/pages/editar-datos/editar-datos.page.ts <<'JUEGALMI_EOF'
import { Component, inject, signal } from '@angular/core';
import { AbstractControl, FormBuilder, ReactiveFormsModule, ValidationErrors, Validators } from '@angular/forms';
import { IonHeader, IonToolbar, IonButtons, IonBackButton, IonContent, IonFooter, IonInput, IonButton,
         IonIcon, IonSpinner, NavController, ToastController } from '@ionic/angular';
import { addIcons } from 'ionicons';
import { cameraOutline, lockClosedOutline } from 'ionicons/icons';
import { SesionService } from '../../services/sesion.service';
import { of, switchMap } from 'rxjs';
import { FotoService } from '../../services/foto.service';
import { telefonoValido } from '../../validators/validadores';

type Campo = 'nombre' | 'apellido1' | 'telefono' | 'password_actual' | 'password_nueva';

// Contraseña: o las dos vacías (no se cambia) o las dos rellenas
function parejaContrasena(g: AbstractControl): ValidationErrors | null {
  const actual = g.get('password_actual'), nueva = g.get('password_nueva');
  const unaSola = !!actual?.value !== !!nueva?.value;
  actual?.setErrors(unaSola && !actual.value ? { required: true } : null);
  if (unaSola && !nueva?.value) nueva?.setErrors({ required: true });
  else if (nueva?.value && nueva.value.length < 6) nueva.setErrors({ minlength: true });
  else nueva?.setErrors(null);
  return null;
}

@Component({
  selector: 'app-editar-datos',
  templateUrl: './editar-datos.page.html',
  styleUrls: ['../subpagina.scss', '../datos-personales/datos-personales.page.scss', './editar-datos.page.scss'],
  imports: [ReactiveFormsModule, IonHeader, IonToolbar, IonButtons, IonBackButton, IonContent, IonFooter,
            IonInput, IonButton, IonIcon, IonSpinner],
})
export class EditarDatosPage {
  sesion = inject(SesionService);
  private fotos = inject(FotoService);
  private nav = inject(NavController);
  private toast = inject(ToastController);

  guardando = signal(false);
  foto = signal<string | null>(null);          // foto nueva (o la que ya tenía)

  form = inject(FormBuilder).nonNullable.group({
    nombre: ['', [Validators.required, Validators.minLength(2)]],
    apellido1: ['', [Validators.required, Validators.minLength(2)]],
    apellido2: [''],
    telefono: ['', telefonoValido],             // opcional, pero si se pone tiene que ser válido
    password_actual: [''],
    password_nueva: [''],
  }, { validators: parejaContrasena });

  constructor() {
    addIcons({ cameraOutline, lockClosedOutline });
  }

  // Rellena el formulario con los datos actuales
  ionViewWillEnter(): void {
    const u = this.sesion.usuario();
    if (!u) return;
    this.form.reset({ nombre: u.nombre, apellido1: u.apellido1, apellido2: u.apellido2 ?? '', telefono: u.telefono ?? '',
                     password_actual: '', password_nueva: '' });
    this.foto.set(u.foto_perfil_url ?? null);
  }

  invalido(c: Campo): boolean {
    const control = this.form.controls[c];
    return control.invalid && control.touched;
  }

  // Botón de la cámara sobre el avatar
  async cambiarFoto(): Promise<void> {
    try {
      const nueva = await this.fotos.hacerFoto();
      if (nueva) this.foto.set(nueva);
    } catch {
      this.aviso('No se ha podido usar la cámara. Revisa los permisos.', 'danger');
    }
  }

  guardar(): void {
    if (this.form.invalid) { this.form.markAllAsTouched(); return; }
    this.guardando.set(true);
    // PUT /api/yo: solo lo que cambia (vacío → null). La foto solo si es nueva
    const v = this.form.getRawValue();
    const datos: Record<string, string | null> = {
      nombre: v.nombre.trim(), apellido1: v.apellido1.trim(),
      apellido2: v.apellido2.trim() || null, telefono: v.telefono.trim() || null,
    };
    if (v.password_nueva) { datos['password_actual'] = v.password_actual; datos['password_nueva'] = v.password_nueva; }
    // Foto nueva = dataURL de la cámara → se sube aparte como archivo
    const foto = this.foto();
    const fotoNueva = foto?.startsWith('data:') ? foto : null;
    this.sesion.actualizarDatos(datos).pipe(
      switchMap(u => fotoNueva
        ? this.sesion.subirFoto(this.fotos.aBlob(fotoNueva), 'perfil.' + this.fotos.extension(fotoNueva))
        : of(u)),
    ).subscribe({
      next: () => { this.guardando.set(false); this.aviso('Datos guardados.', 'dark'); this.nav.back(); },
      error: e => { this.guardando.set(false); this.aviso(this.sesion.mensaje(e), 'danger'); },   // p. ej. contraseña actual incorrecta
    });
  }

  private async aviso(m: string, color: string): Promise<void> {
    const t = await this.toast.create({ message: m, duration: 2000, color });
    await t.present();
  }
}
JUEGALMI_EOF

mkdir -p $(dirname src/app/pages/home/home.page.html)
cat > src/app/pages/home/home.page.html <<'JUEGALMI_EOF'
<ion-header class="ion-no-border">
  <app-cabecera></app-cabecera>
</ion-header>

<ion-content class="ion-padding">
  <ion-refresher slot="fixed" (ionRefresh)="refrescar($event)">
    <ion-refresher-content></ion-refresher-content>
  </ion-refresher>

  <h1 class="titulo">Hola, {{ sesion.usuario()?.nombre }}</h1>

  <div class="cascada">
    <!-- Tarjeta turquesa del taller -->
    <section class="taller">
      <ion-icon class="fondo" name="build-outline" aria-hidden="true"></ion-icon>
      <div class="cats">
        @for (c of categorias; track c) { <span>{{ c }}</span> }
      </div>
      <h2>Lo reparamos.</h2>
      <a class="boton-oscuro pulsable" routerLink="/taller">Pedir reparación <ion-icon name="arrow-forward"></ion-icon></a>
    </section>

    <!-- Comprar / Alquilar -->
    <div class="accesos">
      <a class="acceso comprar pulsable" routerLink="/tienda">
        <ion-icon name="storefront-outline"></ion-icon><strong>Comprar</strong>
      </a>
      <a class="acceso alquilar pulsable" routerLink="/tienda" [queryParams]="{ modo: 'alquilar' }">
        <ion-icon name="time-outline"></ion-icon><strong>Alquilar</strong>
      </a>
    </div>

    @if (cargando()) {
      <ion-skeleton-text [animated]="true" class="esqueleto"></ion-skeleton-text>
      <ion-skeleton-text [animated]="true" class="esqueleto"></ion-skeleton-text>
    } @else {
      <!-- Reparación en curso con círculo de progreso (paso / total_pasos de la API) -->
      @if (reparacion(); as r) {
        <a class="tarjeta fila pulsable" [routerLink]="['/taller/reparacion', r.id]">
          <span class="progreso">
            <svg viewBox="0 0 60 60" aria-hidden="true">
              <circle cx="30" cy="30" r="26" class="pista"></circle>
              <circle cx="30" cy="30" r="26" class="valor" [attr.stroke-dasharray]="vuelta" [attr.stroke-dashoffset]="hueco(r)"></circle>
            </svg>
            <b>{{ r.paso }}/{{ r.total_pasos }}</b>
          </span>
          <span class="texto"><strong>{{ dispositivo[r.tipo_dispositivo] }} · {{ r.marca }} {{ r.modelo }}</strong><small>{{ r.estado_texto }}</small></span>
          <ion-icon name="chevron-forward"></ion-icon>
        </a>
      }

      <!-- Alquiler activo con los días que quedan -->
      @if (alquiler(); as a) {
        <a class="tarjeta fila pulsable" routerLink="/cuenta/alquileres">
          <app-miniatura-producto [producto]="a.lineas[0].videojuego" class="portada"></app-miniatura-producto>
          <span class="texto"><strong>{{ a.lineas[0].videojuego | nombreProducto }}</strong></span>
          <span class="dias"><b>{{ a.dias_restantes > 0 ? a.dias_restantes : 0 }}</b> {{ a.dias_restantes === 1 ? 'día' : 'días' }}</span>
        </a>
      }
    }
  </div>

  <!-- Novedades (scroll horizontal) -->
  <div class="seccion">
    <h2>Novedades</h2>
    <a routerLink="/tienda">Ver todo</a>
  </div>
  <div class="novedades">
    @for (p of novedades(); track p.id) {
      <ion-card class="novedad pulsable" [class.agotado]="aviso(p)?.agotado" [routerLink]="['/producto', p.id]">
        <app-miniatura-producto [producto]="p"></app-miniatura-producto>
        @if (aviso(p); as e) { <span class="stock" [class.aviso]="!e.agotado">{{ e.texto }}</span> }
        <strong>{{ p.nombre }}</strong>
        <app-precio [valor]="p.precio_venta"></app-precio>
      </ion-card>
    }
  </div>
</ion-content>
JUEGALMI_EOF

mkdir -p $(dirname src/app/pages/home/home.page.scss)
cat > src/app/pages/home/home.page.scss <<'JUEGALMI_EOF'
// Tarjeta turquesa "Lo reparamos."
.taller {
  position: relative; overflow: hidden;
  padding: 26px 26px 28px; border-radius: 28px;   // como Android
  background: linear-gradient(135deg, #8ad6d8 0%, #6fc4c7 100%);
  color: #1f2329;

  .fondo { position: absolute; right: -24px; top: 10px; font-size: 190px; opacity: .14; transform: rotate(-12deg); }
  .cats { position: relative; display: flex; gap: 6px; }
  .cats span {
    padding: 6px 11px; border-radius: 999px;
    background: rgba(255, 255, 255, .55); font-size: 12px; font-weight: 600;
  }
  h2 { position: relative; margin: 64px 0 18px; font-size: 44px; font-weight: 700; letter-spacing: -0.055em; }
}
.boton-oscuro {
  position: relative; display: inline-flex; align-items: center; gap: 10px;
  height: 50px; padding: 0 22px; border-radius: 999px;
  background: #1f2329; color: var(--jg-acento);
  font-size: 16px; font-weight: 600; text-decoration: none;
}

// Comprar (oscura) / Alquilar (gris)
.accesos { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; margin: 14px 0; }
.acceso {
  display: flex; flex-direction: column; justify-content: space-between;
  height: 156px; padding: 22px; border-radius: 26px; text-decoration: none;
  ion-icon { font-size: 26px; }
  strong { font-size: 25px; font-weight: 700; letter-spacing: -0.04em; }
  &.comprar { background: var(--jg-inverso); color: var(--jg-inverso-texto); }
  &.alquilar { background: var(--jg-gris); color: var(--ion-text-color); }
}

// Filas: reparación y alquiler
.fila {
  display: flex; align-items: center; gap: 16px;
  padding: 16px 20px; margin-bottom: 14px;
  color: var(--ion-text-color); text-decoration: none;

  .texto { flex-grow: 1; display: flex; flex-direction: column; gap: 4px; min-width: 0; }
  strong { font-size: 17px; font-weight: 600; }
  small { color: var(--jg-texto-sec); font-size: 15px; }
  > ion-icon { color: var(--jg-texto-sec); }
}

// Círculo de progreso 3/5
.progreso {
  position: relative; width: 62px; height: 62px; flex-shrink: 0;
  svg { width: 100%; height: 100%; transform: rotate(-90deg); }
  circle { fill: none; stroke-width: 5; }
  .pista { stroke: var(--jg-acento-suave); }
  .valor { stroke: #4fb2b6; stroke-linecap: round; transition: stroke-dashoffset .6s ease; }
  b { position: absolute; inset: 0; display: flex; align-items: center; justify-content: center; font-size: 16px; }
}

.portada { --tam: 64px; --radio: 12px; }
.dias { color: var(--jg-texto-sec); font-size: 15px; white-space: nowrap; b { color: var(--ion-text-color); font-size: 34px; font-weight: 700; } }

.esqueleto { height: 92px; border-radius: 24px; margin-bottom: 14px; }

// Novedades en carrusel
.novedades {
  display: flex; gap: 14px;
  overflow-x: auto; scrollbar-width: none;
  margin: 0 -20px; padding: 0 20px 8px;
  &::-webkit-scrollbar { display: none; }
}
.novedad {
  --background: transparent; margin: 0; box-shadow: none; border-radius: 0; overflow: visible;
  position: relative; flex: 0 0 168px;
  display: flex; flex-direction: column; gap: 8px;
  color: var(--ion-text-color); text-decoration: none;

  app-miniatura-producto { --tam: 168px; --radio: 22px; --fondo: var(--jg-tarjeta); --icono: 48px; }
  .stock {
    position: absolute; top: 10px; left: 10px; z-index: 1; padding: 4px 10px; border-radius: 999px;
    background: #ffffff; color: #1f2329; font-size: 11px; font-weight: 600; box-shadow: 0 2px 8px rgba(0, 0, 0, .12);
    &.aviso { background: #a72144; color: #ffffff; }
  }
  strong { font-size: 15px; font-weight: 500; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
  app-precio { font-size: 22px; }
}

.novedad.agotado { app-miniatura-producto, strong, app-precio { opacity: .55; filter: grayscale(1); } }
JUEGALMI_EOF

mkdir -p $(dirname src/app/pages/home/home.page.ts)
cat > src/app/pages/home/home.page.ts <<'JUEGALMI_EOF'
import { NombreProductoPipe } from '../../pipes/nombre-producto.pipe';
import { Component, inject, signal } from '@angular/core';
import { RouterLink } from '@angular/router';
import { forkJoin } from 'rxjs';
import { IonHeader, IonContent, IonIcon, IonSkeletonText,
         IonRefresher, IonRefresherContent, RefresherCustomEvent, IonCard } from '@ionic/angular';
import { addIcons } from 'ionicons';
import { storefrontOutline, timeOutline, chevronForward, arrowForward, buildOutline } from 'ionicons/icons';
import { CabeceraComponent } from '../../components/cabecera/cabecera.component';
import { MiniaturaProductoComponent } from '../../components/miniatura-producto/miniatura-producto.component';
import { PrecioComponent } from '../../components/precio/precio.component';
import { SesionService } from '../../services/sesion.service';
import { AlquilerService } from '../../services/alquiler.service';
import { ReparacionService } from '../../services/reparacion.service';
import { ProductoService } from '../../services/producto.service';
import { NOMBRE_DISPOSITIVO, Reparacion } from '../../models/reparacion.model';
import { Alquiler } from '../../models/alquiler.model';
import { Producto } from '../../models/producto.model';
import { avisoStock } from '../../models/producto.model';

const VUELTA = 2 * Math.PI * 26;   // perímetro del círculo de progreso (radio 26)

@Component({
  selector: 'app-home',
  templateUrl: './home.page.html',
  styleUrls: ['./home.page.scss'],
  imports: [IonCard, RouterLink, IonHeader, IonContent, IonIcon, IonSkeletonText, IonRefresher, IonRefresherContent,
            CabeceraComponent, MiniaturaProductoComponent, PrecioComponent, NombreProductoPipe],
})
export class HomePage {
  // Etiqueta de stock de las novedades (la misma regla que la Tienda y Android)
  aviso = (p: Producto) => avisoStock(p, false);

  sesion = inject(SesionService);
  private alquileres = inject(AlquilerService);
  private reparaciones = inject(ReparacionService);
  private productos = inject(ProductoService);

  cargando = signal(true);
  reparacion = signal<Reparacion | null>(null);   // la reparación en curso más reciente
  alquiler = signal<Alquiler | null>(null);       // el alquiler activo
  novedades = signal<Producto[]>([]);

  categorias = ['Consolas', 'Móviles', 'Mandos', 'Tablets'];
  vuelta = VUELTA;
  dispositivo = NOMBRE_DISPOSITIVO;

  constructor() {
    addIcons({ storefrontOutline, timeOutline, chevronForward, arrowForward, buildOutline });
  }

  ionViewWillEnter(): void { this.cargar(); }

  refrescar(evento: RefresherCustomEvent): void {
    this.cargar(() => evento.target.complete());
  }

  private cargar(alTerminar?: () => void): void {
    // Las tres peticiones a la vez (no bloquea la interfaz)
    forkJoin({
      alquileres: this.alquileres.listar('activo', 1, 1),
      reparaciones: this.reparaciones.listar(1, 20),
      novedades: this.productos.listar({ page: 1, limit: 6 }),
    }).subscribe({
      next: ({ alquileres, reparaciones, novedades }) => {
        // La más reciente que siga en el taller (la API las da de la más nueva a la más antigua)
        this.reparacion.set(reparaciones.datos.find(r => r.estado !== 'entregada' && r.estado !== 'cancelada') ?? null);
        this.alquiler.set(alquileres.datos[0] ?? null);
        this.novedades.set(novedades.datos);
        this.cargando.set(false);
        alTerminar?.();
      },
      error: () => { this.cargando.set(false); alTerminar?.(); },
    });
  }

  // Trazo del círculo que queda sin pintar
  hueco(r: Reparacion): number {
    return VUELTA * (1 - r.paso / r.total_pasos);
  }
}
JUEGALMI_EOF

mkdir -p $(dirname src/app/pages/login/login.page.html)
cat > src/app/pages/login/login.page.html <<'JUEGALMI_EOF'
<ion-content class="ion-padding">
  <!-- Cabecera de acceso: logo + enlace a registro -->
  <header class="cabecera-acceso">
    <div class="marca"><span class="logo">J</span><span>JuegAlmi</span></div>
    <a routerLink="/registro" routerDirection="forward">Crear cuenta</a>
  </header>

  <h1>Inicia sesión</h1>
  <p class="subtitulo">Compra, alquila y repara desde un mismo sitio.</p>

  <form [formGroup]="form" (ngSubmit)="entrar()" novalidate>
    <!-- Email -->
    <div class="campo">
      <label for="email">Email</label>
      <ion-input id="email" formControlName="email" type="email" inputmode="email" autocomplete="email"
                 aria-label="Email" [class.mal]="invalido('email')"></ion-input>
      @if (invalido('email')) {
        <p class="error">{{ mensajeError('email', 'El email no es válido.') }}</p>
      }
    </div>

    <!-- Contraseña -->
    <div class="campo">
      <label for="password">Contraseña</label>
      <ion-input id="password" formControlName="password" type="password" autocomplete="current-password"
                 aria-label="Contraseña" [class.mal]="invalido('password')"></ion-input>
      @if (invalido('password')) {
        <p class="error">{{ mensajeError('password') }}</p>
      }
    </div>

    <!-- Error de la API (email o clave incorrectos, sin conexión...) -->
    @if (error()) {
      <p class="error-general" role="alert">{{ error() }}</p>
    }

    <ion-button type="submit" expand="block" [disabled]="cargando()">
      @if (cargando()) { <ion-spinner name="crescent"></ion-spinner> } @else { Entrar }
    </ion-button>
  </form>

  <p class="nota">demo&#64;juegalmi.es · 1234</p>
  <p class="pie">JuegAlmi · Bilbao</p>
</ion-content>
JUEGALMI_EOF

mkdir -p $(dirname src/app/pages/login/login.page.scss)
cat > src/app/pages/login/login.page.scss <<'JUEGALMI_EOF'
ion-content { --padding-top: calc(14px + var(--ion-safe-area-top, 0px)); --padding-bottom: 32px; }

.cabecera-acceso {
  display: flex; align-items: center; justify-content: space-between;
  min-height: 56px; margin-bottom: 28px;
  .marca { display: flex; align-items: center; gap: 10px; font-size: 24px; font-weight: 700; letter-spacing: -0.04em; }
  a { color: var(--ion-text-color); font-size: 16px; font-weight: 500; text-decoration: none; }
}

h1 { margin: 0; font-size: 46px; line-height: 1.02; font-weight: 700; letter-spacing: -0.055em; }
.subtitulo { margin: 14px 0 32px; color: var(--jg-texto-sec); font-size: 18px; line-height: 1.5; max-width: 300px; }

form { display: flex; flex-direction: column; gap: 18px; }
.campo { display: flex; flex-direction: column; gap: 10px; min-width: 0; label { font-size: 17px; font-weight: 500; } }
.fila { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 14px; }

.error-general {
  margin: 0; padding: 12px 14px; border-radius: 14px;
  background: rgba(167, 33, 68, .12); color: var(--ion-color-danger); font-size: 14px;
}

ion-button { margin-top: 12px; }

// Línea fina con el usuario de prueba en medio
.nota {
  display: flex; align-items: center; gap: 12px;
  margin: 24px 0 0; color: var(--jg-texto-sec); font-size: 13px;
  &::before, &::after { content: ''; flex: 1; height: 1px; background: var(--jg-borde); }
}
.pie { margin: 40px 0 0; text-align: center; color: var(--jg-texto-sec); font-size: 13px; }
.campo label small { color: var(--jg-texto-sec); font-weight: 400; margin-left: 4px; font-size: 14px; }
JUEGALMI_EOF

mkdir -p $(dirname src/app/pages/login/login.page.ts)
cat > src/app/pages/login/login.page.ts <<'JUEGALMI_EOF'
import { Component, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { IonContent, IonInput, IonButton, IonSpinner, MenuController } from '@ionic/angular';
import { SesionService } from '../../services/sesion.service';
import { textoError } from '../../validators/validadores';

@Component({
  selector: 'app-login',
  templateUrl: './login.page.html',
  styleUrls: ['./login.page.scss'],
  imports: [ReactiveFormsModule, RouterLink, IonContent, IonInput, IonButton, IonSpinner],
})
export class LoginPage {
  private sesion = inject(SesionService);
  private router = inject(Router);
  private menu = inject(MenuController);

  cargando = signal(false);   // muestra el spinner en el botón
  error = signal('');         // mensaje de error general

  // Formulario con validaciones
  form = inject(FormBuilder).nonNullable.group({
    email: ['', [Validators.required, Validators.email]],
    password: ['', Validators.required],
  });

  // Sin menú lateral en la pantalla de acceso
  ionViewWillEnter(): void { this.menu.enable(false); }
  ionViewWillLeave(): void { this.menu.enable(true); }

  // true si el campo está mal y el usuario ya lo ha tocado
  invalido(campo: 'email' | 'password'): boolean {
    const c = this.form.controls[campo];
    return c.invalid && c.touched;
  }

  // «Este campo es obligatorio» si está vacío; el mensaje del formato si está mal escrito
  mensajeError(campo: 'email' | 'password', formato?: string): string {
    return textoError(this.form.controls[campo], formato);
  }

  entrar(): void {
    if (this.form.invalid) {                 // marca todos para que se vean los errores
      this.form.markAllAsTouched();
      return;
    }
    this.cargando.set(true);
    this.error.set('');
    const { email, password } = this.form.getRawValue();

    this.sesion.login(email.trim().toLowerCase(), password).subscribe({
      next: usuario => {
        this.cargando.set(false);
        this.form.reset();
        this.router.navigateByUrl('/inicio', { replaceUrl: true });
      },
      error: (e: Error) => {
        this.cargando.set(false);
        this.error.set(e.message);
      },
    });
  }
}
JUEGALMI_EOF

mkdir -p $(dirname src/app/pages/nosotros/nosotros.page.html)
cat > src/app/pages/nosotros/nosotros.page.html <<'JUEGALMI_EOF'
<ion-header class="ion-no-border">
  <app-cabecera></app-cabecera>
</ion-header>

<ion-content class="ion-padding">
  <h1 class="titulo">Sobre nosotros</h1>

  <ion-segment [value]="vista()" (ionChange)="cambiarVista($event.detail.value)">
    <ion-segment-button value="ubicacion"><ion-label>Ubicación</ion-label></ion-segment-button>
    <ion-segment-button value="historia"><ion-label>Historia</ion-label></ion-segment-button>
    <ion-segment-button value="galeria"><ion-label>Galería</ion-label></ion-segment-button>
  </ion-segment>

  <!-- ============ UBICACIÓN ============ -->
  <div [hidden]="vista() !== 'ubicacion'">
    <div #mapa class="mapa" role="img" aria-label="Mapa con la ubicación de la tienda"></div>

    @if (tienda(); as t) {
      <div class="tarjeta direccion">
        <strong>{{ t.direccion_linea1 }}</strong>
        <span>{{ t.direccion_linea2 }}</span>
      </div>

      <div class="dos">
        <div class="tarjeta horario">
          <ion-icon name="time-outline"></ion-icon>
          @for (h of horario; track h.dias) { <div><b>{{ h.horas }}</b><span>{{ h.dias }}</span></div> }
        </div>
        <a class="telefono pulsable" [href]="telefonoEnlace(t)">
          <ion-icon name="call-outline"></ion-icon>
          <b>{{ t.telefono }}</b>
        </a>
      </div>

      <ion-button expand="block" (click)="comoLlegar()">
        <ion-icon slot="start" name="navigate-outline"></ion-icon>
        Cómo llegar
      </ion-button>
    }
  </div>

  <!-- ============ HISTORIA ============ -->
  @if (vista() === 'historia') {
    <p class="historia">{{ historia }}</p>
    <ol class="hitos cascada">
      @for (h of hitos; track h.anio) {
        <li>
          <span class="punto"></span>
          <div class="tarjeta">
            <span class="icono"><ion-icon [name]="h.icono"></ion-icon></span>
            <b>{{ h.anio }}</b>
            <strong>{{ h.titulo }}</strong>
            <p>{{ h.texto }}</p>
          </div>
        </li>
      }
    </ol>
  }

  <!-- ============ GALERÍA (imagen provisional si no hay foto) ============ -->
  @if (vista() === 'galeria') {
    <!-- Cada foto es un ion-card con ion-img (carga diferida) -->
    <div class="galeria cascada">
      @for (f of fotos(); track f.id; let i = $index) {
        <ion-card class="foto" [class.grande]="i % 3 === 0">
          <ion-icon name="image-outline"></ion-icon>
          @if (f.url) { <ion-img [src]="f.url" [alt]="f.titulo" (ionError)="f.url = null"></ion-img> }
          <span class="pie-foto">{{ f.titulo }}</span>
        </ion-card>
      } @empty {
        <p class="vacio">Todavía no hay fotos de la tienda.</p>
      }
    </div>
  }

  @if (!tienda() && vista() === 'ubicacion') {
    <ion-skeleton-text [animated]="true" style="height: 256px; border-radius: 28px"></ion-skeleton-text>
  }
</ion-content>
JUEGALMI_EOF

mkdir -p $(dirname src/app/pages/nosotros/nosotros.page.scss)
cat > src/app/pages/nosotros/nosotros.page.scss <<'JUEGALMI_EOF'
// Mapa redondeado
.mapa { height: 256px; border-radius: 28px; overflow: hidden; z-index: 0; background: var(--jg-gris); }
:host ::ng-deep .pin-tienda { background: none; border: 0; }
:host ::ng-deep .pin {
  width: 72px; height: 72px; border-radius: 50%;
  display: flex; align-items: center; justify-content: center;
  background: rgba(120, 205, 208, .3);
  svg { width: 46px; height: 46px; padding: 11px; border-radius: 50%; background: var(--jg-acento); }
}
.direccion {
  display: flex; flex-direction: column; gap: 4px; padding: 22px; margin: 14px 0;
  strong { font-size: 21px; font-weight: 700; letter-spacing: -0.03em; }
  span { color: var(--jg-texto-sec); font-size: 15px; }
  small { margin-top: 6px; color: var(--jg-texto-sec); font-size: 13px; }
}

.dos { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; margin-bottom: 18px; }
.horario {
  display: flex; flex-direction: column; gap: 14px; padding: 20px;
  ion-icon { font-size: 22px; color: var(--jg-texto-sec); margin-bottom: 8px; }
  b { display: block; font-size: 17px; font-weight: 600; }
  span { font-size: 15px; color: var(--jg-texto-sec); }
}
.telefono {
  display: flex; flex-direction: column; justify-content: space-between; padding: 20px;
  border-radius: var(--jg-radio); text-decoration: none;
  background: var(--jg-inverso); color: var(--jg-inverso-texto);
  ion-icon { font-size: 22px; }
  b { font-size: 18px; font-weight: 600; }
}

// Historia
.historia { margin: 6px 0 24px; font-size: 21px; line-height: 1.4; font-weight: 700; letter-spacing: -0.02em; }
.hitos {
  list-style: none; margin: 0; padding: 0 0 0 28px; position: relative;
  &::before { content: ''; position: absolute; left: 6px; top: 12px; bottom: 0; width: 3px; border-radius: 2px; background: var(--jg-acento); opacity: .6; }
  li { position: relative; margin-bottom: 18px; }
  .punto { position: absolute; left: -28px; top: 26px; width: 15px; height: 15px; border-radius: 50%; background: #5fbfc3; }
  .tarjeta { position: relative; padding: 22px; }
  .icono {
    position: absolute; top: 20px; right: 20px; width: 46px; height: 46px; border-radius: 50%;
    display: flex; align-items: center; justify-content: center; background: var(--jg-acento-suave); font-size: 20px;
  }
  b { display: block; font-size: 48px; line-height: 1; font-weight: 700; letter-spacing: -0.05em; }
  strong { display: block; margin-top: 18px; font-size: 18px; font-weight: 600; }
  p { margin: 8px 0 0; color: var(--jg-texto-sec); font-size: 15px; line-height: 1.5; }
}

// Galería: una grande y dos pequeñas
.galeria { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; }
ion-card.foto {
  position: relative; margin: 0; box-shadow: none; height: 190px; border-radius: 26px; overflow: hidden;
  display: flex; align-items: center; justify-content: center;
  background: linear-gradient(160deg, var(--jg-acento-suave), var(--jg-tarjeta));
  &.grande { grid-column: span 2; height: 250px; }
  ion-icon { font-size: 30px; color: var(--jg-texto-sec); opacity: .6; }
  ion-img { position: absolute; inset: 0; width: 100%; height: 100%; }
  ion-img::part(image) { width: 100%; height: 100%; object-fit: cover; }
  .pie-foto {
    position: absolute; left: 14px; bottom: 14px; padding: 6px 12px; border-radius: 999px;
    background: #ffffff; color: #1f2329; font-size: 13px; font-weight: 600;
  }
}
JUEGALMI_EOF

mkdir -p $(dirname src/app/pages/nosotros/nosotros.page.ts)
cat > src/app/pages/nosotros/nosotros.page.ts <<'JUEGALMI_EOF'
import { Component, ElementRef, OnDestroy, inject, signal, viewChild } from '@angular/core';
import { IonHeader, IonContent, IonSegment, IonSegmentButton, IonLabel, IonIcon, IonButton, IonSkeletonText, IonCard, IonImg } from '@ionic/angular';
import { addIcons } from 'ionicons';
import { locationOutline, timeOutline, callOutline, navigateOutline, imageOutline,
         storefrontOutline, buildOutline, phonePortraitOutline, rocketOutline } from 'ionicons/icons';
import * as L from 'leaflet';
import { CabeceraComponent } from '../../components/cabecera/cabecera.component';
import { TiendaService } from '../../services/tienda.service';
import { FOTOS_LOCALES, FotoTienda, HISTORIA, HITOS, HORARIO, Tienda } from '../../models/tienda.model';

type Vista = 'ubicacion' | 'historia' | 'galeria';

// Chincheta morada de la tienda (SVG propio: evita las imágenes por defecto de Leaflet)
const PIN = `<span class="pin"><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#1f2329" stroke-width="2">
  <path d="M12 21s-7-6.2-7-12a7 7 0 0 1 14 0c0 5.8-7 12-7 12z"/><circle cx="12" cy="9" r="2.5"/></svg></span>`;

@Component({
  selector: 'app-nosotros',
  templateUrl: './nosotros.page.html',
  styleUrls: ['./nosotros.page.scss'],
  imports: [IonCard, IonImg, IonHeader, IonContent, IonSegment, IonSegmentButton, IonLabel, IonIcon, IonButton, IonSkeletonText, CabeceraComponent],
})
export class NosotrosPage implements OnDestroy {
  private tiendaSrv = inject(TiendaService);

  mapaEl = viewChild<ElementRef<HTMLDivElement>>('mapa');   // <div #mapa>

  vista = signal<Vista>('ubicacion');
  tienda = signal<Tienda | null>(null);

  // Horario e historia van escritos en la app (la API no los devuelve)
  horario = HORARIO;
  historia = HISTORIA;
  hitos = HITOS;
  fotos = signal<FotoTienda[]>(FOTOS_LOCALES);   // GET /api/tienda/fotos (si no hay, las locales)

  private mapa?: L.Map;

  constructor() {
    addIcons({ locationOutline, timeOutline, callOutline, navigateOutline, imageOutline,
               storefrontOutline, buildOutline, phonePortraitOutline, rocketOutline });
    this.tiendaSrv.obtener().subscribe({
      next: t => {
        this.tienda.set(t);
        setTimeout(() => this.crearMapa());     // espera a que exista el <div> del mapa
      },
      error: () => { /* sin conexión: se queda el esqueleto */ },
    });
    this.tiendaSrv.fotos().subscribe({
      next: l => { if (l.some(f => f.url)) this.fotos.set(l); },
      error: () => { /* se quedan las fotos locales */ },
    });
  }

  // Al entrar: recoloca el mapa
  ionViewDidEnter(): void {
    this.mapa?.invalidateSize();
  }

  ngOnDestroy(): void {
    this.mapa?.remove();
  }

  cambiarVista(valor: unknown): void {
    this.vista.set((valor as Vista) ?? 'ubicacion');
    if (valor === 'ubicacion') setTimeout(() => this.mapa?.invalidateSize(), 50);   // el mapa estaba oculto
  }

  // Abre la navegación hasta la tienda en la app de mapas
  comoLlegar(): void {
    const t = this.tienda();
    if (t) window.open(`https://www.google.com/maps/dir/?api=1&destination=${t.latitud},${t.longitud}`, '_blank');
  }

  telefonoEnlace(t: Tienda): string {
    return 'tel:' + t.telefono.replace(/\s/g, '');
  }

  // Mapa fijo, como en Android: no se arrastra ni se hace zoom; al tocarlo se abre la ruta
  private crearMapa(): void {
    const t = this.tienda();
    const el = this.mapaEl()?.nativeElement;
    if (!t || !el || this.mapa) return;

    this.mapa = L.map(el, {
      zoomControl: false, dragging: false, touchZoom: false, scrollWheelZoom: false,
      doubleClickZoom: false, boxZoom: false, keyboard: false,
    }).setView([t.latitud, t.longitud], 17);

    // Teselas de Esri (ojo: {z}/{y}/{x}, al revés que OpenStreetMap)
    L.tileLayer('https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}', {
      maxZoom: 19,
      attribution: 'Tiles © Esri',
    }).addTo(this.mapa);

    L.marker([t.latitud, t.longitud], {
      icon: L.divIcon({ className: 'pin-tienda', html: PIN, iconSize: [72, 72], iconAnchor: [36, 36] }),
      interactive: false,
    }).addTo(this.mapa);

    this.mapa.on('click', () => this.comoLlegar());
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
  } @else if (!pedidos().length) {
    <app-estado icono="receipt-outline" titulo="Sin pedidos" texto="Todavía no has hecho ningún pedido. Puedes hacerlo desde la tienda."
                boton="Ir a la tienda" (accion)="irATienda()"></app-estado>
  } @else {
    <div class="cascada">
      <!-- ===== El último pedido, destacado arriba ===== -->
      @if (ultimo(); as p) {
        <ion-card class="tarjeta pedido">
          <div class="cabecera"><strong>Pedido #{{ p.id }}</strong><span>{{ p.fecha | fechaCorta }}</span></div>

          <!-- Pasos del envío (o «Cancelado») -->
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

          <p class="nombre">{{ titulo(p) }}</p>
          <div class="pie">
            <ng-container *ngTemplateOutlet="miniaturas; context: { $implicit: p }"></ng-container>
            <app-precio [valor]="p.total"></app-precio>
          </div>

          @if (p.se_puede_cancelar) {
            <button type="button" class="cancelar pulsable" (click)="cancelar(p)">Cancelar pedido</button>
          }
        </ion-card>
      }

      <!-- ===== Anteriores: tarjetas compactas con «Ver más» ===== -->
      @if (anteriores().length) {
        <div class="seccion"><h2>Anteriores</h2></div>
        <ion-list class="lista">
          @for (p of anteriores(); track p.id) {
            <ion-card class="tarjeta anterior">
              <p class="nombre">{{ titulo(p) }}</p>
              <p class="resumen">#{{ p.id }} · {{ p.fecha | fechaCorta }} · {{ p.total | euros }}@if (p.estado === 'cancelado') { · Cancelado }</p>
              <ng-container *ngTemplateOutlet="miniaturas; context: { $implicit: p }"></ng-container>

              @if (p.se_puede_cancelar) {
                <button type="button" class="cancelar pulsable" (click)="cancelar(p)">Cancelar pedido</button>
              }
              @if ((lineas()[p.id]?.length ?? 0) > 1) {
                <button type="button" class="ver-mas pulsable" (click)="verMas(p)">
                  {{ abierto() === p.id ? 'Ver menos' : 'Ver más · ' + lineas()[p.id].length + ' artículos' }}
                  <ion-icon [name]="abierto() === p.id ? 'chevron-up' : 'chevron-down'"></ion-icon>
                </button>
              }

              <!-- Todos los artículos del pedido -->
              @if (abierto() === p.id) {
                <ul class="detalle">
                  @for (l of lineas()[p.id]; track l.id) {
                    <li>
                      <app-miniatura-producto [producto]="l.producto"></app-miniatura-producto>
                      <span class="textos"><strong>{{ l.producto | nombreProducto }}</strong><small>{{ l.cantidad }} × {{ l.precio_unitario | euros }}</small></span>
                      <app-precio [valor]="l.subtotal"></app-precio>
                    </li>
                  }
                </ul>
              }
            </ion-card>
          }
        </ion-list>
      }
    </div>
  }

  <!-- Hasta 3 portadas de izquierda a derecha (+N si hay más) -->
  <ng-template #miniaturas let-p>
    <div class="minis">
      @for (l of primeras(p); track l.id) {
        <span class="mini">
          <app-miniatura-producto [producto]="l.producto"></app-miniatura-producto>
          @if (l.cantidad > 1) { <b class="cantidad">×{{ l.cantidad }}</b> }
        </span>
      } @empty {
        <app-miniatura-producto [producto]="mini(p)"></app-miniatura-producto>
      }
      @if (restantes(p) > 0) { <span class="mas">+{{ restantes(p) }}</span> }
    </div>
  </ng-template>
</ion-content>
JUEGALMI_EOF

mkdir -p $(dirname src/app/pages/pedidos/pedidos.page.scss)
cat > src/app/pages/pedidos/pedidos.page.scss <<'JUEGALMI_EOF'
.pedido, .anterior { margin: 0 0 14px; }
.nombre { margin: 14px 0 8px; font-size: 16px; font-weight: 500; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.anterior {
  padding: 16px 18px;
  .nombre { margin: 0 0 4px; }
  .resumen { margin: 0 0 12px; color: var(--jg-texto-sec); font-size: 14px; }
  .cancelar { margin-top: 12px; }
}
.pedido {
  padding: 20px 20px 18px;
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
.mini { position: relative; display: block; }
.cantidad {
  position: absolute; right: -6px; top: -6px; padding: 1px 6px; border-radius: 999px;
  background: #1f2329; color: #ffffff; font-size: 11px;
}
.mas {
  align-self: center; min-width: 36px; height: 36px; padding: 0 8px; border-radius: 10px;
  display: grid; place-items: center; background: var(--jg-acento-suave); font-size: 14px; font-weight: 700;
}
.ver-mas {
  display: inline-flex; align-items: center; gap: 6px; margin-top: 12px; padding: 8px 14px;
  border: 0; border-radius: 999px; background: var(--jg-acento-suave);
  color: var(--ion-text-color); font: inherit; font-size: 14px; font-weight: 600; white-space: nowrap;
}

// Lista completa al pulsar «Ver más»
.detalle {
  list-style: none; margin: 16px 0 0; padding: 12px 0 0; border-top: 1px solid var(--jg-borde);
  display: flex; flex-direction: column; gap: 12px;
  li { display: flex; align-items: center; gap: 12px; }
  app-miniatura-producto { --tam: 48px; --radio: 10px; }
  .textos { flex-grow: 1; display: flex; flex-direction: column; gap: 2px; min-width: 0; }
  strong { font-size: 15px; font-weight: 600; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
  small { color: var(--jg-texto-sec); font-size: 13px; }
  app-precio { font-size: 17px; }
}

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
import { Component, computed, inject, signal } from '@angular/core';
import { IonHeader, IonToolbar, IonButtons, IonBackButton, IonContent, IonSkeletonText, IonIcon,
         AlertController, ToastController, IonList, IonCard } from '@ionic/angular';
import { EstadoComponent } from '../../components/estado/estado.component';
import { MiniaturaProductoComponent } from '../../components/miniatura-producto/miniatura-producto.component';
import { PrecioComponent } from '../../components/precio/precio.component';
import { FechaCortaPipe } from '../../pipes/fecha-corta.pipe';
import { PedidoService } from '../../services/pedido.service';
import { SesionService } from '../../services/sesion.service';
import { EstadoPedido, LineaPedido, PedidoResumen } from '../../models/pedido.model';
import { NombreProductoPipe, nombreProducto } from '../../pipes/nombre-producto.pipe';
import { NgTemplateOutlet } from '@angular/common';
import { Router } from '@angular/router';
import { EurosPipe } from '../../pipes/euros.pipe';
import { catchError, forkJoin, map, of } from 'rxjs';
import { addIcons } from 'ionicons';
import { chevronDown, chevronUp } from 'ionicons/icons';

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
  styleUrls: ['../subpagina.scss', './pedidos.page.scss'],
  imports: [IonList, IonCard, NgTemplateOutlet, IonHeader, IonToolbar, IonButtons, IonBackButton, IonContent, IonSkeletonText, IonIcon,
            EstadoComponent, MiniaturaProductoComponent, NombreProductoPipe, EurosPipe, PrecioComponent, FechaCortaPipe],
})
export class PedidosPage {
  private servicio = inject(PedidoService);
  private router = inject(Router);
  private sesion = inject(SesionService);
  private alerta = inject(AlertController);
  private toast = inject(ToastController);

  pedidos = signal<PedidoResumen[]>([]);     // GET /api/pedidos (el más reciente primero)
  cargando = signal(true);
  lineas = signal<Record<number, LineaPedido[]>>({});   // artículos de cada pedido (GET /api/pedidos/{id})
  abierto = signal<number | null>(null);                // pedido con «Ver más» desplegado
  error = signal(false);                     // sin conexión → Reintentar
  pasos = PASOS;

  constructor() {
    addIcons({ chevronDown, chevronUp });
  }

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
  // El último pedido va destacado arriba; el resto en «Anteriores»
  ultimo = computed(() => this.pedidos()[0] ?? null);
  anteriores = computed(() => this.pedidos().slice(1));

  // «PlayStation 5 Slim» o «Elden Ring +2» si el pedido tiene más artículos
  titulo(p: PedidoResumen): string {
    const l = this.lineas()[p.id];
    if (!l?.length) return p.primer_producto;
    return l.length > 1 ? `${nombreProducto(l[0].producto)} +${l.length - 1}` : nombreProducto(l[0].producto);
  }

  irATienda(): void { this.router.navigateByUrl('/tienda'); }

  mini(p: PedidoResumen) {
    return { nombre: p.primer_producto, imagen_url: p.imagen_url };
  }

  // PUT /api/pedidos/{id}/cancelar (solo pendiente/pagado: se_puede_cancelar)
  async cancelar(p: PedidoResumen): Promise<void> {
    const a = await this.alerta.create({
      header: '¿Cancelar el pedido?',
      message: `El pedido #${p.id} se cancelará y no se te cobrará.`,
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

  // Hasta 3 portadas en la tarjeta; el resto con «Ver más»
  primeras(p: PedidoResumen): LineaPedido[] { return (this.lineas()[p.id] ?? []).slice(0, 3); }
  restantes(p: PedidoResumen): number { return Math.max(0, (this.lineas()[p.id]?.length ?? 0) - 3); }

  verMas(p: PedidoResumen): void {
    this.abierto.update(id => id === p.id ? null : p.id);
  }

  cargar(): void {
    this.error.set(false);
    this.servicio.listar().subscribe({
      next: r => { this.pedidos.set(r.datos); this.cargando.set(false); this.cargarLineas(r.datos); },
      error: () => { this.cargando.set(false); this.error.set(true); },
    });
  }

  // El listado solo trae el primer producto: se pide el detalle de cada pedido para ver todos
  private cargarLineas(pedidos: PedidoResumen[]): void {
    if (!pedidos.length) return;
    forkJoin(pedidos.map(p => this.servicio.obtener(p.id).pipe(
      map(d => [p.id, d.lineas] as const),
      catchError(() => of([p.id, []] as const)),        // si falla uno, ese se queda con la portada del listado
    ))).subscribe(res => this.lineas.set(Object.fromEntries(res)));
  }

  private async aviso(mensaje: string, color: string): Promise<void> {
    const t = await this.toast.create({ message: mensaje, duration: 2500, color });
    await t.present();
  }
}
JUEGALMI_EOF

mkdir -p $(dirname src/app/pages/registro/registro.page.html)
cat > src/app/pages/registro/registro.page.html <<'JUEGALMI_EOF'
<ion-content class="ion-padding">
  <header class="cabecera-acceso">
    <div class="marca"><span class="logo">J</span><span>JuegAlmi</span></div>
    <a routerLink="/login" routerDirection="back">Ya tengo cuenta</a>
  </header>

  <h1>Crear cuenta</h1>
  <p class="subtitulo">Solo te llevará un minuto.</p>

  <form [formGroup]="form" (ngSubmit)="registrar()" novalidate>
    <div class="campo">
      <label>Nombre</label>
      <ion-input formControlName="nombre" autocomplete="given-name" aria-label="Nombre" [class.mal]="invalido('nombre')"></ion-input>
      @if (invalido('nombre')) { <p class="error">{{ mensajeError('nombre') }}</p> }
    </div>

    <!-- Dos columnas: apellidos -->
    <div class="fila">
      <div class="campo">
        <label>1er apellido</label>
        <ion-input formControlName="apellido1" autocomplete="family-name" aria-label="Primer apellido" [class.mal]="invalido('apellido1')"></ion-input>
        @if (invalido('apellido1')) { <p class="error">{{ mensajeError('apellido1') }}</p> }
      </div>
      <div class="campo">
        <label>2º apellido</label>
        <ion-input formControlName="apellido2" aria-label="Segundo apellido"></ion-input>
      </div>
    </div>

    <!-- Dos columnas: DNI y teléfono -->
    <div class="fila">
      <div class="campo">
        <label>DNI</label>
        <ion-input formControlName="dni" placeholder="12345678Z" maxlength="9" aria-label="DNI" [class.mal]="invalido('dni')"></ion-input>
        @if (invalido('dni')) { <p class="error">{{ mensajeError('dni') }}</p> }
      </div>
      <div class="campo">
        <label>Teléfono <small>(opcional)</small></label>
        <ion-input formControlName="telefono" type="tel" inputmode="tel" autocomplete="tel" aria-label="Teléfono" [class.mal]="invalido('telefono')"></ion-input>
        @if (invalido('telefono')) { <p class="error">{{ mensajeError('telefono') }}</p> }
      </div>
    </div>

    <div class="campo">
      <label>Email</label>
      <ion-input formControlName="email" type="email" inputmode="email" autocomplete="email" aria-label="Email" [class.mal]="invalido('email')"></ion-input>
      @if (invalido('email')) { <p class="error">{{ mensajeError('email') }}</p> }
    </div>

    <div class="campo">
      <label>Contraseña</label>
      <ion-input formControlName="password" type="password" autocomplete="new-password" aria-label="Contraseña" [class.mal]="invalido('password')"></ion-input>
      @if (invalido('password')) { <p class="error">{{ mensajeError('password') }}</p> }
    </div>

    @if (error()) {
      <p class="error-general" role="alert">{{ error() }}</p>
    }

    <ion-button type="submit" expand="block" [disabled]="cargando()">
      @if (cargando()) { <ion-spinner name="crescent"></ion-spinner> } @else { Registrarme }
    </ion-button>
  </form>

  <p class="pie">JuegAlmi · Bilbao</p>
</ion-content>
JUEGALMI_EOF

mkdir -p $(dirname src/app/pages/registro/registro.page.scss)
cat > src/app/pages/registro/registro.page.scss <<'JUEGALMI_EOF'
ion-content { --padding-top: calc(14px + var(--ion-safe-area-top, 0px)); --padding-bottom: 32px; }

.cabecera-acceso {
  display: flex; align-items: center; justify-content: space-between;
  min-height: 56px; margin-bottom: 28px;
  .marca { display: flex; align-items: center; gap: 10px; font-size: 24px; font-weight: 700; letter-spacing: -0.04em; }
  a { color: var(--ion-text-color); font-size: 16px; font-weight: 500; text-decoration: none; }
}

h1 { margin: 0; font-size: 46px; line-height: 1.02; font-weight: 700; letter-spacing: -0.055em; }
.subtitulo { margin: 14px 0 32px; color: var(--jg-texto-sec); font-size: 18px; line-height: 1.5; max-width: 300px; }

form { display: flex; flex-direction: column; gap: 18px; }
.campo { display: flex; flex-direction: column; gap: 10px; min-width: 0; label { font-size: 17px; font-weight: 500; } }
.fila { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 14px; }

.error-general {
  margin: 0; padding: 12px 14px; border-radius: 14px;
  background: rgba(167, 33, 68, .12); color: var(--ion-color-danger); font-size: 14px;
}

ion-button { margin-top: 12px; }

// Línea fina con el usuario de prueba en medio
.nota {
  display: flex; align-items: center; gap: 12px;
  margin: 24px 0 0; color: var(--jg-texto-sec); font-size: 13px;
  &::before, &::after { content: ''; flex: 1; height: 1px; background: var(--jg-borde); }
}
.pie { margin: 40px 0 0; text-align: center; color: var(--jg-texto-sec); font-size: 13px; }
.campo label small { color: var(--jg-texto-sec); font-weight: 400; margin-left: 4px; font-size: 14px; }
JUEGALMI_EOF

mkdir -p $(dirname src/app/pages/registro/registro.page.ts)
cat > src/app/pages/registro/registro.page.ts <<'JUEGALMI_EOF'
import { Component, inject, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { IonContent, IonInput, IonButton, IonSpinner, MenuController } from '@ionic/angular';
import { SesionService } from '../../services/sesion.service';
import { OBLIGATORIO, dniValido, telefonoValido, textoError } from '../../validators/validadores';

const BORRADOR = 'juegalmi_registro';   // clave en sessionStorage

type Campo = 'nombre' | 'apellido1' | 'apellido2' | 'dni' | 'telefono' | 'email' | 'password';

@Component({
  selector: 'app-registro',
  templateUrl: './registro.page.html',
  styleUrls: ['../login/login.page.scss', './registro.page.scss'],   // reutiliza los estilos del login
  imports: [ReactiveFormsModule, RouterLink, IonContent, IonInput, IonButton, IonSpinner],
})
export class RegistroPage {
  private sesion = inject(SesionService);
  private router = inject(Router);
  private menu = inject(MenuController);

  cargando = signal(false);
  error = signal('');

  form = inject(FormBuilder).nonNullable.group({
    nombre: ['', [Validators.required, Validators.minLength(2)]],
    apellido1: ['', [Validators.required, Validators.minLength(2)]],
    apellido2: [''],                                               // opcional
    dni: ['', [Validators.required, dniValido]],
    telefono: ['', telefonoValido],                               // opcional
    email: ['', [Validators.required, Validators.email]],
    password: ['', [Validators.required, Validators.minLength(6)]],
  });

  // Mensaje de error de cada campo
  // Mensaje si el formato está mal (si está vacío: «Este campo es obligatorio»)
  formatos: Record<Campo, string> = {
    nombre: OBLIGATORIO,
    apellido1: OBLIGATORIO,
    apellido2: '',
    dni: 'El DNI o NIE no es válido.',
    telefono: 'El teléfono debe tener 9 números y empezar por 6, 7, 8 o 9.',
    email: 'El email no es válido.',
    password: 'La contraseña debe tener al menos 6 caracteres.',
  };

  constructor() {
    // sessionStorage: si sales y vuelves en la misma sesión, el formulario conserva lo escrito
    try {
      const guardado = sessionStorage.getItem(BORRADOR);
      if (guardado) this.form.patchValue(JSON.parse(guardado));
    } catch { /* sin almacenamiento */ }

    this.form.valueChanges.pipe(takeUntilDestroyed()).subscribe(valor => {
      const { password: _, ...sinClave } = valor;                  // la contraseña nunca se guarda
      try { sessionStorage.setItem(BORRADOR, JSON.stringify(sinClave)); } catch { /* sin almacenamiento */ }
    });
  }

  ionViewWillEnter(): void { this.menu.enable(false); }
  ionViewWillLeave(): void { this.menu.enable(true); }

  invalido(campo: Campo): boolean {
    const c = this.form.controls[campo];
    return c.invalid && c.touched;
  }

  mensajeError(campo: Campo): string {
    return textoError(this.form.controls[campo], this.formatos[campo]);
  }

  registrar(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    this.cargando.set(true);
    this.error.set('');
    const v = this.form.getRawValue();

    this.sesion.registrar({
      ...v,
      email: v.email.trim().toLowerCase(),
      dni: v.dni.trim().toUpperCase(),
      telefono: v.telefono.replace(/\s/g, '') || undefined,      // opcional
      apellido2: v.apellido2.trim() || undefined,
    }).subscribe({
      next: () => {
        this.cargando.set(false);
        try { sessionStorage.removeItem(BORRADOR); } catch { /* sin almacenamiento */ }
        this.form.reset();
        this.router.navigateByUrl('/inicio', { replaceUrl: true });   // ya queda dentro
      },
      error: (e: Error) => {
        this.cargando.set(false);
        this.error.set(e.message);
      },
    });
  }
}
JUEGALMI_EOF

mkdir -p $(dirname src/app/pages/reparacion/reparacion.page.html)
cat > src/app/pages/reparacion/reparacion.page.html <<'JUEGALMI_EOF'
<ion-header class="ion-no-border">
  <ion-toolbar>
    <ion-buttons slot="start">
      <ion-back-button class="redondo" defaultHref="/taller" text=""></ion-back-button>
    </ion-buttons>
  </ion-toolbar>
</ion-header>

<ion-content class="ion-padding">
  <ion-refresher slot="fixed" (ionRefresh)="refrescar($event)">
    <ion-refresher-content></ion-refresher-content>
  </ion-refresher>

  @if (rep(); as r) {
    <div class="cascada">
      <!-- Estado en grande + tramos -->
      <section class="estado">
        <span>{{ r.numero }} · {{ tipo() }} · {{ r.marca }} {{ r.modelo }}</span>
        <h1>{{ r.estado_texto }}</h1>
        @if (r.estado !== 'cancelada') {
          <div class="tramos">
            @for (p of r.pasos ?? []; track p.estado) { <i [class.hecho]="p.hecho"></i> }
          </div>
        }
      </section>

      <!-- Avería / Presupuesto -->
      <div class="datos">
        <div class="tarjeta"><span>Avería</span><strong>{{ r.descripcion_averia }}</strong></div>
        <div class="tarjeta">
          <span>Presupuesto</span>
          @if (r.presupuesto != null) { <app-precio [valor]="r.presupuesto"></app-precio> }
          @else { <strong>Pendiente</strong> }
        </div>
      </div>

      <!-- Línea de tiempo (pasos calculados por la API) -->
      @if (r.estado !== 'cancelada') {
        <ol class="tarjeta linea-tiempo">
          @for (p of r.pasos ?? []; track p.estado) {
            <li [class.hecho]="p.hecho" [class.actual]="p.actual">
              <span class="punto"></span>
              <div class="crece">
                <strong>{{ p.texto }}</strong>
                @if (p.actual && p.descripcion) { <p>{{ p.descripcion }}</p> }
              </div>
              @if (p.fecha) { <small>{{ p.fecha | fechaCorta }}</small> }
            </li>
          }
        </ol>
      }

      <!-- Técnico + llamar -->
      <div class="contacto">
        <div class="tarjeta tecnico">
          @if (r.trabajador; as t) {
            <span class="inicial">{{ t.nombre_completo[0] }}</span>
            <span><strong>{{ t.nombre_completo }}</strong><small>{{ t.cargo }} · {{ t.departamento }}</small></span>
          } @else {
            <span class="inicial">?</span>
            <span><strong>Aún sin técnico</strong><small>Te avisaremos cuando lo revisen.</small></span>
          }
        </div>
        @if (telefono()) {
          <a class="llamar pulsable" [href]="telefono()" aria-label="Llamar"><ion-icon name="call-outline"></ion-icon></a>
        }
      </div>

      <!-- Fotos -->
      @if (r.fotos?.length) {
        <div class="seccion"><h2>Fotos</h2></div>
        <div class="fotos">
          @for (f of r.fotos; track f.id) {
            <a class="foto" [href]="f.url" target="_blank" rel="noopener">
              <img [src]="f.miniatura_url ?? f.url" alt="Foto {{ $index + 1 }}" loading="lazy">
            </a>
          }
        </div>
      }

      @if (r.se_puede_cancelar) {
        <ion-button expand="block" fill="outline" color="danger" class="cancelar" (click)="cancelar()" [disabled]="cancelando()">
          Cancelar solicitud
        </ion-button>
      }
    </div>
  } @else {
    <ion-skeleton-text [animated]="true" style="height: 176px; border-radius: 30px"></ion-skeleton-text>
    <ion-skeleton-text [animated]="true" style="height: 110px; border-radius: 24px; margin-top: 14px"></ion-skeleton-text>
  }
</ion-content>
JUEGALMI_EOF

mkdir -p $(dirname src/app/pages/reparacion/reparacion.page.scss)
cat > src/app/pages/reparacion/reparacion.page.scss <<'JUEGALMI_EOF'
ion-toolbar { --background: var(--ion-background-color); --min-height: 64px; padding: 0 12px; }

// Tarjeta turquesa con el estado
.estado {
  padding: 24px 22px; border-radius: 30px;
  background: linear-gradient(135deg, #8ad6d8 0%, #6fc4c7 100%); color: #1f2329;
  span { font-size: 15px; opacity: .8; }
  h1 { margin: 22px 0 18px; font-size: 44px; line-height: 1; font-weight: 700; letter-spacing: -0.055em; }
}
.tramos {
  display: grid; grid-template-columns: repeat(5, 1fr); gap: 8px;
  i { height: 6px; border-radius: 3px; background: rgba(31, 35, 41, .15); }
  i.hecho { background: #1f2329; }
}

// Avería / Presupuesto
.datos {
  display: grid; grid-template-columns: 1fr 1fr; gap: 14px; margin: 14px 0;
  .tarjeta { display: flex; flex-direction: column; gap: 8px; padding: 18px; }
  span { color: var(--jg-texto-sec); font-size: 15px; }
  strong { font-size: 17px; font-weight: 600; line-height: 1.4; }
  app-precio { font-size: 34px; }
}

// Línea de tiempo
.linea-tiempo {
  list-style: none; margin: 0 0 14px; padding: 20px 20px 4px;

  li { position: relative; display: flex; gap: 16px; padding-bottom: 24px; color: var(--jg-texto-sec); }
  li:not(:last-child)::before {               // línea vertical
    content: ''; position: absolute; left: 6px; top: 16px; bottom: -2px;
    width: 2px; background: var(--jg-borde);
  }
  li.hecho:not(:last-child)::before { background: var(--ion-text-color); }
  .punto { width: 14px; height: 14px; margin-top: 3px; border-radius: 50%; flex-shrink: 0; background: var(--jg-borde); z-index: 1; }
  li.hecho { color: var(--ion-text-color); .punto { background: var(--ion-text-color); } }
  li.actual .punto { background: var(--jg-tarjeta); border: 3px solid var(--jg-acento); }
  .crece { flex-grow: 1; }
  strong { font-size: 17px; font-weight: 500; }
  p { margin: 6px 0 0; color: var(--jg-texto-sec); font-size: 15px; line-height: 1.45; }
  small { font-size: 13px; color: var(--jg-texto-sec); letter-spacing: .05em; padding-top: 3px; white-space: nowrap; }
}

// Técnico + botón turquesa de llamar
.contacto { display: flex; gap: 14px; }
.tecnico {
  flex-grow: 1; display: flex; align-items: center; gap: 14px; padding: 18px;
  .inicial {
    width: 48px; height: 48px; border-radius: 50%; display: flex; align-items: center; justify-content: center;
    background: var(--jg-acento-suave); font-weight: 600;
  }
  strong { display: block; font-size: 17px; font-weight: 600; }
  small { color: var(--jg-texto-sec); font-size: 15px; }
}
.llamar {
  width: 86px; border-radius: 24px; flex-shrink: 0;
  display: flex; align-items: center; justify-content: center;
  background: var(--jg-acento); color: #1f2329; font-size: 26px;
}

.fotos { display: flex; gap: 10px; }
.foto {
  width: 96px; height: 96px; border-radius: 18px; overflow: hidden;
  display: flex; align-items: center; justify-content: center;
  background: var(--jg-tarjeta); color: var(--jg-texto-sec); font-size: 30px;
  img { width: 100%; height: 100%; object-fit: cover; }
}

.cancelar { margin-top: 26px; --border-radius: 999px; min-height: 52px; }
.foto img { width: 100%; height: 100%; object-fit: cover; }
JUEGALMI_EOF

mkdir -p $(dirname src/app/pages/reparacion/reparacion.page.ts)
cat > src/app/pages/reparacion/reparacion.page.ts <<'JUEGALMI_EOF'
import { Component, computed, inject, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { ActivatedRoute } from '@angular/router';
import { IonHeader, IonToolbar, IonButtons, IonBackButton, IonContent, IonIcon, IonButton,
         IonSkeletonText, IonRefresher, IonRefresherContent, RefresherCustomEvent,
         AlertController, ToastController } from '@ionic/angular';
import { addIcons } from 'ionicons';
import { imageOutline, callOutline } from 'ionicons/icons';
import { PrecioComponent } from '../../components/precio/precio.component';
import { FechaCortaPipe } from '../../pipes/fecha-corta.pipe';
import { ReparacionService } from '../../services/reparacion.service';
import { TiendaService } from '../../services/tienda.service';
import { SesionService } from '../../services/sesion.service';
import { NOMBRE_DISPOSITIVO, Reparacion } from '../../models/reparacion.model';

@Component({
  selector: 'app-reparacion',
  templateUrl: './reparacion.page.html',
  styleUrls: ['./reparacion.page.scss'],
  imports: [IonHeader, IonToolbar, IonButtons, IonBackButton, IonContent, IonIcon, IonButton,
            IonSkeletonText, IonRefresher, IonRefresherContent, PrecioComponent, FechaCortaPipe],
})
export class ReparacionPage {
  private servicio = inject(ReparacionService);
  private sesion = inject(SesionService);
  private alerta = inject(AlertController);
  private toast = inject(ToastController);
  private id = 0;

  rep = signal<Reparacion | null>(null);
  telTienda = signal('');                    // si aún no hay técnico se llama a la tienda
  cancelando = signal(false);

  tipo = computed(() => NOMBRE_DISPOSITIVO[this.rep()?.tipo_dispositivo ?? 'otro']);
  // Teléfono del técnico asignado o, si no hay, el de la tienda
  telefono = computed(() => {
    const t = this.rep()?.trabajador?.telefono ?? this.telTienda();
    return t ? 'tel:' + t.replace(/\s/g, '') : '';
  });

  constructor() {
    addIcons({ imageOutline, callOutline });
    inject(TiendaService).obtener().subscribe({ next: t => this.telTienda.set(t.telefono), error: () => {} });
    inject(ActivatedRoute).paramMap.pipe(takeUntilDestroyed()).subscribe(p => {
      this.id = Number(p.get('id'));
      this.cargar();
    });
  }

  refrescar(e: RefresherCustomEvent): void {
    this.cargar(() => e.target.complete());
  }

  // DELETE /api/reparaciones/{id} (solo en "recibida": se_puede_cancelar)
  async cancelar(): Promise<void> {
    const a = await this.alerta.create({
      header: '¿Cancelar la solicitud?',
      message: 'Solo se puede cancelar mientras no hayamos empezado a revisarla.',
      buttons: [
        { text: 'Sí, cancelar', role: 'destructive', handler: () => this.confirmarCancelar() },
        { text: 'No', role: 'cancel' },
      ],
    });
    await a.present();
  }

  private confirmarCancelar(): void {
    this.cancelando.set(true);
    this.servicio.cancelar(this.id).subscribe({
      next: r => { this.cancelando.set(false); this.rep.set(r); this.aviso('Solicitud cancelada', 'dark'); },
      error: e => { this.cancelando.set(false); this.aviso(this.sesion.mensaje(e), 'danger'); },
    });
  }

  private cargar(alTerminar?: () => void): void {
    this.servicio.obtener(this.id).subscribe({
      next: r => { this.rep.set(r); alTerminar?.(); },
      error: () => alTerminar?.(),
    });
  }

  private async aviso(mensaje: string, color: string): Promise<void> {
    const t = await this.toast.create({ message: mensaje, duration: 3000, position: 'bottom', color });
    await t.present();
  }
}
JUEGALMI_EOF

mkdir -p $(dirname src/app/pages/subpagina.scss)
cat > src/app/pages/subpagina.scss <<'JUEGALMI_EOF'
// Cabecera: solo el botón redondo de volver
ion-toolbar { --background: var(--ion-background-color); --min-height: 70px; padding: 0 14px; }
ion-back-button {
  --color: var(--ion-text-color); --border-radius: 50%; --icon-font-size: 22px;
  width: 48px; height: 48px; border-radius: 50%; background: var(--jg-tarjeta);
}
ion-title { text-align: center; padding-inline-end: 60px; font-size: 18px; font-weight: 700; }
ion-content { --padding-bottom: 130px; }

.subtitulo { margin: -12px 0 22px; color: var(--jg-texto-sec); font-size: 17px; }
h2 { margin: 30px 0 14px; font-size: 24px; font-weight: 700; letter-spacing: -0.04em; }
.vacio { text-align: center; color: var(--jg-texto-sec); margin-top: 40px; }

// Tarjeta tipo fila: miniatura · textos · precio
.fila {
  display: flex; align-items: center; gap: 16px;
  padding: 14px 18px 14px 14px; margin-bottom: 14px;
  color: var(--ion-text-color); text-decoration: none;
  app-miniatura-producto { --tam: 72px; --radio: 14px; --fondo: #ffffff; --ajuste: contain; height: 84px; }
  .textos { flex-grow: 1; display: flex; flex-direction: column; gap: 4px; min-width: 0; }
  strong { font-size: 17px; font-weight: 600; }
  small { color: var(--jg-texto-sec); font-size: 15px; }
  app-precio { font-size: 22px; }
}

// Lista de datos dentro de tarjeta
.lista { display: flex; flex-direction: column; overflow: hidden; padding: 4px 0; }
.item {
  display: flex; align-items: center; gap: 14px;
  min-height: 60px; padding: 0 20px; border: 0; border-bottom: 1px solid var(--jg-borde);
  background: var(--jg-tarjeta); color: var(--ion-text-color); font: inherit; text-align: left; text-decoration: none;
  &:last-child { border-bottom: 0; }
  ion-icon { font-size: 20px; color: var(--jg-texto-sec); flex-shrink: 0; }
  .crece { flex-grow: 1; font-size: 16px; }
  .dato { color: var(--jg-texto-sec); font-size: 15px; }
}

// Formularios
form { display: flex; flex-direction: column; gap: 18px; }
.campo { display: flex; flex-direction: column; gap: 10px; min-width: 0; label { font-size: 16px; font-weight: 500; } }
.campo label small { color: var(--jg-texto-sec); font-weight: 400; margin-left: 6px; }
.fila2 { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 14px; }
.fijo {
  display: flex; align-items: center; justify-content: space-between;
  min-height: 52px; padding: 0 16px; border-radius: 16px;
  background: rgba(255, 255, 255, .55); color: var(--jg-texto-sec); font-size: 17px;
}
.error { margin: 0; color: var(--ion-color-danger); font-size: 13px; }

// Botón fijo abajo dentro de una tarjeta blanca flotante
ion-footer { padding: 0 14px calc(14px + var(--ion-safe-area-bottom, 0px)); background: transparent; }
.pie-boton {
  padding: 12px; border-radius: 30px; background: var(--jg-tarjeta); box-shadow: var(--jg-sombra);
  ion-button { margin: 0; min-height: 56px; }
}

// Etiqueta de estado (pantallas antiguas: ajustes, panel...)
.chip-estado {
  height: 26px; padding: 0 12px; border-radius: 999px; font-size: 12px; font-weight: 700;
  display: inline-flex; align-items: center; background: var(--jg-gris); color: var(--jg-texto-sec);
  &.verde { background: rgba(52, 168, 83, .15); color: #2e9d55; }
  &.morado { background: var(--jg-acento-suave); color: var(--ion-text-color); }
  &.rojo { background: rgba(167, 33, 68, .14); color: var(--ion-color-danger); }
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
    <!-- Barra de 3 partes: turquesa cuando esa zona del formulario está completa -->
    <div class="pasos" aria-hidden="true">
      <span [class.hecho]="parte1()"></span><span [class.hecho]="parte2()"></span><span [class.hecho]="parte3()"></span>
    </div>

    <h1 class="titulo">¿Qué reparamos?</h1>

    <!-- 1. Tipo de dispositivo (2 filas de 4) -->
    <div class="tipos">
      @for (t of tipos; track t.valor) {
        <button type="button" class="tipo pulsable" [class.activo]="tipo() === t.valor" (click)="elegirTipo(t.valor)">
          <ion-icon [name]="t.icono"></ion-icon>
          <span>{{ t.texto }}</span>
        </button>
      }
    </div>

    <!-- 2. Marca y Modelo en la misma fila -->
    <div class="dos-campos">
      <div>
        <label class="etiqueta">Marca</label>
        <ion-input [value]="marca()" (ionInput)="marca.set($event.detail.value ?? '')" placeholder="Sony" aria-label="Marca"></ion-input>
      </div>
      <div>
        <label class="etiqueta">Modelo</label>
        <ion-input [value]="modelo()" (ionInput)="modelo.set($event.detail.value ?? '')" placeholder="PlayStation 5" aria-label="Modelo"></ion-input>
      </div>
    </div>

    <!-- 3. Componente afectado: los 13 de siempre, solo uno -->
    <label class="etiqueta">Componente afectado</label>
    <div class="chips envolver">
      @for (c of componentes; track c) {
        <ion-chip class="filtro" [class.activo]="componente() === c" (click)="componente.set(c)">{{ c }}</ion-chip>
      }
    </div>

    <!-- 4. Describe el problema -->
    <label class="etiqueta">Describe el problema</label>
    <ion-textarea [value]="descripcion()" (ionInput)="descripcion.set($event.detail.value ?? '')"
                  [autoGrow]="true" rows="4" placeholder="Ej.: no da imagen por HDMI desde ayer" aria-label="Descripción de la avería"></ion-textarea>

    <!-- 5. Fotos (opcional, hasta 5) -->
    <label class="etiqueta">Fotos (opcional)</label>
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
          <span>Añadir</span>
        </button>
      }
    </div>

    <!-- Un solo mensaje de error, encima del botón -->
    @if (intentado() && error()) { <p class="caja-error">{{ error() }}</p> }

    <ion-button expand="block" class="continuar" (click)="continuar()" [disabled]="enviando()">
      {{ enviando() ? 'Enviando…' : 'Continuar' }}
    </ion-button>
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
        <ion-list class="lista cascada">
          @for (r of enCurso(); track r.id) {
            <ion-card class="tarjeta pulsable" (click)="abrir(r)">
            <div class="en-curso">
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
              <span class="dato"><span>Presupuesto</span><span>{{ r.presupuesto != null ? (r.presupuesto | euros) : 'Pendiente' }}</span></span>
            </div>
            </ion-card>
          }
        </ion-list>
      }

      @if (entregadas().length) {
        <div class="seccion"><h2>Entregadas</h2></div>
        <ion-list class="lista">
        @for (r of entregadas(); track r.id) {
          <ion-card class="tarjeta pulsable" (click)="abrir(r)">
          <div class="entregada">
            <ion-icon name="checkmark-circle-outline"></ion-icon>
            <span class="textos"><strong>{{ tipoTexto(r) }} · {{ r.marca }} {{ r.modelo }}</strong><small>Entregada el {{ (r.fecha_entrega ?? r.fecha) | fechaCorta }}</small></span>
            @if (r.presupuesto != null) { <span class="precio">{{ r.presupuesto | euros }}</span> }
          </div>
          </ion-card>
        }
        </ion-list>
      }

      @if (!enCurso().length && !entregadas().length) {
        <app-estado icono="build-outline" titulo="Aún no tienes reparaciones" texto="Cuando nos traigas algo a reparar, podrás seguirlo desde aquí."
                    boton="Pedir una reparación" (accion)="pedirReparacion()"></app-estado>
      }
    }
  }
</ion-content>
JUEGALMI_EOF

mkdir -p $(dirname src/app/pages/taller/taller.page.scss)
cat > src/app/pages/taller/taller.page.scss <<'JUEGALMI_EOF'
// Barra de pasos turquesa
.pasos {
  display: grid; grid-template-columns: repeat(3, 1fr); gap: 8px; margin: 10px 0 26px;
  span { height: 6px; border-radius: 3px; background: var(--jg-segmento); transition: background .3s; }
  .hecho { background: var(--jg-acento); }
}

// Rejilla de dispositivos 4×2
.tipos { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 10px; }
.tipo {
  display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 8px;
  aspect-ratio: 1; border: 0; border-radius: 20px;
  background: var(--jg-tarjeta); color: var(--ion-text-color); font: inherit;
  ion-icon { font-size: 28px; }
  span { font-size: 12px; }
  &.activo { background: var(--jg-acento); color: #1f2329; }
}

.etiqueta { display: block; margin: 26px 0 10px; font-size: 16px; font-weight: 600; }
ion-textarea { min-height: 130px; }

// Fotos de la cámara
.fotos { display: flex; gap: 10px; flex-wrap: wrap; }
.foto, .hacer-foto { width: 96px; height: 96px; border-radius: 18px; }
.foto {
  position: relative; overflow: hidden;
  img { width: 100%; height: 100%; object-fit: cover; }
  button {
    position: absolute; top: 6px; right: 6px; width: 26px; height: 26px; border: 0; border-radius: 50%;
    background: rgba(0, 0, 0, .6); color: #ffffff; display: flex; align-items: center; justify-content: center;
  }
}
.hacer-foto {
  display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 6px;
  border: 2px dashed var(--jg-acento); background: var(--jg-acento-suave);
  color: var(--ion-text-color); font: inherit; font-size: 13px;
  ion-icon { font-size: 26px; }
}
.nota { margin: 12px 0 0; color: var(--jg-texto-sec); font-size: 14px; }

// Error único encima del botón (caja roja, como Android)
.caja-error {
  margin: 24px 0 0; padding: 12px 16px; border-radius: 14px;
  background: #f4e4e9; color: #a72144; font-size: 14px;
}
.continuar { margin-top: 18px; }

// Mis reparaciones
.reparacion {
  display: flex; flex-direction: column; align-items: flex-start; gap: 6px;
  width: 100%; padding: 20px; margin-bottom: 14px; border: 0;
  color: var(--ion-text-color); font: inherit; text-align: left;
  .numero { color: var(--jg-texto-sec); font-size: 14px; }
  strong { font-size: 19px; font-weight: 700; letter-spacing: -0.02em; }
  .estado { display: flex; align-items: center; gap: 6px; width: 100%; justify-content: space-between; font-size: 15px; }
  .barra { display: grid; grid-template-columns: repeat(5, 1fr); gap: 6px; width: 100%; margin-top: 8px; }
  i { height: 5px; border-radius: 3px; background: var(--jg-segmento); }
  i.hecho { background: var(--jg-acento); }
}

// Marca | Modelo
.dos-campos { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 14px; }

// ----- Mis reparaciones (mockup 14)
ion-list.lista ion-card { margin: 0 0 14px; }
.en-curso, .entregada {
  width: 100%; border: 0;
  color: var(--ion-text-color); font: inherit; text-align: left;
  .textos { flex-grow: 1; display: flex; flex-direction: column; gap: 4px; min-width: 0; }
  strong { font-size: 17px; font-weight: 600; }
  small { color: var(--jg-texto-sec); font-size: 15px; }
}
.en-curso {
  display: flex; flex-direction: column; padding: 20px;
  .arriba { display: flex; align-items: center; gap: 18px; padding-bottom: 18px; border-bottom: 1px solid var(--jg-borde); }
  .arriba > ion-icon { color: var(--jg-texto-sec); }
  .dato { display: flex; justify-content: space-between; padding-top: 12px; font-size: 16px; }
  .dato span:first-child { color: var(--jg-texto-sec); }
}
.progreso {
  position: relative; width: 62px; height: 62px; flex-shrink: 0;
  svg { width: 100%; height: 100%; transform: rotate(-90deg); }
  circle { fill: none; stroke-width: 5; }
  .pista { stroke: var(--jg-acento-suave); }
  .valor { stroke: #4fb2b6; stroke-linecap: round; }
  b { position: absolute; inset: 0; display: flex; align-items: center; justify-content: center; font-size: 16px; }
}
.entregada {
  display: flex; align-items: center; gap: 16px; padding: 18px 20px;
  > ion-icon { font-size: 24px; color: var(--jg-texto-sec); flex-shrink: 0; }
  .precio { font-size: 16px; white-space: nowrap; }
}
JUEGALMI_EOF

mkdir -p $(dirname src/app/pages/taller/taller.page.ts)
cat > src/app/pages/taller/taller.page.ts <<'JUEGALMI_EOF'
import { Component, computed, inject, signal } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { concatMap, from, last, of, switchMap } from 'rxjs';
import { IonHeader, IonContent, IonSegment, IonSegmentButton, IonLabel, IonIcon, IonInput, IonTextarea,
         IonChip, IonButton, IonSkeletonText, ToastController, IonList, IonCard } from '@ionic/angular';
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

// Los 13 componentes, siempre los mismos y en este orden (igual que Android)
const COMPONENTES = ['Pantalla', 'Batería', 'Puerto de carga', 'HDMI', 'Ventilador', 'Placa base', 'Joystick',
                     'Botones', 'Lector de discos', 'Altavoz / micro', 'Cámara', 'Software', 'No lo sé'];

@Component({
  selector: 'app-taller',
  templateUrl: './taller.page.html',
  styleUrls: ['./taller.page.scss'],
  imports: [IonList, IonCard, IonHeader, IonContent, IonSegment, IonSegmentButton, IonLabel, IonIcon, IonInput, IonTextarea,
            IonChip, IonButton, IonSkeletonText, CabeceraComponent, EstadoComponent, EurosPipe, FechaCortaPipe],
})
export class TallerPage {
  private sesion = inject(SesionService);
  private reparaciones = inject(ReparacionService);
  private fotos = inject(FotoService);
  private router = inject(Router);
  private ruta = inject(ActivatedRoute);
  private toast = inject(ToastController);

  vista = signal<'nueva' | 'mis'>('nueva');

  // ----- Formulario en una sola pantalla (estado con signals)
  intentado = signal(false);                 // true al pulsar Continuar → muestra el error
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

  componentes = COMPONENTES;

  // Barra de 3 partes: cada una se pone turquesa cuando su zona del formulario está completa
  parte1 = computed(() => !!this.tipo());
  parte2 = computed(() => !!this.marca().trim() && !!this.modelo().trim());
  parte3 = computed(() => !!this.componente() && this.descripcion().trim().length >= 10);

  // Un solo mensaje, en el orden de la pantalla (los mismos textos que Android)
  error = computed(() => {
    if (!this.parte1()) return 'Elige qué tipo de dispositivo es.';
    if (!this.parte2()) return 'Escribe la marca y el modelo.';
    if (!this.componente()) return 'Elige el componente afectado (o «No lo sé»).';
    if (this.descripcion().trim().length < 10) return 'Describe el problema con al menos 10 caracteres.';
    return '';
  });

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
  }

  // «Continuar»: valida y envía
  continuar(): void {
    this.intentado.set(true);
    if (this.error()) return;
    this.enviar();
  }

  pedirReparacion(): void {
    this.vista.set('nueva');
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
  private enviar(): void {
    const tipo = this.tipo();
    if (!tipo) return;
    this.enviando.set(true);
    const componente = this.componente() === 'No lo sé' ? undefined : this.componente();   // el texto del chip; «No lo sé» no se envía

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
      next: () => {
        this.enviando.set(false);
        this.reiniciar();
        this.aviso('Solicitud enviada. Te avisaremos cuando la revisemos.', 'dark');
        this.vista.set('mis');                                   // a la pestaña «Mis reparaciones»
        this.cargarMias();
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
    this.intentado.set(false); this.tipo.set(null);
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
    <!-- Rejilla de 2 columnas · cada producto es un ion-card (CardView) -->
    <div class="rejilla cascada">
      @for (p of productos(); track p.id) {
        <ion-card class="producto pulsable" [class.agotado]="stock(p)?.agotado" (click)="abrir(p)">
          <span class="foto">
            <app-miniatura-producto [producto]="p" [sinMarca]="p.tipo === 'videojuego'"></app-miniatura-producto>
            @if (p.tipo === 'videojuego') { <app-plataformas class="columna" [producto]="p"></app-plataformas> }
            @if (stock(p); as e) { <span class="stock" [class.aviso]="!e.agotado">{{ e.texto }}</span> }
          </span>
          <span class="nombre">{{ p.nombre }}</span>
          @if (modo() === 'alquilar') { <app-precio [valor]="p.precio_alquiler_dia ?? 0" sufijo="/ día"></app-precio> }
          @else { <app-precio [valor]="p.precio_venta"></app-precio> }
        </ion-card>
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

// ion-card sin fondo ni sombra: la tarjeta es la portada
.producto { --background: transparent; --color: var(--ion-text-color); margin: 0; box-shadow: none; border-radius: 0; overflow: visible; text-align: left; }

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
// Agotado / alquilado: la tarjeta en gris pero se puede abrir (para llegar a «Avísame»);
// las píldoras de plataforma mantienen su color
.producto.agotado {
  app-miniatura-producto, .nombre, app-precio { opacity: .55; filter: grayscale(1); }
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
         IonSkeletonText, IonInfiniteScroll, IonInfiniteScrollContent, InfiniteScrollCustomEvent, ToastController, IonCard } from '@ionic/angular';
import { addIcons } from 'ionicons';
import { searchOutline, closeOutline, micOutline } from 'ionicons/icons';
import { CabeceraComponent } from '../../components/cabecera/cabecera.component';
import { MiniaturaProductoComponent } from '../../components/miniatura-producto/miniatura-producto.component';
import { PrecioComponent } from '../../components/precio/precio.component';
import { PlataformasComponent } from '../../components/plataformas/plataformas.component';
import { ProductoService } from '../../services/producto.service';
import { VozService } from '../../services/voz.service';
import { Producto, TipoProducto, avisoStock } from '../../models/producto.model';
import { EstadoComponent } from '../../components/estado/estado.component';

type Modo = 'comprar' | 'alquilar';
interface Filtro { etiqueta: string; valor: string; }   // valor '' = todos

const POR_PAGINA = 8;   // carga progresiva

@Component({
  selector: 'app-tienda',
  templateUrl: './tienda.page.html',
  styleUrls: ['./tienda.page.scss'],
  imports: [IonCard, IonHeader, IonContent, IonSegment, IonSegmentButton, IonLabel, IonSearchbar, IonChip, IonIcon,
            IonSkeletonText, IonInfiniteScroll, IonInfiniteScrollContent,
            CabeceraComponent, MiniaturaProductoComponent, PrecioComponent, EstadoComponent, PlataformasComponent],
})
export class TiendaPage {
  private servicio = inject(ProductoService);
  private router = inject(Router);
  voz = inject(VozService);
  private toast = inject(ToastController);

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
      // Por si la API aún manda «Multi» (ya no existe: cada juego viene una vez por plataforma)
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

  // Micrófono: «ir a la cesta», «mis pedidos»... cambian de pantalla; cualquier otra cosa se busca
  async buscarPorVoz(): Promise<void> {
    const texto = await this.voz.escuchar();
    if (!texto) return;
    const orden = this.voz.orden(texto);
    if (orden) {
      this.avisoVoz(`Abriendo ${orden.texto}`);
      this.router.navigate([orden.ruta], { queryParams: orden.query });
      return;
    }
    this.buscando.set(true);
    this.buscar(texto);
  }

  private async avisoVoz(mensaje: string): Promise<void> {
    const t = await this.toast.create({ message: '🎤 ' + mensaje, duration: 1500, position: 'top', color: 'dark' });
    await t.present();
  }

  buscar(texto: string | null | undefined): void {
    this.texto.set(texto ?? '');
    this.cargar();
  }

  cargarMas(evento: InfiniteScrollCustomEvent): void {
    this.cargar(false, evento);
  }

  // Comprar: unidades en stock · Alquilar: copias libres
  stock(p: Producto) {
    return avisoStock(p, this.modo() === 'alquilar');
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

mkdir -p $(dirname src/app/tabs/tabs.page.scss)
cat > src/app/tabs/tabs.page.scss <<'JUEGALMI_EOF'
// Barra flotante redondeada
ion-tab-bar {
  --background: #1f2329;                // barra oscura (mockup final)
  --border: 0;
  height: 56px;                         // como Android
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
  height: 44px;                         // como Android
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

mkdir -p $(dirname src/app/tabs/tabs.routes.ts)
cat > src/app/tabs/tabs.routes.ts <<'JUEGALMI_EOF'
import { Routes } from '@angular/router';
import { TabsPage } from './tabs.page';

export const routes: Routes = [
  {
    path: '',
    component: TabsPage,
    children: [
      // Pestañas de la barra inferior
      { path: 'inicio',   loadComponent: () => import('../pages/home/home.page').then(m => m.HomePage) },
      { path: 'tienda',   loadComponent: () => import('../pages/tienda/tienda.page').then(m => m.TiendaPage) },
      { path: 'taller',   loadComponent: () => import('../pages/taller/taller.page').then(m => m.TallerPage) },
      { path: 'taller/reparacion/:id', loadComponent: () => import('../pages/reparacion/reparacion.page').then(m => m.ReparacionPage) },
      { path: 'cesta',    loadComponent: () => import('../pages/cesta/cesta.page').then(m => m.CestaPage) },
      { path: 'nosotros', loadComponent: () => import('../pages/nosotros/nosotros.page').then(m => m.NosotrosPage) },

    ],
  },
];
JUEGALMI_EOF

mkdir -p $(dirname src/app/validators/validadores.spec.ts)
cat > src/app/validators/validadores.spec.ts <<'JUEGALMI_EOF'
import { describe, it, expect } from 'vitest';
import { FormControl, Validators } from '@angular/forms';
import { dniValido, telefonoValido, textoError, OBLIGATORIO } from './validadores';

// Ayuda: ejecuta un validador sobre un valor y devuelve el error (o null si es válido)
const validar = (validador: typeof dniValido, valor: string) => validador(new FormControl(valor));

describe('Validador de DNI', () => {
  it('acepta un DNI con la letra correcta', () => {
    expect(validar(dniValido, '12345678Z')).toBeNull();
  });

  it('acepta minúsculas y espacios alrededor', () => {
    expect(validar(dniValido, ' 12345678z ')).toBeNull();
  });

  it('rechaza un DNI con la letra equivocada', () => {
    expect(validar(dniValido, '12345678A')).toEqual({ dni: true });
  });

  it('rechaza un DNI con menos de 8 números', () => {
    expect(validar(dniValido, '1234567Z')).toEqual({ dni: true });
  });

  it('no da error si está vacío (eso lo comprueba "required")', () => {
    expect(validar(dniValido, '')).toBeNull();
  });

  it('acepta un NIE válido (la API admite X1234567L)', () => {
    expect(validar(dniValido, 'X1234567L')).toBeNull();
  });

  it('rechaza un NIE con letra incorrecta', () => {
    expect(validar(dniValido, 'X1234567A')).toEqual({ dni: true });
  });
});

describe('Validador de teléfono', () => {
  it('acepta un móvil de 9 cifras', () => {
    expect(validar(telefonoValido, '600111222')).toBeNull();
  });

  it('acepta un fijo y espacios entre cifras', () => {
    expect(validar(telefonoValido, '944 000 102')).toBeNull();
  });

  it('rechaza menos de 9 cifras', () => {
    expect(validar(telefonoValido, '60011122')).toEqual({ telefono: true });
  });

  it('rechaza si no empieza por 6, 7, 8 o 9', () => {
    expect(validar(telefonoValido, '500111222')).toEqual({ telefono: true });
  });
});

describe('Mensajes de los formularios (los de Android)', () => {
  it('vacío → «Este campo es obligatorio»; mal escrito → el concreto', () => {
    const vacio = new FormControl('', Validators.required);
    const mal = new FormControl('12', [Validators.required, Validators.pattern(/^\d{5}$/)]);
    expect(textoError(vacio, 'El código postal tiene 5 números')).toBe(OBLIGATORIO);
    expect(textoError(mal, 'El código postal tiene 5 números')).toBe('El código postal tiene 5 números');
  });
});
JUEGALMI_EOF

mkdir -p $(dirname src/app/validators/validadores.ts)
cat > src/app/validators/validadores.ts <<'JUEGALMI_EOF'
import { AbstractControl, ValidationErrors, ValidatorFn } from '@angular/forms';

const LETRAS = 'TRWAGMYFPDXBNJZSQVHLCKE';

// DNI (12345678Z) o NIE (X1234567L) con la letra correcta, como pide la API
export const dniValido: ValidatorFn = (c: AbstractControl): ValidationErrors | null => {
  const valor = String(c.value ?? '').trim().toUpperCase();
  if (!valor) return null;                                   // el "required" se comprueba aparte
  if (!/^[XYZ\d]\d{7}[A-Z]$/.test(valor)) return { dni: true };
  const numero = valor.slice(0, 8).replace('X', '0').replace('Y', '1').replace('Z', '2');   // NIE → número
  return LETRAS[Number(numero) % 23] === valor[8] ? null : { dni: true };
};

// Teléfono español: 9 cifras empezando por 6, 7, 8 o 9
export const telefonoValido: ValidatorFn = (c: AbstractControl): ValidationErrors | null => {
  const valor = String(c.value ?? '').replace(/\s/g, '');
  if (!valor) return null;
  return /^[6789]\d{8}$/.test(valor) ? null : { telefono: true };
};

// Mensajes de los formularios (los mismos que Android): genérico si está vacío, concreto si el formato está mal
export const OBLIGATORIO = 'Este campo es obligatorio';
export function textoError(control: AbstractControl, formato = OBLIGATORIO): string {
  return control.hasError('required') ? OBLIGATORIO : formato;
}
JUEGALMI_EOF

mkdir -p $(dirname src/global.scss)
cat > src/global.scss <<'JUEGALMI_EOF'
// Fuente Roboto local, la de Android (en iPhone no viene instalada)
@import "@fontsource/roboto/400.css";
@import "@fontsource/roboto/500.css";
@import "@fontsource/roboto/700.css";

// CSS base de Ionic
@import "@ionic/angular/css/core.css";
@import "@ionic/angular/css/normalize.css";
@import "@ionic/angular/css/structure.css";
@import "@ionic/angular/css/typography.css";
@import "@ionic/angular/css/display.css";
@import "@ionic/angular/css/padding.css";
@import "@ionic/angular/css/float-elements.css";
@import "@ionic/angular/css/text-alignment.css";
@import "@ionic/angular/css/text-transformation.css";
@import "@ionic/angular/css/flex-utils.css";

// Colores DESPUÉS del CSS de Ionic (si no, Ionic los pisa)
@import "./theme/variables.scss";

// Mapa (Leaflet)
@import "leaflet/dist/leaflet.css";

body { background: var(--ion-background-color); }
ion-content { --padding-start: 20px; --padding-end: 20px; --padding-bottom: 110px; }  // hueco para la barra flotante

// Títulos grandes y apretados ("Hola, Ane", "Tienda", "Cesta")
.titulo {
  margin: 6px 0 22px;
  font-size: 40px;
  line-height: 1.05;
  font-weight: 700;
  letter-spacing: -0.05em;
}
h1, h2, h3 { letter-spacing: -0.03em; }

// Tarjeta base
.tarjeta {
  background: var(--jg-tarjeta);
  border-radius: var(--jg-radio);
}

// ion-card con el aspecto de .tarjeta (equivale a CardView)
ion-card.tarjeta {
  --background: var(--jg-tarjeta);
  --color: inherit;
  margin: 0;
  box-shadow: none;
  border-radius: var(--jg-radio);
}

// ion-list transparente (equivale a RecyclerView)
ion-list.lista {
  background: transparent;
  padding: 0;
}

// Cabecera de sección: "Novedades ...... Ver todo"
.seccion {
  display: flex; align-items: center; justify-content: space-between;
  margin: 26px 0 12px;
  h2 { margin: 0; font-size: 20px; font-weight: 700; }
  a { color: var(--jg-texto-sec); font-size: 15px; text-decoration: none; }
}

// Botones en píldora
ion-button {
  --border-radius: 999px;
  --box-shadow: none;
  min-height: 48px;
  text-transform: none;
  font-weight: 500;
  font-size: 14px;
  letter-spacing: 0;
}

// Botón redondo (volver, buscar)
.redondo {
  width: 46px; height: 46px; border: 0; border-radius: 50%;
  display: inline-flex; align-items: center; justify-content: center;
  background: var(--jg-tarjeta); color: var(--ion-text-color);
  font-size: 22px; box-shadow: var(--jg-sombra);
  ion-icon { font-size: 22px; }
}
ion-toolbar .redondo { box-shadow: none; }
ion-back-button.redondo {
  --color: var(--ion-text-color);
  --icon-font-size: 22px;
  --border-radius: 50%;
  --padding-start: 0; --padding-end: 0;
}

// Segmentos en píldora (Comprar/Alquilar, Ubicación/Historia/Galería)
ion-segment {
  --background: var(--jg-segmento);
  border-radius: 999px;
  padding: 4px;
  margin-bottom: 16px;
}
ion-segment-button {
  --color: var(--jg-texto-sec);
  --color-checked: var(--ion-text-color);
  --indicator-color: transparent;
  --border-radius: 999px;
  --padding-start: 8px;
  --padding-end: 8px;
  min-height: 42px;
  border-radius: 999px;
  text-transform: none;
  letter-spacing: 0;
  font-size: 15px;
  font-weight: 500;
}
ion-segment-button.segment-button-checked {
  background: var(--jg-segmento-activo);
}

// Chips de filtro (fila con scroll horizontal)
.chips {
  display: flex; gap: 8px;
  overflow-x: auto; scrollbar-width: none;
  margin: 0 -20px 18px; padding: 0 20px;
  &::-webkit-scrollbar { display: none; }
  &.envolver { flex-wrap: wrap; overflow: visible; margin: 0 0 18px; padding: 0; }
}
ion-chip.filtro {
  --background: var(--jg-tarjeta);
  --color: var(--ion-text-color);
  flex-shrink: 0;
  height: 40px; margin: 0; padding: 0 16px;
  border-radius: 999px;
  font-size: 15px;
}
ion-chip.filtro.activo {
  --background: var(--jg-inverso);
  --color: var(--jg-inverso-texto);
  font-weight: 600;
}

// Etiquetas pequeñas (Aventura, PEGI 12, Últimas unidades...)
.etiqueta-mini {
  display: inline-flex; align-items: center;
  height: 26px; padding: 0 12px; border-radius: 999px;
  background: var(--jg-tarjeta); color: var(--ion-text-color);
  font-size: 12px; font-weight: 600;
  &.roja { background: var(--ion-color-danger); color: #ffffff; }
}

// Cajas de texto (formularios)
app-login ion-input, app-registro ion-input, app-taller ion-input, app-taller ion-textarea,
app-datos-personales ion-input, app-direcciones ion-input, app-editar-datos ion-input, app-direccion ion-input {
  // !important: Ionic pone sus valores con una clase que pesa más que este selector
  --background: var(--jg-tarjeta) !important;
  --padding-start: 16px !important;
  --padding-end: 16px !important;
  --highlight-color-focused: var(--jg-acento);
  min-height: 44px;
  border: 1px solid var(--jg-borde);
  border-radius: 14px;
  overflow: hidden;
  font-size: 15px;
  &.has-focus { border-color: #375e60; }
  &.mal { border-color: var(--ion-color-danger); }
}
.error { margin: 6px 0 0; color: var(--ion-color-danger); font-size: 13px; }
.vacio { text-align: center; color: var(--jg-texto-sec); margin: 40px 0; }

// Avisos (toast) redondeados por encima de la barra
ion-toast { --border-radius: 18px; --start: 16px; --end: 16px; transform: translateY(-80px); }

// ===================== ANIMACIONES =====================
@keyframes jg-aparecer {
  from { opacity: 0; transform: translateY(14px); }
  to   { opacity: 1; transform: none; }
}
.cascada > * { animation: jg-aparecer .35s ease-out both; }
@for $i from 2 through 10 {
  .cascada > *:nth-child(#{$i}) { animation-delay: #{($i - 1) * 45}ms; }
}

// Igual que Animaciones.aparecer() de Android: entra subiendo 24px
@keyframes jg-subir {
  from { opacity: 0; transform: translateY(24px); }
  to   { opacity: 1; transform: none; }
}
.aparecer { animation: jg-subir .4s cubic-bezier(0, 0, .2, 1) both; }

// Igual que Animaciones.latido(): crece al 108 % y vuelve con rebote
@keyframes jg-latido {
  0%   { transform: scale(1); }
  33%  { transform: scale(1.08); }
  100% { transform: scale(1); }
}
.latido { animation: jg-latido .3s cubic-bezier(.34, 1.56, .64, 1); }

// Respuesta táctil al pulsar
.pulsable { transition: transform .12s ease; cursor: pointer; }
.pulsable:active { transform: scale(.97); }

@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after { animation: none !important; transition: none !important; }
}

// Cuadrado turquesa con la "J"
.logo {
  width: 32px; height: 32px; border-radius: 9px; flex-shrink: 0;
  background: var(--jg-acento); color: #1f2329;
  display: inline-flex; align-items: center; justify-content: center;
  font-size: 18px; font-weight: 700; letter-spacing: 0;
}
JUEGALMI_EOF

mkdir -p $(dirname src/theme/variables.scss)
cat > src/theme/variables.scss <<'JUEGALMI_EOF'
// Guía de estilo JuegAlmi · mockup turquesa (siempre en claro)
:root {
  color-scheme: light;                              // la app siempre en claro
  // Primario: turquesa de la marca (botones, pestaña activa, tarjeta "Lo reparamos")
  --ion-color-primary: #78cdd0;
  --ion-color-primary-rgb: 120, 205, 208;
  --ion-color-primary-contrast: #162525;            // texto oscuro sobre turquesa (igual que Android)
  --ion-color-primary-contrast-rgb: 22, 37, 37;
  --ion-color-primary-shade: #6ab4b7;
  --ion-color-primary-tint: #86d2d5;

  // Dark: avisos (toast) y textos fuertes
  --ion-color-dark: #1f2329;
  --ion-color-dark-rgb: 31, 35, 41;
  --ion-color-dark-contrast: #ffffff;
  --ion-color-dark-contrast-rgb: 255, 255, 255;
  --ion-color-dark-shade: #1b1f24;
  --ion-color-dark-tint: #35393e;

  // Danger: errores y punto rojo de la cesta
  --ion-color-danger: #a72144;
  --ion-color-danger-rgb: 167, 33, 68;
  --ion-color-danger-contrast: #ffffff;
  --ion-color-danger-contrast-rgb: 255, 255, 255;
  --ion-color-danger-shade: #931d3c;
  --ion-color-danger-tint: #b03757;

  // Generales
  --ion-font-family: 'Roboto', system-ui, sans-serif;   // la fuente de Android
  --ion-background-color: #ecf2f1;                  // fondo verde grisáceo
  --ion-background-color-rgb: 236, 242, 241;
  --ion-text-color: #1f2329;
  --ion-text-color-rgb: 31, 35, 41;
  --ion-toolbar-background: var(--ion-background-color);
  --ion-item-background: var(--jg-tarjeta);

  // Propias del proyecto
  --jg-tarjeta: #ffffff;                            // tarjetas
  --jg-texto-sec: #5c616c;                          // textos secundarios
  --jg-gris: #e9ebea;                               // tarjeta "Alquilar", huecos de imagen
  --jg-segmento: #deeeed;                           // fondo de los segmentos
  --jg-segmento-activo: #ffffff;                    // opción activa del segmento
  --jg-inverso: #1f2329;                            // tarjetas oscuras y chips activos
  --jg-inverso-texto: #ffffff;
  --jg-acento: #78cdd0;
  --jg-acento-suave: #eff9f9;                       // círculos de iconos y avatares (Android)
  --jg-borde: rgba(24, 26, 32, 0.16);               // borde de los campos (Android)
  --jg-barra: #ffffff;                              // barra inferior flotante
  --jg-sombra: 0 10px 30px rgba(31, 35, 41, 0.10);
  --jg-radio: 20px;                                // esquinas de las tarjetas (Android)
  --jg-relleno: var(--jg-gris);                     // nombre antiguo (lo usan páginas anteriores)
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
| `validators/validadores.spec.ts` | DNI y NIE (letra correcta/incorrecta, formato, vacío), teléfono (9 cifras, empieza por 6-9, espacios) y mensajes de error de Android | 12 |
| `services/cesta.service.spec.ts` | Cesta: vacía, añadir, sumar cantidad, quitar al llegar a 0, total, guardado en localStorage, vaciar, límite de stock | 7 |
| `models/producto.model.spec.ts` | Etiquetas de stock («Quedan 2», «Última unidad/copia», «Agotado/Alquilado») plataformas de cada juego y su color (PlayStation azul, Xbox verde, Switch rojo) y `avisoStock` (misma regla que Android) | 11 |
| `services/sesion.service.spec.ts` | Foto de perfil: `POST /api/yo/foto` con el campo «imagen» (HTTP simulado) | 1 |
| `components/precio/precio.component.spec.ts` | Precio con céntimos pequeños: 59,99 €, 35,00 €, punto de miles, sufijo "/ día" | 4 |
| `services/voz.service.spec.ts` | Voz de la Tienda: texto a buscar, órdenes («ir a la cesta», «mis pedidos», «quiero alquilar»), «buscar …» siempre busca, navegador sin voz | 9 |
| `pipes/euros.pipe.spec.ts` | Formato en euros y valor vacío | 2 |
| **Total** | | **46** |

Técnicas usadas:
- **TestBed** de Angular para crear servicios y componentes como en la app.
- **Dobles de prueba** (`vi.fn()`) para los avisos (`ToastController`): se comprueba que la app avisa sin mostrar nada en pantalla.
- `localStorage.clear()` antes de cada prueba para que no dependan unas de otras.

Resultado esperado: `Test Files 7 passed (7) · Tests 46 passed (46)`.

Pruebas manuales en dispositivo (no automatizables aquí): cámara, GPS, voz real y agitar el móvil → ver checklist de la defensa.
JUEGALMI_EOF

grep -rl "@ionic/angular/standalone" src | xargs -r sed -i "s#@ionic/angular/standalone#@ionic/angular#g"

echo ""
echo "✔ Paso 25 aplicado: Ionic con el diseño, textos y listas de Android."
echo "  Comprueba: npx ng test --watch=false  (46 pruebas)  y  ionic serve"
