#!/bin/bash
# =====================================================================
# PASO 20 · API actualizada de Aketza (guía de 12 páginas)
#   - Plataformas "PlayStation", "Switch", "Xbox" (ya no hay "Multi": un juego viene una vez por
#     plataforma) → píldora de su color y nombre «Minecraft · Xbox» en cesta, cuenta e inicio
#   - Foto de perfil: POST /api/yo/foto (multipart, campo "imagen") y se muestra foto_perfil_url
#   - Mis reparaciones: vuelve el presupuesto y «Entregada el …» (fecha_entrega)
# Uso (desde la carpeta ionic/):   bash paso20-api-actualizada.sh
# =====================================================================
set -e
if [ ! -f angular.json ] || ! grep -q "colorPlataforma" src/app/models/producto.model.ts 2>/dev/null; then
  echo "✘ Ejecútalo dentro de ionic/ y con los pasos 19 y 19b aplicados"; exit 1
fi
tar czf ../ionic-src-antes-paso20.tgz src PRUEBAS.md
echo "• Copia de seguridad: ../ionic-src-antes-paso20.tgz"

mkdir -p $(dirname src/app/app.component.html)
cat > src/app/app.component.html <<'JUEGALMI_EOF'
<ion-app>
  <ion-menu contentId="contenido-principal" type="overlay" (ionWillOpen)="resumen.refrescar()">
    <ion-content>
      <div class="marca"><span class="logo">J</span>JuegAlmi</div>

      <!-- Usuario: abre Datos personales -->
      <ion-menu-toggle [autoHide]="false">
        <a class="usuario" routerLink="/cuenta/datos-personales" routerDirection="root">
          <span class="avatar">
            @if (sesion.usuario()?.foto_perfil_miniatura_url ?? sesion.usuario()?.foto_perfil_url; as foto) { <img [src]="foto" alt=""> } @else { {{ sesion.iniciales() }} }
          </span>
          <span>
            <strong>{{ sesion.usuario()?.nombre }} {{ sesion.usuario()?.apellido1 }}</strong>
            <small>{{ sesion.usuario()?.email }}</small>
          </span>
        </a>
      </ion-menu-toggle>

      <!-- Mi actividad y mis datos -->
      @for (grupo of grupos(); track $index) {
        <nav class="grupo">
          @for (op of grupo; track op.titulo) {
            <ion-menu-toggle [autoHide]="false">
              <a class="opcion" [routerLink]="op.url" [queryParams]="op.query" routerDirection="root">
                <ion-icon [name]="op.icono"></ion-icon>
                <span>{{ op.titulo }}</span>
                @if (op.contador !== undefined) { <b class="contador">{{ op.contador }}</b> }
              </a>
            </ion-menu-toggle>
          }
        </nav>
      }

      <!-- Cerrar sesión, en su propio bloque -->
      <nav class="grupo">
        <ion-menu-toggle [autoHide]="false">
          <button type="button" class="opcion" (click)="cerrarSesion()">
            <ion-icon name="log-out-outline"></ion-icon><span>Cerrar sesión</span>
          </button>
        </ion-menu-toggle>
      </nav>
    </ion-content>
  </ion-menu>

  <ion-router-outlet id="contenido-principal"></ion-router-outlet>
</ion-app>
JUEGALMI_EOF

mkdir -p $(dirname src/app/models/producto.model.spec.ts)
cat > src/app/models/producto.model.spec.ts <<'JUEGALMI_EOF'
import { describe, it, expect } from 'vitest';
import { colorPlataforma, etiquetaStock, plataformasDe } from './producto.model';

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

// Un videojuego se puede alquilar si tiene precio por día
export function esAlquilable(p: Producto): boolean {
  return p.tipo === 'videojuego' && p.precio_alquiler_dia != null;
}
JUEGALMI_EOF

mkdir -p $(dirname src/app/models/reparacion.model.ts)
cat > src/app/models/reparacion.model.ts <<'JUEGALMI_EOF'
// Reparación tal como la devuelve la API
export type TipoDispositivo = 'consola' | 'movil' | 'tablet' | 'ordenador' | 'mando' | 'auriculares' | 'reloj' | 'otro';
export type EstadoReparacion = 'recibida' | 'diagnostico' | 'en_reparacion' | 'lista_para_recoger' | 'entregada' | 'cancelada';

export interface PasoReparacion {
  estado: EstadoReparacion;
  texto: string;                 // "En reparación"
  hecho: boolean;
  actual: boolean;
  fecha: string | null;
  descripcion: string | null;
}

export interface Reparacion {
  id: number;
  numero: string;                // "Nº 0001"
  tipo_dispositivo: TipoDispositivo;
  marca: string;
  modelo: string;
  estado: EstadoReparacion;
  estado_texto: string;
  paso: number;                  // 3 → "3/5"
  total_pasos: number;
  fecha: string;                 // entrada (ISO 8601)
  se_puede_cancelar: boolean;
  // Solo en el detalle (GET /api/reparaciones/{id})
  componente?: string | null;
  descripcion_averia?: string;
  presupuesto?: number | null;   // null hasta que la tienda lo pone
  fecha_entrega?: string | null; // cuándo se entregó (null si aún no)
  pasos?: PasoReparacion[];
  trabajador?: { nombre_completo: string; cargo: string; telefono: string; departamento: string } | null;
  fotos?: { id: number; url: string; miniatura_url?: string | null; fecha_subida: string }[];
}

// Datos del formulario (POST /api/reparaciones)
export interface NuevaReparacion {
  tipo_dispositivo: TipoDispositivo;
  marca: string;
  modelo: string;
  componente?: string;
  descripcion_averia: string;
}

// "mando" → "Mando"
export const NOMBRE_DISPOSITIVO: Record<TipoDispositivo, string> = {
  consola: 'Consola', movil: 'Móvil', tablet: 'Tablet', ordenador: 'Ordenador',
  mando: 'Mando', auriculares: 'Auriculares', reloj: 'Reloj', otro: 'Otro',
};
JUEGALMI_EOF

mkdir -p $(dirname src/app/models/usuario.model.ts)
cat > src/app/models/usuario.model.ts <<'JUEGALMI_EOF'
// Usuario tal como lo devuelve la API (GET /api/yo, login y registro)
export type TipoUsuario = 'cliente' | 'trabajador';

export interface Contadores {
  pedidos: number;
  alquileres_activos: number;
  reparaciones_en_curso: number;
}

export interface Usuario {
  id: number;
  tipo: TipoUsuario;
  nombre: string;
  apellido1: string;
  apellido2?: string | null;
  nombre_completo?: string;      // "Ane Etxeberria"
  iniciales?: string;            // "AE"
  dni: string;
  email: string;
  telefono?: string | null;
  foto_perfil?: string | null;               // solo la ruta
  foto_perfil_url?: string | null;           // dirección completa (para mostrarla)
  foto_perfil_miniatura_url?: string | null; // versión pequeña (avatares)
  activo?: boolean;
  fecha_registro?: string;       // ISO 8601
  contadores?: Contadores;       // solo clientes
}

// Datos del formulario de registro (POST /api/registro)
export interface NuevoUsuario {
  nombre: string;
  apellido1: string;
  apellido2?: string;
  dni: string;
  telefono?: string;
  email: string;
  password: string;
}
JUEGALMI_EOF

mkdir -p $(dirname src/app/pages/alquileres/alquileres.page.ts)
cat > src/app/pages/alquileres/alquileres.page.ts <<'JUEGALMI_EOF'
import { nombreProducto } from '../../pipes/nombre-producto.pipe';
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
      @for (l of cesta.lineas(); track l.producto.id) {
        <div class="tarjeta linea">
          <app-miniatura-producto [producto]="l.producto"></app-miniatura-producto>
          <div class="datos">
            <strong>{{ l.producto | nombreProducto }}</strong>
            <app-precio [valor]="l.producto.precio_venta"></app-precio>
          </div>
          <app-selector-cantidad [vertical]="true" [valor]="l.cantidad" [min]="0" [max]="l.producto.stock"
                                 (cambio)="cambiar(l.producto.id, $event)"></app-selector-cantidad>
        </div>
      }

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
    <div class="vacia">
      <ion-icon name="bag-handle-outline"></ion-icon>
      <p>Tu cesta está vacía.</p>
      <ion-button routerLink="/tienda">Ir a la tienda</ion-button>
    </div>
  }
</ion-content>
JUEGALMI_EOF

mkdir -p $(dirname src/app/pages/cesta/cesta.page.ts)
cat > src/app/pages/cesta/cesta.page.ts <<'JUEGALMI_EOF'
import { NombreProductoPipe } from '../../pipes/nombre-producto.pipe';
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

mkdir -p $(dirname src/app/pages/cuenta/cuenta.page.html)
cat > src/app/pages/cuenta/cuenta.page.html <<'JUEGALMI_EOF'
<ion-header class="ion-no-border">
  <app-cabecera></app-cabecera>
</ion-header>

<ion-content class="ion-padding">
  @if (sesion.usuario(); as u) {
    <!-- Perfil -->
    <div class="perfil">
      <div class="avatar">@if (u.foto_perfil_miniatura_url ?? u.foto_perfil_url; as foto) { <img [src]="foto" alt=""> } @else { {{ sesion.iniciales() }} }</div>
      <h1>{{ sesion.nombreCompleto() }}</h1>
      <span>{{ u.email }}</span>
    </div>

    <div class="cascada">
      <!-- Contadores -->
      <div class="contadores">
        <a class="tarjeta pulsable" routerLink="/cuenta/pedidos">
          <ion-icon name="receipt-outline"></ion-icon><b>{{ resumen.pedidos() }}</b><span>Pedidos</span>
        </a>
        <a class="tarjeta pulsable" routerLink="/cuenta/alquileres">
          <ion-icon name="time-outline"></ion-icon><b>{{ resumen.alquileresActivos() }}</b>
          <span>{{ resumen.alquileresActivos() === 1 ? 'Alquiler' : 'Alquileres' }}</span>
        </a>
        <a class="tarjeta pulsable" routerLink="/taller" [queryParams]="{ vista: 'mis' }">
          <ion-icon name="build-outline"></ion-icon><b>{{ resumen.reparacionesEnCurso() }}</b>
          <span>{{ resumen.reparacionesEnCurso() === 1 ? 'Reparación' : 'Reparaciones' }}</span>
        </a>
      </div>

      <!-- Alquiler activo -->
      @if (resumen.alquilerActivo(); as a) {
        <div class="tarjeta alquiler">
          @if (a.lineas[0]; as l) { <app-miniatura-producto [producto]="l.videojuego"></app-miniatura-producto> }
          <span class="crece"><strong>{{ a.lineas[0]?.videojuego | nombreProducto }}</strong><small>Hasta el {{ a.fecha_fin_prevista | fechaCorta }}</small></span>
          <button type="button" class="devolver pulsable" (click)="devolver(a)">Devolver</button>
        </div>
      }

      <!-- Mis datos -->
      <nav class="tarjeta lista">
        <a routerLink="/cuenta/datos-personales"><ion-icon name="person-outline"></ion-icon><span>Datos personales</span><ion-icon name="chevron-forward"></ion-icon></a>
        <a routerLink="/cuenta/direcciones"><ion-icon name="location-outline"></ion-icon><span>Direcciones</span>
          <ion-icon name="chevron-forward"></ion-icon></a>
        <a routerLink="/cuenta/ajustes"><ion-icon name="settings-outline"></ion-icon><span>Ajustes</span><ion-icon name="chevron-forward"></ion-icon></a>
      </nav>

      <button type="button" class="salir" (click)="cerrarSesion()">
        <ion-icon name="log-out-outline"></ion-icon> Cerrar sesión
      </button>
    </div>
  }
</ion-content>
JUEGALMI_EOF

mkdir -p $(dirname src/app/pages/cuenta/cuenta.page.ts)
cat > src/app/pages/cuenta/cuenta.page.ts <<'JUEGALMI_EOF'
import { NombreProductoPipe } from '../../pipes/nombre-producto.pipe';
import { Component, inject } from '@angular/core';
import { Router, RouterLink } from '@angular/router';
import { IonHeader, IonContent, IonIcon, AlertController, ToastController } from '@ionic/angular';
import { addIcons } from 'ionicons';
import { receiptOutline, timeOutline, buildOutline, personOutline, locationOutline,
         settingsOutline, chevronForward, logOutOutline } from 'ionicons/icons';
import { CabeceraComponent } from '../../components/cabecera/cabecera.component';
import { MiniaturaProductoComponent } from '../../components/miniatura-producto/miniatura-producto.component';
import { SesionService } from '../../services/sesion.service';
import { ResumenService } from '../../services/resumen.service';
import { AlquilerService } from '../../services/alquiler.service';
import { Alquiler } from '../../models/alquiler.model';
import { FechaCortaPipe } from '../../pipes/fecha-corta.pipe';

@Component({
  selector: 'app-cuenta',
  templateUrl: './cuenta.page.html',
  styleUrls: ['./cuenta.page.scss'],
  imports: [RouterLink, IonHeader, IonContent, IonIcon, CabeceraComponent, MiniaturaProductoComponent, FechaCortaPipe, NombreProductoPipe],
})
export class CuentaPage {
  sesion = inject(SesionService);
  resumen = inject(ResumenService);
  private alquileres = inject(AlquilerService);
  private alerta = inject(AlertController);
  private toast = inject(ToastController);
  private router = inject(Router);

  constructor() {
    addIcons({ receiptOutline, timeOutline, buildOutline, personOutline, locationOutline,
               settingsOutline, chevronForward, logOutOutline });
  }

  ionViewWillEnter(): void {
    this.resumen.refrescar();
  }

  // Devolver el alquiler activo (con confirmación)
  async devolver(a: Alquiler): Promise<void> {
    const alerta = await this.alerta.create({
      header: 'Devolver alquiler',
      message: `¿Confirmas que has devuelto ${a.lineas[0]?.videojuego.nombre ?? 'el juego'} en la tienda?`,
      buttons: [
        { text: 'Cancelar', role: 'cancel' },
        { text: 'Devolver', handler: () => {
          this.alquileres.devolver(a.id).subscribe({
            next: () => { this.resumen.refrescar(); this.aviso('Alquiler devuelto. ¡Gracias!', 'dark'); },
            error: e => this.aviso(this.sesion.mensaje(e), 'danger'),
          });
        } },
      ],
    });
    await alerta.present();
  }

  private async aviso(mensaje: string, color: string): Promise<void> {
    const t = await this.toast.create({ message: mensaje, duration: 2500, color });
    await t.present();
  }

  cerrarSesion(): void {
    this.sesion.cerrar();
    this.router.navigateByUrl('/login', { replaceUrl: true });
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
      <div><span>Teléfono</span><strong>{{ u.telefono || '—' }}</strong></div>
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
  styleUrls: ['../cuenta/subpagina.scss', '../datos-personales/datos-personales.page.scss', './editar-datos.page.scss'],
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
      <a class="novedad pulsable" [routerLink]="['/producto', p.id]">
        <app-miniatura-producto [producto]="p"></app-miniatura-producto>
        @if (p.stock > 0 && p.stock <= 2) { <span class="etiqueta-mini roja">Últimas unidades</span> }
        <strong>{{ p.nombre }}</strong>
        <app-precio [valor]="p.precio_venta"></app-precio>
      </a>
    }
  </div>
</ion-content>
JUEGALMI_EOF

mkdir -p $(dirname src/app/pages/home/home.page.ts)
cat > src/app/pages/home/home.page.ts <<'JUEGALMI_EOF'
import { NombreProductoPipe } from '../../pipes/nombre-producto.pipe';
import { Component, inject, signal } from '@angular/core';
import { RouterLink } from '@angular/router';
import { forkJoin } from 'rxjs';
import { IonHeader, IonContent, IonIcon, IonSkeletonText,
         IonRefresher, IonRefresherContent, RefresherCustomEvent } from '@ionic/angular';
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

const VUELTA = 2 * Math.PI * 26;   // perímetro del círculo de progreso (radio 26)

@Component({
  selector: 'app-home',
  templateUrl: './home.page.html',
  styleUrls: ['./home.page.scss'],
  imports: [RouterLink, IonHeader, IonContent, IonIcon, IonSkeletonText, IonRefresher, IonRefresherContent,
            CabeceraComponent, MiniaturaProductoComponent, PrecioComponent, NombreProductoPipe],
})
export class HomePage {
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
              <span class="dato"><span>Presupuesto</span><span>{{ r.presupuesto != null ? (r.presupuesto | euros) : 'Pendiente' }}</span></span>
            </button>
          }
        </div>
      }

      @if (entregadas().length) {
        <div class="seccion"><h2>Entregadas</h2></div>
        @for (r of entregadas(); track r.id) {
          <button type="button" class="tarjeta entregada pulsable" (click)="abrir(r)">
            <ion-icon name="checkmark-circle-outline"></ion-icon>
            <span class="textos"><strong>{{ tipoTexto(r) }} · {{ r.marca }} {{ r.modelo }}</strong><small>Entregada el {{ (r.fecha_entrega ?? r.fecha) | fechaCorta }}</small></span>
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

mkdir -p $(dirname src/app/pipes/nombre-producto.pipe.ts)
cat > src/app/pipes/nombre-producto.pipe.ts <<'JUEGALMI_EOF'
import { Pipe, PipeTransform } from '@angular/core';

// "Minecraft" + plataforma → "Minecraft · Xbox" (un juego viene una vez por cada plataforma)
export function nombreProducto(p: { nombre: string; plataforma?: string | null } | null | undefined): string {
  if (!p) return '';
  return p.plataforma ? `${p.nombre} · ${p.plataforma}` : p.nombre;
}

@Pipe({ name: 'nombreProducto' })
export class NombreProductoPipe implements PipeTransform {
  transform(p: { nombre: string; plataforma?: string | null } | null | undefined): string {
    return nombreProducto(p);
  }
}
JUEGALMI_EOF

mkdir -p $(dirname src/app/services/sesion.service.spec.ts)
cat > src/app/services/sesion.service.spec.ts <<'JUEGALMI_EOF'
import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { TestBed } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { SesionService } from './sesion.service';
import { environment } from '../../environments/environment';

describe('SesionService · foto de perfil', () => {
  let sesion: SesionService;
  let http: HttpTestingController;

  beforeEach(() => {
    localStorage.clear();
    TestBed.configureTestingModule({ providers: [provideHttpClient(), provideHttpClientTesting()] });
    sesion = TestBed.inject(SesionService);
    http = TestBed.inject(HttpTestingController);
  });

  afterEach(() => http.verify());   // no queda ninguna petición sin comprobar

  it('sube la foto por POST /api/yo/foto con el campo «imagen»', () => {
    sesion.subirFoto(new Blob(['x'], { type: 'image/jpeg' }), 'perfil.jpg').subscribe();
    const pet = http.expectOne(`${environment.apiUrl}/yo/foto`);
    expect(pet.request.method).toBe('POST');
    expect((pet.request.body as FormData).get('imagen')).toBeInstanceOf(Blob);
    pet.flush({ id: 2, tipo: 'cliente', nombre: 'Ane', apellido1: 'Etxeberria', dni: '12345678Z', email: 'demo@juegalmi.es',
                foto_perfil_url: 'http://192.168.2.74:8000/uploads/perfil/2.jpg' });
  });
});
JUEGALMI_EOF

mkdir -p $(dirname src/app/services/sesion.service.ts)
cat > src/app/services/sesion.service.ts <<'JUEGALMI_EOF'
import { Injectable, computed, inject, signal } from '@angular/core';
import { HttpClient, HttpErrorResponse } from '@angular/common/http';
import { Observable, catchError, map, tap, throwError } from 'rxjs';
import { environment } from '../../environments/environment';
import { NuevoUsuario, Usuario } from '../models/usuario.model';

// Lo que se guarda tras iniciar sesión
export interface Sesion {
  token: string;                 // JWT que devuelve la API (dura 7 días)
  usuario: Usuario;
}

const CLAVE = 'juegalmi_sesion';       // clave en localStorage
const API = environment.apiUrl;

@Injectable({ providedIn: 'root' })
export class SesionService {
  private http = inject(HttpClient);
  private sesion = signal<Sesion | null>(this.leer());

  readonly usuario = computed(() => this.sesion()?.usuario ?? null);
  readonly token = computed(() => this.sesion()?.token ?? null);
  readonly logueado = computed(() => this.sesion() !== null);

  // "Ane Etxeberria" (la API ya lo trae; si no, se compone)
  readonly nombreCompleto = computed(() => {
    const u = this.usuario();
    return u ? (u.nombre_completo ?? `${u.nombre} ${u.apellido1}`) : '';
  });

  // "AE"
  readonly iniciales = computed(() => {
    const u = this.usuario();
    return u ? (u.iniciales ?? (u.nombre[0] + u.apellido1[0]).toUpperCase()) : '';
  });

  // ---------------------------------------------------------- LOGIN · POST /api/login
  login(email: string, password: string): Observable<Usuario> {
    return this.http.post<Sesion>(`${API}/login`, { email, password }).pipe(
      tap(s => {
        // La app es para clientes: los trabajadores usan la web
        if (s.usuario.tipo !== 'cliente') throw new Error('Esta app es para clientes. Los trabajadores usáis la web de JuegAlmi.');
        this.guardar(s);
      }),
      map(s => s.usuario),
      catchError(e => throwError(() => new Error(this.mensaje(e)))),
    );
  }

  // ---------------------------------------------------------- REGISTRO · POST /api/registro (201 + sesión iniciada)
  registrar(datos: NuevoUsuario): Observable<Usuario> {
    return this.http.post<Sesion>(`${API}/registro`, datos).pipe(
      tap(s => this.guardar(s)),
      map(s => s.usuario),
      catchError(e => throwError(() => new Error(this.mensaje(e)))),
    );
  }

  // ---------------------------------------------------------- MIS DATOS · GET /api/yo (incluye contadores)
  refrescar(): Observable<Usuario> {
    return this.http.get<Usuario>(`${API}/yo`).pipe(tap(u => this.actualizarLocal(u)));
  }

  // ---------------------------------------------------------- MODIFICAR · PUT /api/yo (solo lo que cambia)
  actualizarDatos(cambios: Record<string, string | null>): Observable<Usuario> {
    return this.http.put<Usuario>(`${API}/yo`, cambios).pipe(
      tap(u => this.actualizarLocal(u)),
      catchError(e => throwError(() => new Error(this.mensaje(e)))),
    );
  }

  // POST /api/yo/foto (multipart, campo "imagen"): devuelve el usuario con foto_perfil_url
  subirFoto(imagen: Blob, nombre: string): Observable<Usuario> {
    const datos = new FormData();
    datos.append('imagen', imagen, nombre);
    return this.http.post<Usuario>(`${API}/yo/foto`, datos).pipe(tap(u => this.actualizarLocal(u)));
  }

  // ---------------------------------------------------------- CERRAR SESIÓN
  cerrar(): void {
    this.sesion.set(null);
    try { localStorage.removeItem(CLAVE); } catch { /* sin almacenamiento */ }
  }

  // Mensaje para el usuario a partir del error de la API: { error, codigo, mensaje, campos }
  mensaje(e: unknown): string {
    if (e instanceof HttpErrorResponse) {
      if (e.status === 0) return 'No se puede conectar con el servidor. ¿Estás en la misma wifi que la API?';
      if (e.status >= 500) return 'Error del servidor. Inténtalo más tarde.';
      const campos = e.error?.campos as Record<string, string> | undefined;
      if (campos && Object.keys(campos).length) return Object.values(campos)[0];
      return e.error?.mensaje ?? 'Ha ocurrido un error. Inténtalo de nuevo.';
    }
    return e instanceof Error ? e.message : 'Ha ocurrido un error.';
  }

  // ---------------------------------------------------------- AUXILIARES
  private actualizarLocal(u: Usuario): void {
    const s = this.sesion();
    if (s) this.guardar({ ...s, usuario: { ...s.usuario, ...u } });
  }

  private guardar(s: Sesion): void {
    this.sesion.set(s);
    try { localStorage.setItem(CLAVE, JSON.stringify(s)); } catch { /* sin almacenamiento */ }
  }

  private leer(): Sesion | null {
    try { return JSON.parse(localStorage.getItem(CLAVE) ?? 'null'); } catch { return null; }
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
| `models/producto.model.spec.ts` | Etiquetas de stock («Quedan 2», «Última unidad/copia», «Agotado/Alquilado») plataformas de cada juego y su color (PlayStation azul, Xbox verde, Switch rojo) | 9 |
| `services/sesion.service.spec.ts` | Foto de perfil: `POST /api/yo/foto` con el campo «imagen» (HTTP simulado) | 1 |
| `components/precio/precio.component.spec.ts` | Precio con céntimos pequeños: 59,99 €, 35,00 €, punto de miles, sufijo "/ día" | 4 |
| `services/voz.service.spec.ts` | Buscador por voz de la Tienda: texto a buscar, quitar «buscar» y signos, frase vacía, navegador sin voz | 5 |
| `pipes/euros.pipe.spec.ts` | Formato en euros y valor vacío | 2 |
| **Total** | | **39** |

Técnicas usadas:
- **TestBed** de Angular para crear servicios y componentes como en la app.
- **Dobles de prueba** (`vi.fn()`) para los avisos (`ToastController`): se comprueba que la app avisa sin mostrar nada en pantalla.
- `localStorage.clear()` antes de cada prueba para que no dependan unas de otras.

Resultado esperado: `Test Files 7 passed (7) · Tests 39 passed (39)`.

Pruebas manuales en dispositivo (no automatizables aquí): cámara, GPS, voz real y agitar el móvil → ver checklist de la defensa.
JUEGALMI_EOF

grep -rl "@ionic/angular/standalone" src | xargs -r sed -i "s#@ionic/angular/standalone#@ionic/angular#g"

echo ""
echo "✔ Paso 20 aplicado: la app sigue la guía nueva de la API (plataformas, foto de perfil, reparaciones)."
echo "  Prueba: npx ng test --watch=false   y   ionic serve"
