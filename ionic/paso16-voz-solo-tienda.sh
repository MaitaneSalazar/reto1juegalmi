#!/bin/bash
# =====================================================================
# PASO 16 · Buscador por voz SOLO en la Tienda
#   - Fuera el micrófono de la cabecera común (Inicio, Taller, Cesta, Nosotros, Cuenta)
#   - Tienda: micrófono junto a la lupa → lo que dices se escribe en el buscador y se busca
# Uso (desde la carpeta ionic/):   bash paso16-voz-solo-tienda.sh
# =====================================================================
set -e
if [ ! -f angular.json ] || [ ! -f src/app/services/domicilio.service.ts ]; then
  echo "✘ Ejecútalo dentro de ionic/ y con el paso 15 (API real) aplicado"; exit 1
fi
tar czf ../ionic-src-antes-paso16.tgz src COMANDOS-VOZ.md PRUEBAS.md 2>/dev/null || tar czf ../ionic-src-antes-paso16.tgz src
echo "• Copia de seguridad: ../ionic-src-antes-paso16.tgz"

mkdir -p $(dirname src/app/components/cabecera/cabecera.component.ts)
cat > src/app/components/cabecera/cabecera.component.ts <<'JUEGALMI_EOF'
import { Component } from '@angular/core';
import { IonToolbar, IonButtons, IonMenuButton } from '@ionic/angular';

// Cabecera común: ☰ + logo J + JuegAlmi + hueco a la derecha (cada página pone sus botones)
@Component({
  selector: 'app-cabecera',
  templateUrl: './cabecera.component.html',
  styleUrls: ['./cabecera.component.scss'],
  imports: [IonToolbar, IonButtons, IonMenuButton],
})
export class CabeceraComponent {}
JUEGALMI_EOF

mkdir -p $(dirname src/app/components/cabecera/cabecera.component.html)
cat > src/app/components/cabecera/cabecera.component.html <<'JUEGALMI_EOF'
<ion-toolbar>
  <ion-buttons slot="start">
    <ion-menu-button></ion-menu-button>   <!-- ☰ abre el menú lateral -->
  </ion-buttons>
  <div class="marca"><span class="logo">J</span>JuegAlmi</div>
  <ion-buttons slot="end">
    <ng-content></ng-content>             <!-- p. ej. micrófono y lupa en Tienda -->
  </ion-buttons>
</ion-toolbar>
JUEGALMI_EOF

mkdir -p $(dirname src/app/components/cabecera/cabecera.component.scss)
cat > src/app/components/cabecera/cabecera.component.scss <<'JUEGALMI_EOF'
:host { display: block; }

ion-toolbar {
  --background: transparent;
  --border-width: 0;
  --min-height: 64px;
  padding: 0 10px 0 6px;
}
ion-menu-button { --color: var(--ion-text-color); font-size: 26px; }

.marca {
  display: flex; align-items: center; gap: 10px;
  font-size: 24px; font-weight: 700; letter-spacing: -0.04em;
}

ion-buttons[slot="end"] { gap: 8px; }
JUEGALMI_EOF

mkdir -p $(dirname src/app/services/voz.service.ts)
cat > src/app/services/voz.service.ts <<'JUEGALMI_EOF'
import { Injectable, inject, signal } from '@angular/core';
import { Capacitor } from '@capacitor/core';
import { SpeechRecognition } from '@capacitor-community/speech-recognition';
import { ToastController } from '@ionic/angular';

// Buscador por voz de la Tienda: escucha una frase y devuelve el texto a buscar
@Injectable({ providedIn: 'root' })
export class VozService {
  private toast = inject(ToastController);

  escuchando = signal(false);              // el micrófono está abierto (anima el botón)

  // Botón del micrófono: devuelve lo que se ha dicho ("" si no se ha entendido)
  async escuchar(): Promise<string> {
    if (this.escuchando()) return '';
    this.escuchando.set(true);
    try {
      const frase = Capacitor.isNativePlatform() ? await this.escucharNativo() : await this.escucharWeb();
      const texto = this.textoBusqueda(frase);
      if (!texto) this.aviso('No te he oído. Pulsa el micrófono y di, por ejemplo, «Zelda».');
      return texto;
    } catch (e) {
      this.aviso(e instanceof Error ? e.message : 'No te he entendido. Inténtalo otra vez.');
      return '';
    } finally {
      this.escuchando.set(false);
    }
  }

  // "Buscar Zelda." → "zelda" · "¿Tenéis la PlayStation?" → "tenéis la playstation"
  textoBusqueda(frase: string): string {
    return frase.toLowerCase()
      .replace(/[¿?¡!.,]/g, '')                    // sin signos
      .replace(/^\s*(buscar|busca|busco)\s+/, '')  // sin la palabra "buscar" del principio
      .trim();
  }

  // ----- Móvil (Android / iOS): plugin de Capacitor
  private async escucharNativo(): Promise<string> {
    const { available } = await SpeechRecognition.available();
    if (!available) throw new Error('El reconocimiento de voz no está disponible en este móvil.');
    const permiso = await SpeechRecognition.requestPermissions();
    if (permiso.speechRecognition !== 'granted') throw new Error('Necesito permiso de micrófono para entenderte.');
    const r = await SpeechRecognition.start({
      language: 'es-ES', maxResults: 1, prompt: '¿Qué buscas?',
      partialResults: false, popup: true,          // ventana de Google en Android
    });
    return r.matches?.[0] ?? '';
  }

  // ----- Navegador: Web Speech API (Chrome, Edge y Safari; Firefox no la tiene)
  private escucharWeb(): Promise<string> {
    const w = window as unknown as Record<string, any>;
    const Reconocedor = w['SpeechRecognition'] ?? w['webkitSpeechRecognition'];
    if (!Reconocedor) {
      return Promise.reject(new Error('Este navegador no permite buscar por voz. Prueba con Chrome o con la app.'));
    }
    return new Promise((resolver, rechazar) => {
      const rec = new Reconocedor();
      rec.lang = 'es-ES';
      rec.interimResults = false;
      rec.maxAlternatives = 1;
      rec.onresult = (e: any) => resolver(e.results[0][0].transcript);
      rec.onerror = (e: any) => rechazar(new Error(e.error === 'not-allowed'
        ? 'Permite el micrófono para buscar por voz.'
        : 'No te he entendido. Inténtalo otra vez.'));
      rec.onend = () => resolver('');             // terminó sin oír nada
      rec.start();
      setTimeout(() => { rec.abort?.(); resolver(''); }, 8000);   // seguridad: nunca se queda escuchando para siempre
    });
  }

  private async aviso(mensaje: string): Promise<void> {
    const t = await this.toast.create({ message: mensaje, duration: 2500, position: 'top', color: 'dark' });
    await t.present();
  }
}
JUEGALMI_EOF

mkdir -p $(dirname src/app/services/voz.service.spec.ts)
cat > src/app/services/voz.service.spec.ts <<'JUEGALMI_EOF'
import { describe, it, expect, beforeEach, vi } from 'vitest';
import { TestBed } from '@angular/core/testing';
import { ToastController } from '@ionic/angular';
import { VozService } from './voz.service';

describe('VozService (buscador por voz de la Tienda)', () => {
  let voz: VozService;
  const toast = { create: vi.fn().mockResolvedValue({ present: vi.fn() }) };

  beforeEach(() => {
    vi.clearAllMocks();
    TestBed.configureTestingModule({ providers: [{ provide: ToastController, useValue: toast }] });
    voz = TestBed.inject(VozService);
  });

  it('«Zelda» busca "zelda"', () => {
    expect(voz.textoBusqueda('Zelda')).toBe('zelda');
  });

  it('quita la palabra «buscar» del principio', () => {
    expect(voz.textoBusqueda('Buscar PlayStation 5')).toBe('playstation 5');
    expect(voz.textoBusqueda('busca Elden Ring')).toBe('elden ring');
  });

  it('quita los signos de la frase', () => {
    expect(voz.textoBusqueda('¿Mario Kart?')).toBe('mario kart');
  });

  it('una frase vacía no busca nada', () => {
    expect(voz.textoBusqueda('   ')).toBe('');
  });

  it('en un navegador sin voz avisa y devuelve ""', async () => {
    const w = window as unknown as Record<string, unknown>;
    delete w['SpeechRecognition'];
    delete w['webkitSpeechRecognition'];
    expect(await voz.escuchar()).toBe('');
    expect(toast.create).toHaveBeenCalled();
    expect(voz.escuchando()).toBe(false);
  });
});
JUEGALMI_EOF

mkdir -p $(dirname src/app/pages/tienda/tienda.page.ts)
cat > src/app/pages/tienda/tienda.page.ts <<'JUEGALMI_EOF'
import { Component, computed, inject, signal } from '@angular/core';
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
import { Producto, TipoProducto } from '../../models/producto.model';

type Modo = 'comprar' | 'alquilar';
interface Filtro { etiqueta: string; valor: string; }   // valor '' = todos

const POR_PAGINA = 8;   // carga progresiva

@Component({
  selector: 'app-tienda',
  templateUrl: './tienda.page.html',
  styleUrls: ['./tienda.page.scss'],
  imports: [IonHeader, IonContent, IonSegment, IonSegmentButton, IonLabel, IonSearchbar, IonChip, IonIcon,
            IonSkeletonText, IonInfiniteScroll, IonInfiniteScrollContent,
            CabeceraComponent, MiniaturaProductoComponent, PrecioComponent],
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
  hayMas = signal(true);

  // El primero va en grande; el resto, en rejilla de 2
  destacado = computed(() => this.productos()[0] ?? null);
  resto = computed(() => this.productos().slice(1));

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

  abrir(p: Producto): void {
    this.router.navigate(['/producto', p.id], { queryParams: { modo: this.modo() } });
  }

  private cargar(reiniciar = true, evento?: InfiniteScrollCustomEvent): void {
    if (reiniciar) {
      this.pagina = 1;
      this.cargando.set(true);
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
        this.cargando.set(false);
        evento?.target.complete();
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

  @if (cargando()) {
    <ion-skeleton-text [animated]="true" class="esq-grande"></ion-skeleton-text>
    <div class="rejilla">
      @for (i of [1, 2]; track i) { <ion-skeleton-text [animated]="true" class="esq-peque"></ion-skeleton-text> }
    </div>
  } @else {
    <!-- Producto destacado -->
    @if (destacado(); as p) {
      <button type="button" class="destacado pulsable" (click)="abrir(p)">
        <span class="escaparate">
          <app-miniatura-producto [producto]="p"></app-miniatura-producto>
          @if (p.alquilado) { <span class="etiqueta-mini">Alquilado</span> }
        </span>
        <span class="pie">
          <span class="nombre">{{ p.nombre }}</span>
          @if (modo() === 'alquilar') { <app-precio [valor]="p.precio_alquiler_dia ?? 0" sufijo="/ día"></app-precio> }
          @else { <app-precio [valor]="p.precio_venta"></app-precio> }
        </span>
      </button>
    }

    <!-- Resto en rejilla de 2 -->
    <div class="rejilla cascada">
      @for (p of resto(); track p.id) {
        <button type="button" class="producto pulsable" (click)="abrir(p)">
          <span class="foto">
            <app-miniatura-producto [producto]="p"></app-miniatura-producto>
            @if (p.alquilado) { <span class="etiqueta-mini">Alquilado</span> }
          </span>
          <span class="nombre">{{ p.nombre }}</span>
          @if (modo() === 'alquilar') { <app-precio [valor]="p.precio_alquiler_dia ?? 0" sufijo="/ día"></app-precio> }
          @else { <app-precio [valor]="p.precio_venta"></app-precio> }
        </button>
      }
    </div>

    @if (!productos().length) { <p class="vacio">No hay productos que coincidan.</p> }

    <ion-infinite-scroll [disabled]="!hayMas()" (ionInfinite)="cargarMas($event)">
      <ion-infinite-scroll-content loadingSpinner="crescent"></ion-infinite-scroll-content>
    </ion-infinite-scroll>
  }
</ion-content>
JUEGALMI_EOF

mkdir -p $(dirname src/app/pages/tienda/tienda.page.scss)
cat > src/app/pages/tienda/tienda.page.scss <<'JUEGALMI_EOF'
ion-searchbar { --background: var(--jg-tarjeta); --border-radius: 999px; --box-shadow: none; padding: 0 0 14px; }

.destacado, .producto { border: 0; padding: 0; background: none; font: inherit; color: var(--ion-text-color); text-align: left; }

// Destacado: foto grande con degradado
.destacado { display: block; width: 100%; margin-bottom: 22px; }
.escaparate {
  position: relative; display: flex; align-items: center; justify-content: center;
  height: 280px; border-radius: 28px; overflow: hidden;
  background: radial-gradient(circle at 50% 40%, #a9c3c2 0%, #6f8584 100%);

  app-miniatura-producto { --tam: 172px; --radio: 12px; --fondo: rgba(255, 255, 255, .25); --icono: 56px;
                           height: 236px; box-shadow: 0 16px 40px rgba(0, 0, 0, .25); }
}
.pie { display: flex; align-items: baseline; justify-content: space-between; gap: 12px; margin-top: 12px; }
.nombre { font-size: 16px; font-weight: 500; }
.destacado app-precio { font-size: 22px; }

// Rejilla de 2 columnas
.rejilla { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 14px; }
.producto {
  display: flex; flex-direction: column; gap: 6px; min-width: 0;
  .nombre { font-size: 15px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; margin-top: 4px; }
  app-precio { font-size: 22px; }
}
.foto {
  position: relative; display: block; aspect-ratio: 4 / 5;
  app-miniatura-producto { --tam: 100%; --radio: 22px; --fondo: var(--jg-tarjeta); --icono: 46px; width: 100%; height: 100%; }
}
.foto .etiqueta-mini, .escaparate .etiqueta-mini { position: absolute; top: 12px; left: 12px; }

.esq-grande { height: 280px; border-radius: 28px; margin-bottom: 22px; }
.esq-peque { height: 220px; border-radius: 22px; }

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

      // Cuenta ya no es pestaña, pero sigue accesible (enlaces del menú)
      { path: 'cuenta',   loadComponent: () => import('../pages/cuenta/cuenta.page').then(m => m.CuentaPage) },
      { path: 'cuenta/notificaciones', loadComponent: () => import('../pages/notificaciones/notificaciones.page').then(m => m.NotificacionesPage) },
      { path: 'cuenta/ajustes',        loadComponent: () => import('../pages/ajustes/ajustes.page').then(m => m.AjustesPage) },
      { path: 'cuenta/ayuda',          loadComponent: () => import('../pages/ayuda/ayuda.page').then(m => m.AyudaPage) },
    ],
  },
];
JUEGALMI_EOF

mkdir -p $(dirname COMANDOS-VOZ.md)
cat > COMANDOS-VOZ.md <<'JUEGALMI_EOF'
# Buscador por voz y acelerómetro (JuegAlmi · Ionic)

## Buscador por voz (solo en la Tienda)
En **Tienda** pulsa el **micrófono** (junto a la lupa) y di lo que buscas:

| Di… | Busca |
|---|---|
| «Zelda» | zelda |
| «Buscar PlayStation 5» | playstation 5 (se quita la palabra «buscar») |
| «¿Elden Ring?» | elden ring (se quitan los signos) |

- Lo dicho se escribe en el buscador y se piden los productos a la API (`GET /api/productos?q=...`). En modo Alquilar filtra los juegos de alquiler.
- Mientras escucha, el micrófono se pone turquesa y late. Si no oye nada en 8 segundos, se cierra solo.
- En el móvil usa el reconocedor de voz del sistema (plugin `@capacitor-community/speech-recognition`, ventana «¿Qué buscas?»).
- En el navegador usa la Web Speech API (Chrome, Edge, Safari; **Firefox no la tiene**).

## Acelerómetro
- `@capacitor/motion`: agitar el móvil recarga la pantalla actual. La sesión y la cesta se conservan.
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
| `services/cesta.service.spec.ts` | Cesta: vacía, añadir, sumar cantidad, quitar al llegar a 0, total, guardado en localStorage, vaciar | 6 |
| `components/precio/precio.component.spec.ts` | Precio con céntimos pequeños: 59,99 €, 35,00 €, punto de miles, sufijo "/ día" | 4 |
| `services/voz.service.spec.ts` | Buscador por voz de la Tienda: texto a buscar, quitar «buscar» y signos, frase vacía, navegador sin voz | 5 |
| `pipes/euros.pipe.spec.ts` | Formato en euros y valor vacío | 2 |
| **Total** | | **28** |

Técnicas usadas:
- **TestBed** de Angular para crear servicios y componentes como en la app.
- **Dobles de prueba** (`vi.fn()`) para los avisos (`ToastController`): se comprueba que la app avisa sin mostrar nada en pantalla.
- `localStorage.clear()` antes de cada prueba para que no dependan unas de otras.

Resultado esperado: `Test Files 5 passed (5) · Tests 28 passed (28)`.

Pruebas manuales en dispositivo (no automatizables aquí): cámara, GPS, voz real y agitar el móvil → ver checklist de la defensa.
JUEGALMI_EOF

grep -rl "@ionic/angular/standalone" src | xargs -r sed -i "s#@ionic/angular/standalone#@ionic/angular#g"

echo ""
echo "✔ Paso 16 aplicado: el micrófono solo está en la Tienda y sirve para buscar por voz."
echo "  Prueba: ionic serve → Tienda → micrófono → di «Zelda»   (en Chrome; Firefox no tiene voz)"
