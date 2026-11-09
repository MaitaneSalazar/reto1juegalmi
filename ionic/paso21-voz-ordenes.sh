#!/bin/bash
# =====================================================================
# PASO 21 · Control por voz de distintas partes de la app (rúbrica)
#   El micrófono sigue solo en la Tienda: si dices una orden («ir a la cesta», «mis pedidos»,
#   «quiero alquilar», «taller», «dónde estáis»…) cambia de pantalla; si no, busca.
# Uso (desde la carpeta ionic/):   bash paso21-voz-ordenes.sh
# =====================================================================
set -e
if [ ! -f angular.json ] || [ ! -f src/app/pipes/nombre-producto.pipe.ts ]; then
  echo "✘ Ejecútalo dentro de ionic/ y con el paso 20 aplicado"; exit 1
fi
mkdir -p ~/Escritorio/copias-ionic
tar czf ~/Escritorio/copias-ionic/ionic-src-antes-paso21.tgz src PRUEBAS.md COMANDOS-VOZ.md
echo "• Copia de seguridad: ~/Escritorio/copias-ionic/ionic-src-antes-paso21.tgz"

mkdir -p $(dirname src/app/pages/tienda/tienda.page.ts)
cat > src/app/pages/tienda/tienda.page.ts <<'JUEGALMI_EOF'
import { Component, inject, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { ActivatedRoute, Router } from '@angular/router';
import { IonHeader, IonContent, IonSegment, IonSegmentButton, IonLabel, IonSearchbar, IonChip, IonIcon,
         IonSkeletonText, IonInfiniteScroll, IonInfiniteScrollContent, InfiniteScrollCustomEvent, ToastController } from '@ionic/angular';
import { addIcons } from 'ionicons';
import { searchOutline, closeOutline, micOutline } from 'ionicons/icons';
import { CabeceraComponent } from '../../components/cabecera/cabecera.component';
import { MiniaturaProductoComponent } from '../../components/miniatura-producto/miniatura-producto.component';
import { PrecioComponent } from '../../components/precio/precio.component';
import { PlataformasComponent } from '../../components/plataformas/plataformas.component';
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

  it('«Ir a la cesta» abre la cesta', () => {
    expect(voz.orden('Ir a la cesta')?.ruta).toBe('/cesta');
  });

  it('«Abre mis pedidos» y «mis alquileres» (con o sin tildes)', () => {
    expect(voz.orden('Abre mis pedidos')?.ruta).toBe('/cuenta/pedidos');
    expect(voz.orden('Mis alquileres')?.ruta).toBe('/cuenta/alquileres');
    expect(voz.orden('¿Dónde estáis?')?.ruta).toBe('/nosotros');
  });

  it('«Quiero alquilar» pasa la Tienda a modo alquiler', () => {
    expect(voz.orden('Quiero alquilar')).toMatchObject({ ruta: '/tienda', query: { modo: 'alquilar' } });
  });

  it('un nombre de producto o «buscar …» no es una orden: se busca', () => {
    expect(voz.orden('Zelda')).toBeNull();
    expect(voz.orden('Buscar cesta de regalo')).toBeNull();
  });
});
JUEGALMI_EOF

mkdir -p $(dirname src/app/services/voz.service.ts)
cat > src/app/services/voz.service.ts <<'JUEGALMI_EOF'
import { Injectable, inject, signal } from '@angular/core';
import { Capacitor } from '@capacitor/core';
import { SpeechRecognition } from '@capacitor-community/speech-recognition';
import { ToastController } from '@ionic/angular';

// Orden de voz que lleva a otra parte de la app
export interface OrdenVoz { ruta: string; query?: Record<string, string>; texto: string; }

// Palabras clave → pantalla (de la más concreta a la más general; sin tildes)
const ORDENES: { claves: string[]; orden: OrdenVoz }[] = [
  { claves: ['mis pedidos', 'pedidos'],                      orden: { ruta: '/cuenta/pedidos', texto: 'Mis pedidos' } },
  { claves: ['mis alquileres', 'alquileres'],                orden: { ruta: '/cuenta/alquileres', texto: 'Mis alquileres' } },
  { claves: ['mis reparaciones', 'reparaciones'],            orden: { ruta: '/taller', query: { vista: 'mis' }, texto: 'Mis reparaciones' } },
  { claves: ['direcciones', 'direccion de envio'],           orden: { ruta: '/cuenta/direcciones', texto: 'Direcciones' } },
  { claves: ['mis datos', 'datos personales', 'perfil'],     orden: { ruta: '/cuenta/datos-personales', texto: 'Datos personales' } },
  { claves: ['cesta', 'carrito'],                            orden: { ruta: '/cesta', texto: 'Cesta' } },
  { claves: ['taller', 'reparar', 'reparacion'],             orden: { ruta: '/taller', texto: 'Taller' } },
  { claves: ['nosotros', 'donde estais', 'ubicacion', 'horario'], orden: { ruta: '/nosotros', texto: 'Sobre nosotros' } },
  { claves: ['alquilar', 'modo alquiler'],                   orden: { ruta: '/tienda', query: { modo: 'alquilar' }, texto: 'Alquilar' } },
  { claves: ['comprar', 'modo compra'],                      orden: { ruta: '/tienda', query: { modo: 'comprar' }, texto: 'Comprar' } },
  { claves: ['inicio', 'portada'],                           orden: { ruta: '/inicio', texto: 'Inicio' } },
];

// Micrófono de la Tienda: busca productos o lleva a otra parte de la app («ir a la cesta»)
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

  // «Ir a la cesta», «abre mis pedidos», «modo alquiler»... → orden; si no es una orden → null (se busca)
  orden(frase: string): OrdenVoz | null {
    if (/^\s*(buscar|busca|busco)\b/i.test(frase)) return null;            // «buscar …» siempre busca
    const t = ' ' + frase.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '')   // sin tildes
      .replace(/[¿?¡!.,]/g, '').trim() + ' ';
    return ORDENES.find(o => o.claves.some(c => t.includes(' ' + c + ' ')))?.orden ?? null;
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

mkdir -p $(dirname COMANDOS-VOZ.md)
cat > COMANDOS-VOZ.md <<'JUEGALMI_EOF'
# Control por voz y acelerómetro (JuegAlmi · Ionic)

## Micrófono (en la Tienda, junto a la lupa)
Pulsa el micrófono y habla. Si lo que dices es una **orden**, la app cambia de pantalla; si no, **busca** ese texto en la Tienda.

### Órdenes (con o sin «ir a», «abre», tildes…)
| Di… | Abre |
|---|---|
| «Ir a la cesta», «carrito» | Cesta |
| «Mis pedidos» | Mis pedidos |
| «Mis alquileres» | Mis alquileres |
| «Mis reparaciones» | Taller › Mis reparaciones |
| «Taller», «quiero reparar» | Taller (nueva reparación) |
| «Quiero alquilar» / «Comprar» | Tienda en modo Alquilar / Comprar |
| «Dónde estáis», «horario», «nosotros» | Sobre nosotros |
| «Mis datos», «perfil» | Datos personales |
| «Direcciones» | Direcciones |
| «Inicio» | Inicio |

### Búsqueda
| Di… | Busca |
|---|---|
| «Zelda» | zelda |
| «Buscar PlayStation 5» | playstation 5 («buscar …» siempre busca, nunca es una orden) |

- Al reconocer una orden sale el aviso «🎤 Abriendo …». Mientras escucha, el micrófono se pone turquesa y late; a los 8 s sin oír nada se cierra.
- Móvil: reconocedor del sistema (plugin `@capacitor-community/speech-recognition`). Navegador: Web Speech API (Chrome, Edge, Safari; **Firefox no la tiene**).

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
| `services/cesta.service.spec.ts` | Cesta: vacía, añadir, sumar cantidad, quitar al llegar a 0, total, guardado en localStorage, vaciar, límite de stock | 7 |
| `models/producto.model.spec.ts` | Etiquetas de stock («Quedan 2», «Última unidad/copia», «Agotado/Alquilado») plataformas de cada juego y su color (PlayStation azul, Xbox verde, Switch rojo) | 9 |
| `services/sesion.service.spec.ts` | Foto de perfil: `POST /api/yo/foto` con el campo «imagen» (HTTP simulado) | 1 |
| `components/precio/precio.component.spec.ts` | Precio con céntimos pequeños: 59,99 €, 35,00 €, punto de miles, sufijo "/ día" | 4 |
| `services/voz.service.spec.ts` | Voz de la Tienda: texto a buscar, órdenes («ir a la cesta», «mis pedidos», «quiero alquilar»), «buscar …» siempre busca, navegador sin voz | 9 |
| `pipes/euros.pipe.spec.ts` | Formato en euros y valor vacío | 2 |
| **Total** | | **43** |

Técnicas usadas:
- **TestBed** de Angular para crear servicios y componentes como en la app.
- **Dobles de prueba** (`vi.fn()`) para los avisos (`ToastController`): se comprueba que la app avisa sin mostrar nada en pantalla.
- `localStorage.clear()` antes de cada prueba para que no dependan unas de otras.

Resultado esperado: `Test Files 7 passed (7) · Tests 43 passed (43)`.

Pruebas manuales en dispositivo (no automatizables aquí): cámara, GPS, voz real y agitar el móvil → ver checklist de la defensa.
JUEGALMI_EOF

grep -rl "@ionic/angular/standalone" src | xargs -r sed -i "s#@ionic/angular/standalone#@ionic/angular#g"

echo ""
echo "✔ Paso 21 aplicado: el micrófono de la Tienda busca y también entiende órdenes («ir a la cesta», «mis pedidos»...)."
echo "  Prueba: npx ng test --watch=false   y   ionic serve"
