#!/bin/bash
# =====================================================================
# PASO 15 · Conectar la app Ionic a la API real de Aketza
#   - Modelos y servicios con el formato exacto de la API (snake_case, {datos, paginacion})
#   - Token Bearer + X-Lat/X-Lon en cada llamada; errores {mensaje, campos}
#   - Domicilios (POST · PUT → nuevo id + sustituye_a · DELETE), pedidos, alquileres,
#     reparaciones + subida de fotos
#   - Fuera: datos de ejemplo, factorías y panel del técnico
# Uso (desde la carpeta ionic/):   bash paso15-api-real.sh
# =====================================================================
set -e
if [ ! -f angular.json ] || [ ! -d src/app/pages/taller ]; then
  echo "✘ Ejecútalo dentro de la carpeta ionic/ del proyecto"; exit 1
fi
if ! grep -q "pie-boton" src/app/pages/cuenta/subpagina.scss 2>/dev/null; then
  echo "✘ Falta el paso 14 (mockup final). Aplícalo antes."; exit 1
fi
tar czf ../ionic-src-antes-paso15.tgz src $( [ -f permisos-nativos.py ] && echo permisos-nativos.py )
echo "• Copia de seguridad: ../ionic-src-antes-paso15.tgz"

# ---------------------------------------------------------------------
# 1. Fuera los datos de ejemplo, las factorías y el panel del técnico
# ---------------------------------------------------------------------
rm -rf src/app/factories src/app/services/fuentes src/assets/data src/app/pages/panel-trabajador

# ---------------------------------------------------------------------
# 2. Archivos nuevos y reescritos (formato de la API de Aketza)
# ---------------------------------------------------------------------
mkdir -p src/app
cat > src/app/app.component.html <<'JUEGALMI_EOF'
<ion-app>
  <ion-menu contentId="contenido-principal" type="overlay" (ionWillOpen)="resumen.refrescar()">
    <ion-content>
      <div class="marca"><span class="logo">J</span>JuegAlmi</div>

      <!-- Usuario: abre Datos personales -->
      <ion-menu-toggle [autoHide]="false">
        <a class="usuario" routerLink="/cuenta/datos-personales" routerDirection="root">
          <span class="avatar">
            @if (sesion.usuario()?.foto_perfil; as foto) { <img [src]="foto" alt=""> } @else { {{ sesion.iniciales() }} }
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

mkdir -p src/app
cat > src/app/app.routes.ts <<'JUEGALMI_EOF'
import { Routes } from '@angular/router';
import { invitadoGuard, sesionGuard } from './guards/sesion.guard';

export const routes: Routes = [
  { path: '', redirectTo: 'inicio', pathMatch: 'full' },   // sin sesión, el guard lo manda al login

  // Acceso (solo sin sesión)
  { path: 'login', canActivate: [invitadoGuard], loadComponent: () => import('./pages/login/login.page').then(m => m.LoginPage) },
  { path: 'registro', canActivate: [invitadoGuard], loadComponent: () => import('./pages/registro/registro.page').then(m => m.RegistroPage) },

  // Pantallas SIN barra inferior (requieren sesión)
  { path: 'producto/:id', canActivate: [sesionGuard], loadComponent: () => import('./pages/detalle-producto/detalle-producto.page').then(m => m.DetalleProductoPage) },
  { path: 'cuenta/pedidos', canActivate: [sesionGuard], loadComponent: () => import('./pages/pedidos/pedidos.page').then(m => m.PedidosPage) },
  { path: 'cuenta/alquileres', canActivate: [sesionGuard], loadComponent: () => import('./pages/alquileres/alquileres.page').then(m => m.AlquileresPage) },
  { path: 'cuenta/datos-personales', canActivate: [sesionGuard], loadComponent: () => import('./pages/datos-personales/datos-personales.page').then(m => m.DatosPersonalesPage) },
  { path: 'cuenta/datos-personales/editar', canActivate: [sesionGuard], loadComponent: () => import('./pages/editar-datos/editar-datos.page').then(m => m.EditarDatosPage) },
  { path: 'cuenta/direcciones', canActivate: [sesionGuard], loadComponent: () => import('./pages/direcciones/direcciones.page').then(m => m.DireccionesPage) },
  { path: 'cuenta/direcciones/nueva', canActivate: [sesionGuard], loadComponent: () => import('./pages/direccion/direccion.page').then(m => m.DireccionPage) },
  { path: 'cuenta/direcciones/:id', canActivate: [sesionGuard], loadComponent: () => import('./pages/direccion/direccion.page').then(m => m.DireccionPage) },

  // Pantallas CON barra inferior (requieren sesión)
  { path: '', canActivate: [sesionGuard], loadChildren: () => import('./tabs/tabs.routes').then(m => m.routes) },

  { path: '**', redirectTo: 'inicio' },
];
JUEGALMI_EOF

mkdir -p src/app/components/miniatura-producto
cat > src/app/components/miniatura-producto/miniatura-producto.component.ts <<'JUEGALMI_EOF'
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
JUEGALMI_EOF

mkdir -p src/app/guards
cat > src/app/guards/sesion.guard.ts <<'JUEGALMI_EOF'
import { inject } from '@angular/core';
import { CanActivateFn, Router } from '@angular/router';
import { SesionService } from '../services/sesion.service';

// Pantallas de la app: sin sesión → al login
export const sesionGuard: CanActivateFn = () => {
  const sesion = inject(SesionService);
  return sesion.logueado() || inject(Router).createUrlTree(['/login']);
};

// Login y registro: si ya hay sesión → a Inicio
export const invitadoGuard: CanActivateFn = () => {
  const sesion = inject(SesionService);
  return !sesion.logueado() || inject(Router).createUrlTree(['/inicio']);
};
JUEGALMI_EOF

mkdir -p src/app/interceptors
cat > src/app/interceptors/api.interceptor.ts <<'JUEGALMI_EOF'
import { HttpErrorResponse, HttpInterceptorFn } from '@angular/common/http';
import { inject } from '@angular/core';
import { Router } from '@angular/router';
import { catchError, from, switchMap, throwError } from 'rxjs';
import { environment } from '../../environments/environment';
import { SesionService } from '../services/sesion.service';
import { UbicacionService } from '../services/ubicacion.service';

// Se ejecuta antes de cada petición HTTP de la app
export const apiInterceptor: HttpInterceptorFn = (req, next) => {
  // Solo las llamadas a nuestra API (los mapas y las imágenes locales no se tocan)
  if (!req.url.startsWith(environment.apiUrl)) return next(req);

  const sesion = inject(SesionService);
  const ubicacion = inject(UbicacionService);
  const router = inject(Router);

  return from(ubicacion.actual()).pipe(
    switchMap(pos => {
      const cabeceras: Record<string, string> = {};

      // Token JWT (todo el consumo de la API mediante tokens)
      const token = sesion.token();
      if (token) cabeceras['Authorization'] = `Bearer ${token}`;

      // Ubicación del usuario en cualquier consulta (también sin sesión)
      if (pos) {
        cabeceras['X-Lat'] = pos.lat.toFixed(6);
        cabeceras['X-Lon'] = pos.lon.toFixed(6);
      }

      return next(req.clone({ setHeaders: cabeceras }));
    }),
    catchError((e: unknown) => {
      // Token caducado o no válido → cerrar sesión y volver al login
      if (e instanceof HttpErrorResponse && e.status === 401 && sesion.logueado() && !req.url.endsWith('/login')) {
        sesion.cerrar();
        router.navigateByUrl('/login', { replaceUrl: true });
      }
      return throwError(() => e);
    }),
  );
};
JUEGALMI_EOF

mkdir -p src/app/models
cat > src/app/models/alquiler.model.ts <<'JUEGALMI_EOF'
import { Producto } from './producto.model';

export type EstadoAlquiler = 'activo' | 'retrasado' | 'devuelto';

export interface LineaAlquiler {
  id: number;
  videojuego: Producto;
  precio_dia: number;
  fecha_devolucion: string | null;
  devuelto: boolean;
  dias: number;
  importe: number;
}

// Alquiler tal como lo devuelve la API
export interface Alquiler {
  id: number;
  fecha_inicio: string;          // AAAA-MM-DD
  fecha_fin_prevista: string;    // AAAA-MM-DD
  estado: EstadoAlquiler;
  dias_restantes: number;        // negativo = días de retraso
  importe: number;
  lineas: LineaAlquiler[];
}
JUEGALMI_EOF

mkdir -p src/app/models
cat > src/app/models/domicilio.model.ts <<'JUEGALMI_EOF'
// Dirección de envío del cliente (GET /api/domicilios)
export interface DatosDireccion {
  calle: string;
  numero: string;
  piso?: string | null;          // opcional
  codigo_postal: string;         // 5 números
  ciudad: string;
  provincia: string;
}

export interface Domicilio {
  id: number;
  fecha_alta: string;
  fecha_baja: string | null;
  activo: boolean;
  direccion: DatosDireccion;
  texto: string;                 // "Gran Vía 12, 3ºB · Bilbao" (listo para la cesta)
  sustituye_a?: number;          // solo al editar: id del domicilio antiguo (dado de baja)
}
JUEGALMI_EOF

mkdir -p src/app/models
cat > src/app/models/pagina.model.ts <<'JUEGALMI_EOF'
// Respuesta de los listados paginados de la API: ?page=1&limit=20
export interface Pagina<T> {
  datos: T[];
  paginacion: { pagina: number; por_pagina: number; total: number; paginas: number };
}

// Algunos listados podrían venir sin paginar: devuelve siempre el array
export function soloDatos<T>(r: T[] | Pagina<T>): T[] {
  return Array.isArray(r) ? r : r.datos;
}
JUEGALMI_EOF

mkdir -p src/app/models
cat > src/app/models/pedido.model.ts <<'JUEGALMI_EOF'
import { Domicilio } from './domicilio.model';
import { Producto } from './producto.model';

export type EstadoPedido = 'pendiente' | 'pagado' | 'enviado' | 'entregado' | 'cancelado';

// Pedido en el listado (GET /api/pedidos)
export interface PedidoResumen {
  id: number;
  fecha: string;                 // ISO 8601
  estado: EstadoPedido;
  total: number;
  unidades: number;
  primer_producto: string;
  imagen_url: string | null;
  se_puede_cancelar: boolean;
}

// Pedido completo (GET /api/pedidos/{id})
export interface Pedido extends PedidoResumen {
  domicilio: Domicilio;
  lineas: { id: number; producto: Producto; cantidad: number; precio_unitario: number; subtotal: number }[];
}

// Línea de la cesta (antes de confirmar el pedido; vive solo en la app)
export interface LineaCesta {
  producto: Producto;
  cantidad: number;
}
JUEGALMI_EOF

mkdir -p src/app/models
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

// Icono provisional de cada tipo (mientras no hay foto o mientras carga)
export const ICONO_TIPO: Record<TipoProducto, string> = {
  videojuego: 'disc-outline',
  consola: 'game-controller-outline',
  movil: 'phone-portrait-outline',
  tablet: 'tablet-portrait-outline',
};

// Un videojuego se puede alquilar si tiene precio por día
export function esAlquilable(p: Producto): boolean {
  return p.tipo === 'videojuego' && p.precio_alquiler_dia != null;
}
JUEGALMI_EOF

mkdir -p src/app/models
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
  presupuesto?: number | null;
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

mkdir -p src/app/models
cat > src/app/models/tienda.model.ts <<'JUEGALMI_EOF'
// Datos de la tienda (GET /api/tienda)
export interface Tienda {
  nombre: string;
  telefono: string;
  email: string;
  latitud: number;
  longitud: number;
  direccion_linea1: string;      // "Gran Vía 12, bajo"
  direccion_linea2: string;      // "48001 Bilbao, Bizkaia"
}

// Foto de la galería (GET /api/tienda/fotos)
export interface FotoTienda {
  id: number;
  titulo: string;
  url: string | null;
}

// Horario e historia: la API no los devuelve, van escritos en la app
export const HORARIO = [
  { dias: 'Lunes a viernes', horas: '10:00 – 20:30' },
  { dias: 'Sábados', horas: '10:00 – 14:00' },
];

export const HISTORIA = 'JuegAlmi nació de la afición de dos amigos por los videojuegos y la electrónica. '
  + 'Hoy somos tienda, alquiler y taller, con el mismo trato cercano del primer día.';

export const HITOS = [
  { anio: 2012, titulo: 'Abrimos en Bilbao', texto: 'Un pequeño local en Gran Vía dedicado a la compraventa de videojuegos de segunda mano.', icono: 'storefront-outline' },
  { anio: 2015, titulo: 'Nace el taller', texto: 'Empezamos a reparar consolas y mandos en la trastienda, con un único técnico.', icono: 'build-outline' },
  { anio: 2018, titulo: 'Llegan los móviles', texto: 'Ampliamos la tienda con venta y reparación de móviles y tablets.', icono: 'phone-portrait-outline' },
  { anio: 2026, titulo: 'Lanzamos la app', texto: 'Compra, alquila y repara desde el móvil.', icono: 'rocket-outline' },
];

// Galería de respaldo si la API todavía no tiene fotos (assets/tienda/1-5.png)
export const FOTOS_LOCALES: FotoTienda[] = [
  { id: 1, titulo: 'Fachada', url: 'assets/tienda/1.png' },
  { id: 2, titulo: 'Mostrador', url: 'assets/tienda/2.png' },
  { id: 3, titulo: 'Zona de videojuegos', url: 'assets/tienda/3.png' },
  { id: 4, titulo: 'Taller', url: 'assets/tienda/4.png' },
  { id: 5, titulo: 'Zona de consolas', url: 'assets/tienda/5.png' },
];
JUEGALMI_EOF

mkdir -p src/app/models
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
  foto_perfil?: string | null;
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

mkdir -p src/app/pages/ajustes
cat > src/app/pages/ajustes/ajustes.page.ts <<'JUEGALMI_EOF'
import { Component, inject } from '@angular/core';
import { IonHeader, IonToolbar, IonButtons, IonBackButton, IonTitle, IonContent, IonIcon,
         AlertController, ToastController } from '@ionic/angular';
import { addIcons } from 'ionicons';
import { serverOutline, trashOutline, informationCircleOutline, languageOutline } from 'ionicons/icons';
import { environment } from '../../../environments/environment';
import { CestaService } from '../../services/cesta.service';

@Component({
  selector: 'app-ajustes',
  templateUrl: './ajustes.page.html',
  styleUrls: ['../cuenta/subpagina.scss'],
  imports: [IonHeader, IonToolbar, IonButtons, IonBackButton, IonTitle, IonContent, IonIcon],
})
export class AjustesPage {
  private cesta = inject(CestaService);
  private alerta = inject(AlertController);
  private toast = inject(ToastController);

  // Útil en la demo: a qué API está conectada la app
  origenDatos = environment.apiUrl;   // dirección de la API que usa la app
  version = '1.0.0';

  constructor() {
    addIcons({ serverOutline, trashOutline, informationCircleOutline, languageOutline });
  }

  async vaciarCesta(): Promise<void> {
    const a = await this.alerta.create({
      header: 'Vaciar cesta',
      message: '¿Quieres quitar todos los productos de la cesta?',
      buttons: [
        { text: 'Cancelar', role: 'cancel' },
        { text: 'Vaciar', role: 'destructive', handler: async () => {
          this.cesta.vaciar();
          const t = await this.toast.create({ message: 'Cesta vaciada.', duration: 2000, color: 'dark' });
          await t.present();
        } },
      ],
    });
    await a.present();
  }
}
JUEGALMI_EOF

mkdir -p src/app/pages/alquileres
cat > src/app/pages/alquileres/alquileres.page.html <<'JUEGALMI_EOF'
<ion-header class="ion-no-border">
  <ion-toolbar>
    <ion-buttons slot="start"><ion-back-button defaultHref="/inicio" text=""></ion-back-button></ion-buttons>
  </ion-toolbar>
</ion-header>

<ion-content class="ion-padding">
  <h1 class="titulo">Mis alquileres</h1>

  @if (cargando()) {
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
      <p class="vacio">No tienes ningún alquiler en curso.</p>
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

mkdir -p src/app/pages/alquileres
cat > src/app/pages/alquileres/alquileres.page.ts <<'JUEGALMI_EOF'
import { Component, computed, inject, signal } from '@angular/core';
import { IonHeader, IonToolbar, IonButtons, IonBackButton, IonContent, IonIcon, IonSkeletonText,
         AlertController, ToastController } from '@ionic/angular';
import { addIcons } from 'ionicons';
import { arrowUndoOutline } from 'ionicons/icons';
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
            MiniaturaProductoComponent, PrecioComponent, FechaCortaPipe],
})
export class AlquileresPage {
  private servicio = inject(AlquilerService);
  private sesion = inject(SesionService);
  private resumen = inject(ResumenService);
  private alerta = inject(AlertController);
  private toast = inject(ToastController);

  todos = signal<Alquiler[]>([]);
  cargando = signal(true);

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
  private cargar(): void {
    this.servicio.listar().subscribe({
      next: r => { this.todos.set(r.datos); this.cargando.set(false); },
      error: () => this.cargando.set(false),
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

mkdir -p src/app/pages/cesta
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
            <strong>{{ l.producto.nombre }}</strong>
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

mkdir -p src/app/pages/cesta
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
    this.cesta.cambiarCantidad(productoId, cambio);   // si llega a 0 se quita
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

mkdir -p src/app/pages/cuenta
cat > src/app/pages/cuenta/cuenta.page.html <<'JUEGALMI_EOF'
<ion-header class="ion-no-border">
  <app-cabecera></app-cabecera>
</ion-header>

<ion-content class="ion-padding">
  @if (sesion.usuario(); as u) {
    <!-- Perfil -->
    <div class="perfil">
      <div class="avatar">@if (u.foto_perfil) { <img [src]="u.foto_perfil" alt=""> } @else { {{ sesion.iniciales() }} }</div>
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
          <span class="crece"><strong>{{ a.lineas[0]?.videojuego?.nombre }}</strong><small>Hasta el {{ a.fecha_fin_prevista | fechaCorta }}</small></span>
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

mkdir -p src/app/pages/cuenta
cat > src/app/pages/cuenta/cuenta.page.ts <<'JUEGALMI_EOF'
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
  imports: [RouterLink, IonHeader, IonContent, IonIcon, CabeceraComponent, MiniaturaProductoComponent, FechaCortaPipe],
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

mkdir -p src/app/pages/datos-personales
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
        @if (u.foto_perfil) { <img [src]="u.foto_perfil" alt="Foto de perfil"> } @else { {{ sesion.iniciales() }} }
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

mkdir -p src/app/pages/datos-personales
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
  styleUrls: ['../cuenta/subpagina.scss', './datos-personales.page.scss'],
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

mkdir -p src/app/pages/detalle-producto
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
        <p class="nota">{{ p.precio_alquiler_dia | euros }} por día · {{ p.copias_disponibles ?? 0 }} libres · devolución antes del {{ devolucion() }}</p>
      } @else {
        <p class="nota">{{ p.stock > 0 ? p.stock + ' disponibles · envío gratis' : 'Sin unidades ahora mismo' }}</p>
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
        <small>{{ modo() === 'alquilar' ? dias() + (dias() === 1 ? ' día' : ' días') : 'IVA incluido' }}</small>
      </div>
      <ion-button (click)="confirmar()" [disabled]="enviando() || (modo() === 'alquilar' ? sinCopias() : sinStock())">
        @if (enviando()) { <ion-spinner name="crescent"></ion-spinner> }
        @else if (modo() === 'alquilar') { {{ sinCopias() ? 'Alquilado' : 'Alquilar' }} }
        @else { {{ sinStock() ? 'Sin stock' : 'Añadir a la cesta' }} }
      </ion-button>
    </div>
  </ion-footer>
}
JUEGALMI_EOF

mkdir -p src/app/pages/detalle-producto
cat > src/app/pages/detalle-producto/detalle-producto.page.ts <<'JUEGALMI_EOF'
import { FechaCortaPipe } from '../../pipes/fecha-corta.pipe';
import { Component, computed, inject, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { ActivatedRoute, Router } from '@angular/router';
import { IonContent, IonFooter, IonBackButton, IonSegment, IonSegmentButton, IonLabel, IonButton,
         IonSpinner, IonSkeletonText, ToastController } from '@ionic/angular';
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
            IonSpinner, IonSkeletonText, MiniaturaProductoComponent, PrecioComponent, EurosPipe],
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
  sinStock = computed(() => (this.producto()?.stock ?? 0) <= 0);                         // para comprar
  sinCopias = computed(() => (this.producto()?.copias_disponibles ?? 0) <= 0);           // para alquilar
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

  private async anadirCesta(p: Producto): Promise<void> {
    this.cesta.anadir(p);
    const t = await this.toast.create({
      message: `${p.nombre} añadido a la cesta`,
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

mkdir -p src/app/pages/direccion
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
      @if (invalido('calle')) { <p class="error">Escribe la calle.</p> }
    </div>

    <div class="fila2">
      <div class="campo">
        <label>Número</label>
        <ion-input formControlName="numero" placeholder="12" aria-label="Número" [class.mal]="invalido('numero')"></ion-input>
        @if (invalido('numero')) { <p class="error">Pon el número.</p> }
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
        @if (invalido('codigo_postal')) { <p class="error">5 cifras.</p> }
      </div>
      <div class="campo">
        <label>Ciudad</label>
        <ion-input formControlName="ciudad" placeholder="Bilbao" aria-label="Ciudad" [class.mal]="invalido('ciudad')"></ion-input>
        @if (invalido('ciudad')) { <p class="error">Escribe la ciudad.</p> }
      </div>
    </div>

    <div class="campo">
      <label>Provincia</label>
      <ion-input formControlName="provincia" placeholder="Bizkaia" aria-label="Provincia" [class.mal]="invalido('provincia')"></ion-input>
      @if (invalido('provincia')) { <p class="error">Escribe la provincia.</p> }
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

mkdir -p src/app/pages/direccion
cat > src/app/pages/direccion/direccion.page.ts <<'JUEGALMI_EOF'
import { Component, computed, inject, signal } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { IonHeader, IonToolbar, IonButtons, IonBackButton, IonContent, IonFooter, IonInput, IonButton,
         IonSpinner, NavController, ToastController } from '@ionic/angular';
import { SesionService } from '../../services/sesion.service';
import { DomicilioService } from '../../services/domicilio.service';
import { DatosDireccion } from '../../models/domicilio.model';

type Campo = 'calle' | 'numero' | 'codigo_postal' | 'ciudad' | 'provincia';

@Component({
  selector: 'app-direccion',
  templateUrl: './direccion.page.html',
  styleUrls: ['../cuenta/subpagina.scss'],
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

mkdir -p src/app/pages/direcciones
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
    <div class="cascada">
      @for (d of domicilios.lista(); track d.id) {
        <div class="tarjeta direccion pulsable" [class.elegida]="esElegido(d)" (click)="elegir(d)">
          <span class="icono"><ion-icon [name]="esElegido(d) ? 'checkmark-circle' : 'location-outline'"></ion-icon></span>
          <div class="textos">
            <strong>{{ d.direccion.calle }} {{ d.direccion.numero }}@if (d.direccion.piso) {, {{ d.direccion.piso }}}</strong>
            <small>{{ d.direccion.codigo_postal }} {{ d.direccion.ciudad }} · {{ d.direccion.provincia }}</small>
          </div>
          <button type="button" (click)="editar(d, $event)" aria-label="Editar dirección"><ion-icon name="pencil-outline"></ion-icon></button>
          <button type="button" (click)="borrar(d, $event)" aria-label="Borrar dirección"><ion-icon name="trash-outline"></ion-icon></button>
        </div>
      } @empty {
        <p class="vacio">Todavía no tienes ninguna dirección.</p>
      }
    </div>
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

mkdir -p src/app/pages/direcciones
cat > src/app/pages/direcciones/direcciones.page.scss <<'JUEGALMI_EOF'
.direccion {
  display: flex; align-items: center; gap: 14px; padding: 16px 14px 16px 16px; margin-bottom: 14px;
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

.direccion { cursor: pointer; border: 2px solid transparent; }
.direccion.elegida { border-color: var(--ion-color-primary); }
.direccion.elegida .icono ion-icon { color: var(--ion-color-primary); }
JUEGALMI_EOF

mkdir -p src/app/pages/direcciones
cat > src/app/pages/direcciones/direcciones.page.ts <<'JUEGALMI_EOF'
import { Component, inject, signal } from '@angular/core';
import { Router, RouterLink } from '@angular/router';
import { IonHeader, IonToolbar, IonButtons, IonBackButton, IonContent, IonFooter, IonButton, IonIcon,
         IonSkeletonText, AlertController, ToastController } from '@ionic/angular';
import { addIcons } from 'ionicons';
import { locationOutline, pencilOutline, trashOutline, add, checkmarkCircle } from 'ionicons/icons';
import { SesionService } from '../../services/sesion.service';
import { DomicilioService } from '../../services/domicilio.service';
import { Domicilio } from '../../models/domicilio.model';

@Component({
  selector: 'app-direcciones',
  templateUrl: './direcciones.page.html',
  styleUrls: ['../cuenta/subpagina.scss', './direcciones.page.scss'],
  imports: [RouterLink, IonHeader, IonToolbar, IonButtons, IonBackButton, IonContent, IonFooter, IonButton, IonIcon, IonSkeletonText],
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

mkdir -p src/app/pages/editar-datos
cat > src/app/pages/editar-datos/editar-datos.page.ts <<'JUEGALMI_EOF'
import { Component, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { IonHeader, IonToolbar, IonButtons, IonBackButton, IonContent, IonFooter, IonInput, IonButton,
         IonIcon, IonSpinner, NavController, ToastController } from '@ionic/angular';
import { addIcons } from 'ionicons';
import { cameraOutline, lockClosedOutline } from 'ionicons/icons';
import { SesionService } from '../../services/sesion.service';
import { FotoService } from '../../services/foto.service';
import { telefonoValido } from '../../validators/validadores';

type Campo = 'nombre' | 'apellido1' | 'telefono';

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
  });

  constructor() {
    addIcons({ cameraOutline, lockClosedOutline });
  }

  // Rellena el formulario con los datos actuales
  ionViewWillEnter(): void {
    const u = this.sesion.usuario();
    if (!u) return;
    this.form.reset({ nombre: u.nombre, apellido1: u.apellido1, apellido2: u.apellido2 ?? '', telefono: u.telefono ?? '' });
    this.foto.set(u.foto_perfil ?? null);
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
    if (this.foto() && this.foto() !== this.sesion.usuario()?.foto_perfil) datos['foto_perfil'] = this.foto();
    this.sesion.actualizarDatos(datos).subscribe({
      next: () => { this.guardando.set(false); this.aviso('Datos guardados.', 'dark'); this.nav.back(); },
      error: (e: Error) => { this.guardando.set(false); this.aviso(e.message, 'danger'); },
    });
  }

  private async aviso(m: string, color: string): Promise<void> {
    const t = await this.toast.create({ message: m, duration: 2000, color });
    await t.present();
  }
}
JUEGALMI_EOF

mkdir -p src/app/pages/home
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
          <span class="texto"><strong>{{ a.lineas[0].videojuego.nombre }}</strong></span>
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

mkdir -p src/app/pages/home
cat > src/app/pages/home/home.page.ts <<'JUEGALMI_EOF'
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
            CabeceraComponent, MiniaturaProductoComponent, PrecioComponent],
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

mkdir -p src/app/pages/login
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
        <p class="error">Introduce un email válido.</p>
      }
    </div>

    <!-- Contraseña -->
    <div class="campo">
      <label for="password">Contraseña</label>
      <ion-input id="password" formControlName="password" type="password" autocomplete="current-password"
                 aria-label="Contraseña" [class.mal]="invalido('password')"></ion-input>
      @if (invalido('password')) {
        <p class="error">Introduce tu contraseña.</p>
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

mkdir -p src/app/pages/login
cat > src/app/pages/login/login.page.scss <<'JUEGALMI_EOF'
ion-content { --padding-top: calc(14px + var(--ion-safe-area-top, 0px)); --padding-bottom: 32px; }

.cabecera-acceso {
  display: flex; align-items: center; justify-content: space-between;
  min-height: 56px; margin-bottom: 28px;
  .marca { display: flex; align-items: center; gap: 10px; font-size: 24px; font-weight: 700; letter-spacing: -0.04em; }
  a { color: var(--ion-text-color); font-size: 16px; font-weight: 500; text-decoration: none; }
}

h1 { margin: 0; font-size: 46px; line-height: 1.02; font-weight: 800; letter-spacing: -0.055em; }
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

mkdir -p src/app/pages/login
cat > src/app/pages/login/login.page.ts <<'JUEGALMI_EOF'
import { Component, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { IonContent, IonInput, IonButton, IonSpinner, MenuController } from '@ionic/angular';
import { SesionService } from '../../services/sesion.service';

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

mkdir -p src/app/pages/nosotros
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
        @if (distancia() !== null) { <small>{{ textoDistancia() }}</small> }
        @else if (sinGps()) { <small>Activa la ubicación para ver a qué distancia estás.</small> }
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
    <div class="galeria cascada">
      @for (f of fotos(); track f.id; let i = $index) {
        <figure [class.grande]="i % 3 === 0">
          <ion-icon name="image-outline"></ion-icon>
          @if (f.url) { <img [src]="f.url" [alt]="f.titulo" loading="lazy" onerror="this.remove()"> }
          <figcaption>{{ f.titulo }}</figcaption>
        </figure>
      }
    </div>
  }

  @if (!tienda() && vista() === 'ubicacion') {
    <ion-skeleton-text [animated]="true" style="height: 256px; border-radius: 28px"></ion-skeleton-text>
  }
</ion-content>
JUEGALMI_EOF

mkdir -p src/app/pages/nosotros
cat > src/app/pages/nosotros/nosotros.page.ts <<'JUEGALMI_EOF'
import { Component, ElementRef, OnDestroy, inject, signal, viewChild } from '@angular/core';
import { IonHeader, IonContent, IonSegment, IonSegmentButton, IonLabel, IonIcon, IonButton, IonSkeletonText } from '@ionic/angular';
import { addIcons } from 'ionicons';
import { locationOutline, timeOutline, callOutline, navigateOutline, imageOutline,
         storefrontOutline, buildOutline, phonePortraitOutline, rocketOutline } from 'ionicons/icons';
import * as L from 'leaflet';
import { CabeceraComponent } from '../../components/cabecera/cabecera.component';
import { TiendaService } from '../../services/tienda.service';
import { UbicacionService } from '../../services/ubicacion.service';
import { FOTOS_LOCALES, FotoTienda, HISTORIA, HITOS, HORARIO, Tienda } from '../../models/tienda.model';

type Vista = 'ubicacion' | 'historia' | 'galeria';

// Chincheta morada de la tienda (SVG propio: evita las imágenes por defecto de Leaflet)
const PIN = `<span class="pin"><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#1f2329" stroke-width="2">
  <path d="M12 21s-7-6.2-7-12a7 7 0 0 1 14 0c0 5.8-7 12-7 12z"/><circle cx="12" cy="9" r="2.5"/></svg></span>`;

@Component({
  selector: 'app-nosotros',
  templateUrl: './nosotros.page.html',
  styleUrls: ['./nosotros.page.scss'],
  imports: [IonHeader, IonContent, IonSegment, IonSegmentButton, IonLabel, IonIcon, IonButton, IonSkeletonText, CabeceraComponent],
})
export class NosotrosPage implements OnDestroy {
  private tiendaSrv = inject(TiendaService);
  private ubicacion = inject(UbicacionService);

  mapaEl = viewChild<ElementRef<HTMLDivElement>>('mapa');   // <div #mapa>

  vista = signal<Vista>('ubicacion');
  tienda = signal<Tienda | null>(null);
  distancia = signal<number | null>(null);    // km hasta la tienda
  sinGps = signal(false);                     // el usuario no ha dado permiso

  // Horario e historia van escritos en la app (la API no los devuelve)
  horario = HORARIO;
  historia = HISTORIA;
  hitos = HITOS;
  fotos = signal<FotoTienda[]>(FOTOS_LOCALES);   // GET /api/tienda/fotos (si no hay, las locales)

  private mapa?: L.Map;
  private marcaUsuario?: L.CircleMarker;

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

  // Al entrar: recoloca el mapa y vuelve a pedir la posición
  ionViewDidEnter(): void {
    this.mapa?.invalidateSize();
    this.localizar();
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

  textoDistancia(): string {
    const d = this.distancia();
    if (d === null) return '';
    return d < 1 ? `Estás a ${Math.round(d * 1000)} m de la tienda` : `Estás a ${d.toFixed(1).replace('.', ',')} km de la tienda`;
  }

  // Mapa de OpenStreetMap con la tienda (sin API key)
  private crearMapa(): void {
    const t = this.tienda();
    const el = this.mapaEl()?.nativeElement;
    if (!t || !el || this.mapa) return;

    this.mapa = L.map(el, { zoomControl: false }).setView([t.latitud, t.longitud], 16);
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 19,
      attribution: '© OpenStreetMap',
    }).addTo(this.mapa);

    L.marker([t.latitud, t.longitud], {
      icon: L.divIcon({ className: 'pin-tienda', html: PIN, iconSize: [72, 72], iconAnchor: [36, 36] }),
    }).addTo(this.mapa).bindPopup(t.nombre);

    this.localizar();
  }

  // Punto azul con la posición del usuario + distancia
  private async localizar(): Promise<void> {
    const pos = await this.ubicacion.obtener();
    const t = this.tienda();
    this.sinGps.set(!pos);
    if (!pos || !t || !this.mapa) return;

    this.distancia.set(this.ubicacion.distanciaKm(pos, { lat: t.latitud, lon: t.longitud }));
    if (this.marcaUsuario) {
      this.marcaUsuario.setLatLng([pos.lat, pos.lon]);
    } else {
      this.marcaUsuario = L.circleMarker([pos.lat, pos.lon], {
        radius: 8, color: '#ffffff', weight: 3, fillColor: '#1A73E8', fillOpacity: 1,
      }).addTo(this.mapa).bindPopup('Estás aquí');
    }
  }
}
JUEGALMI_EOF

mkdir -p src/app/pages/pedidos
cat > src/app/pages/pedidos/pedidos.page.html <<'JUEGALMI_EOF'
<ion-header class="ion-no-border">
  <ion-toolbar>
    <ion-buttons slot="start"><ion-back-button defaultHref="/inicio" text=""></ion-back-button></ion-buttons>
  </ion-toolbar>
</ion-header>

<ion-content class="ion-padding">
  <h1 class="titulo">Mis pedidos</h1>

  @if (cargando()) {
    <ion-skeleton-text [animated]="true" style="height: 200px; border-radius: 24px"></ion-skeleton-text>
  } @else {
    <!-- Pedido en curso con su barra de estado -->
    @if (actual(); as p) {
      <div class="tarjeta actual">
        <div class="cabecera"><strong>Pedido #{{ p.id }}</strong><span>{{ p.fecha | fechaCorta }}</span></div>
        <div class="barra">
          @for (etapa of pasos; track etapa.estado; let i = $index) {
            <div class="tramo" [class.hecho]="i <= paso(p)" [class.ahora]="i === paso(p)">
              <i></i><span>{{ etapa.texto }}</span>
            </div>
          }
        </div>
        <div class="pie">
          <div class="minis">
            @if (detalle(); as d) {
              @for (l of d.lineas; track l.id) { <app-miniatura-producto [producto]="l.producto"></app-miniatura-producto> }
            } @else {
              <app-miniatura-producto [producto]="mini(p)"></app-miniatura-producto>
            }
          </div>
          <app-precio [valor]="p.total"></app-precio>
        </div>
        @if (p.se_puede_cancelar) {
          <ion-button fill="clear" color="danger" size="small" class="cancelar" (click)="cancelar(p)">Cancelar pedido</ion-button>
        }
      </div>
    }

    <!-- Anteriores -->
    @if (anteriores().length) {
      <h2>Anteriores</h2>
      <div class="cascada">
        @for (p of anteriores(); track p.id) {
          <div class="tarjeta fila">
            <app-miniatura-producto [producto]="mini(p)"></app-miniatura-producto>
            <div class="textos">
              <strong>{{ p.primer_producto }}@if (p.unidades > 1) { <em> · {{ p.unidades }} uds.</em> }</strong>
              <small>#{{ p.id }} · {{ p.fecha | fechaCorta }} · {{ estadoTexto(p) }}</small>
            </div>
            <app-precio [valor]="p.total"></app-precio>
          </div>
        }
      </div>
    }

    @if (!pedidos().length) { <p class="vacio">Todavía no has hecho ningún pedido.</p> }
  }
</ion-content>
JUEGALMI_EOF

mkdir -p src/app/pages/pedidos
cat > src/app/pages/pedidos/pedidos.page.scss <<'JUEGALMI_EOF'
.actual {
  padding: 22px;
  .cabecera { display: flex; justify-content: space-between; align-items: baseline; }
  strong { font-size: 18px; font-weight: 600; }
  .cabecera span { color: var(--jg-texto-sec); font-size: 15px; }
}
// Barra de 4 tramos con su texto debajo
.barra { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); align-items: start; gap: 8px; margin: 20px 0 18px; }
.tramo {
  display: flex; flex-direction: column; gap: 10px;
  i { height: 6px; border-radius: 3px; background: var(--jg-segmento); }
  span { font-size: 13px; color: var(--jg-texto-sec); }
  &.hecho i { background: var(--jg-acento); }
  &.ahora span { color: var(--ion-text-color); font-weight: 600; }
}
.pie { display: flex; align-items: flex-end; justify-content: space-between; gap: 12px; }
.minis { display: flex; gap: 10px; }
.minis app-miniatura-producto { --tam: 64px; --radio: 10px; --fondo: transparent; --ajuste: contain; height: 76px; }
.actual app-precio { font-size: 30px; }
em { font-style: normal; color: var(--jg-texto-sec); font-weight: 400; }

.cancelar { margin: 10px auto 0; display: block; }
JUEGALMI_EOF

mkdir -p src/app/pages/pedidos
cat > src/app/pages/pedidos/pedidos.page.ts <<'JUEGALMI_EOF'
import { Component, computed, inject, signal } from '@angular/core';
import { IonHeader, IonToolbar, IonButtons, IonBackButton, IonContent, IonSkeletonText, IonButton,
         AlertController, ToastController } from '@ionic/angular';
import { MiniaturaProductoComponent } from '../../components/miniatura-producto/miniatura-producto.component';
import { PrecioComponent } from '../../components/precio/precio.component';
import { FechaCortaPipe } from '../../pipes/fecha-corta.pipe';
import { PedidoService } from '../../services/pedido.service';
import { SesionService } from '../../services/sesion.service';
import { EstadoPedido, Pedido, PedidoResumen } from '../../models/pedido.model';

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
  imports: [IonHeader, IonToolbar, IonButtons, IonBackButton, IonContent, IonSkeletonText, IonButton,
            MiniaturaProductoComponent, PrecioComponent, FechaCortaPipe],
})
export class PedidosPage {
  private servicio = inject(PedidoService);
  private sesion = inject(SesionService);
  private alerta = inject(AlertController);
  private toast = inject(ToastController);

  pedidos = signal<PedidoResumen[]>([]);     // GET /api/pedidos (el más reciente primero)
  detalle = signal<Pedido | null>(null);     // GET /api/pedidos/{id} del pedido en curso (sus líneas)
  cargando = signal(true);
  pasos = PASOS;

  // El más reciente sin entregar va arriba en grande; el resto, en "Anteriores"
  actual = computed(() => this.pedidos().find(p => p.estado !== 'entregado' && p.estado !== 'cancelado') ?? null);
  anteriores = computed(() => this.pedidos().filter(p => p !== this.actual()));

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

  private cargar(): void {
    this.servicio.listar().subscribe({
      next: r => {
        this.pedidos.set(r.datos);
        this.cargando.set(false);
        const a = this.actual();
        this.detalle.set(null);
        if (a) this.servicio.obtener(a.id).subscribe({ next: d => this.detalle.set(d), error: () => {} });
      },
      error: () => this.cargando.set(false),
    });
  }

  private async aviso(mensaje: string, color: string): Promise<void> {
    const t = await this.toast.create({ message: mensaje, duration: 2500, color });
    await t.present();
  }
}
JUEGALMI_EOF

mkdir -p src/app/pages/registro
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
      @if (invalido('nombre')) { <p class="error">{{ mensajes.nombre }}</p> }
    </div>

    <!-- Dos columnas: apellidos -->
    <div class="fila">
      <div class="campo">
        <label>1er apellido</label>
        <ion-input formControlName="apellido1" autocomplete="family-name" aria-label="Primer apellido" [class.mal]="invalido('apellido1')"></ion-input>
        @if (invalido('apellido1')) { <p class="error">{{ mensajes.apellido1 }}</p> }
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
        @if (invalido('dni')) { <p class="error">{{ mensajes.dni }}</p> }
      </div>
      <div class="campo">
        <label>Teléfono <small>(opcional)</small></label>
        <ion-input formControlName="telefono" type="tel" inputmode="tel" autocomplete="tel" aria-label="Teléfono" [class.mal]="invalido('telefono')"></ion-input>
        @if (invalido('telefono')) { <p class="error">{{ mensajes.telefono }}</p> }
      </div>
    </div>

    <div class="campo">
      <label>Email</label>
      <ion-input formControlName="email" type="email" inputmode="email" autocomplete="email" aria-label="Email" [class.mal]="invalido('email')"></ion-input>
      @if (invalido('email')) { <p class="error">{{ mensajes.email }}</p> }
    </div>

    <div class="campo">
      <label>Contraseña</label>
      <ion-input formControlName="password" type="password" autocomplete="new-password" aria-label="Contraseña" [class.mal]="invalido('password')"></ion-input>
      @if (invalido('password')) { <p class="error">{{ mensajes.password }}</p> }
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

mkdir -p src/app/pages/registro
cat > src/app/pages/registro/registro.page.scss <<'JUEGALMI_EOF'
ion-content { --padding-top: calc(14px + var(--ion-safe-area-top, 0px)); --padding-bottom: 32px; }

.cabecera-acceso {
  display: flex; align-items: center; justify-content: space-between;
  min-height: 56px; margin-bottom: 28px;
  .marca { display: flex; align-items: center; gap: 10px; font-size: 24px; font-weight: 700; letter-spacing: -0.04em; }
  a { color: var(--ion-text-color); font-size: 16px; font-weight: 500; text-decoration: none; }
}

h1 { margin: 0; font-size: 46px; line-height: 1.02; font-weight: 800; letter-spacing: -0.055em; }
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

mkdir -p src/app/pages/registro
cat > src/app/pages/registro/registro.page.ts <<'JUEGALMI_EOF'
import { Component, inject, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { IonContent, IonInput, IonButton, IonSpinner, MenuController } from '@ionic/angular';
import { SesionService } from '../../services/sesion.service';
import { dniValido, telefonoValido } from '../../validators/validadores';

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
  mensajes: Record<Campo, string> = {
    nombre: 'Escribe tu nombre.',
    apellido1: 'Escribe tu primer apellido.',
    apellido2: '',
    dni: 'DNI o NIE no válido (12345678Z o X1234567L).',
    telefono: 'Teléfono no válido (9 cifras).',
    email: 'Introduce un email válido.',
    password: 'Mínimo 6 caracteres.',
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

mkdir -p src/app/pages/reparacion
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
            <span class="inicial">J</span>
            <span><strong>Taller JuegAlmi</strong><small>Técnico pendiente de asignar</small></span>
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
          Cancelar reparación
        </ion-button>
      }
    </div>
  } @else {
    <ion-skeleton-text [animated]="true" style="height: 176px; border-radius: 30px"></ion-skeleton-text>
    <ion-skeleton-text [animated]="true" style="height: 110px; border-radius: 24px; margin-top: 14px"></ion-skeleton-text>
  }
</ion-content>
JUEGALMI_EOF

mkdir -p src/app/pages/reparacion
cat > src/app/pages/reparacion/reparacion.page.scss <<'JUEGALMI_EOF'
ion-toolbar { --background: var(--ion-background-color); --min-height: 64px; padding: 0 12px; }

// Tarjeta turquesa con el estado
.estado {
  padding: 24px 22px; border-radius: 30px;
  background: linear-gradient(135deg, #8ad6d8 0%, #6fc4c7 100%); color: #1f2329;
  span { font-size: 15px; opacity: .8; }
  h1 { margin: 22px 0 18px; font-size: 44px; line-height: 1; font-weight: 800; letter-spacing: -0.055em; }
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

mkdir -p src/app/pages/reparacion
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
      header: '¿Cancelar la reparación?',
      message: 'La solicitud se anulará y no se podrá recuperar.',
      buttons: [
        { text: 'No', role: 'cancel' },
        { text: 'Sí, cancelar', role: 'destructive', handler: () => this.confirmarCancelar() },
      ],
    });
    await a.present();
  }

  private confirmarCancelar(): void {
    this.cancelando.set(true);
    this.servicio.cancelar(this.id).subscribe({
      next: r => { this.cancelando.set(false); this.rep.set(r); this.aviso('Reparación cancelada.', 'dark'); },
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

mkdir -p src/app/pages/taller
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
    @if (cargandoMias()) {
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

      @if (!mias().length) { <p class="vacio">Todavía no has pedido ninguna reparación.</p> }
    }
  }
</ion-content>
JUEGALMI_EOF

mkdir -p src/app/pages/taller
cat > src/app/pages/taller/taller.page.ts <<'JUEGALMI_EOF'
import { Component, computed, inject, signal } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { concatMap, from, last, of, switchMap } from 'rxjs';
import { IonHeader, IonContent, IonSegment, IonSegmentButton, IonLabel, IonIcon, IonInput, IonTextarea,
         IonChip, IonButton, IonSpinner, IonSkeletonText, ToastController } from '@ionic/angular';
import { addIcons } from 'ionicons';
import { gameControllerOutline, phonePortraitOutline, tabletLandscapeOutline, laptopOutline, tvOutline,
         headsetOutline, watchOutline, ellipsisHorizontal, cameraOutline, close, chevronForward, keypadOutline, checkmarkCircleOutline } from 'ionicons/icons';
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
            IonChip, IonButton, IonSpinner, IonSkeletonText, CabeceraComponent, EurosPipe, FechaCortaPipe],
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
  private cargarMias(): void {
    this.reparaciones.listar(1, 50).subscribe({
      next: r => { this.mias.set(r.datos); this.cargandoMias.set(false); },
      error: () => this.cargandoMias.set(false),
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

mkdir -p src/app/pages/tienda
cat > src/app/pages/tienda/tienda.page.html <<'JUEGALMI_EOF'
<ion-header class="ion-no-border">
  <app-cabecera>
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

mkdir -p src/app/pages/tienda
cat > src/app/pages/tienda/tienda.page.ts <<'JUEGALMI_EOF'
import { Component, computed, inject, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { ActivatedRoute, Router } from '@angular/router';
import { IonHeader, IonContent, IonSegment, IonSegmentButton, IonLabel, IonSearchbar, IonChip, IonIcon,
         IonSkeletonText, IonInfiniteScroll, IonInfiniteScrollContent, InfiniteScrollCustomEvent } from '@ionic/angular';
import { addIcons } from 'ionicons';
import { searchOutline, closeOutline } from 'ionicons/icons';
import { CabeceraComponent } from '../../components/cabecera/cabecera.component';
import { MiniaturaProductoComponent } from '../../components/miniatura-producto/miniatura-producto.component';
import { PrecioComponent } from '../../components/precio/precio.component';
import { ProductoService } from '../../services/producto.service';
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
    addIcons({ searchOutline, closeOutline });
    this.servicio.plataformas().subscribe({
      next: lista => this.filtrosAlquilar = [{ etiqueta: 'Todas', valor: '' }, ...lista.map(p => ({ etiqueta: p, valor: p }))],
      error: () => { /* sin conexión: solo "Todas" */ },
    });
    // ?modo=alquilar (desde la tarjeta "Alquilar" de Inicio)
    inject(ActivatedRoute).queryParamMap.pipe(takeUntilDestroyed()).subscribe(params => {
      this.modo.set(params.get('modo') === 'alquilar' ? 'alquilar' : 'comprar');
      this.filtro.set('');
      const buscar = params.get('buscar');          // viene de la orden de voz "buscar ..."
      if (buscar !== null) {
        this.texto.set(buscar);
        this.buscando.set(true);
      }
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

mkdir -p src/app/services
cat > src/app/services/alquiler.service.ts <<'JUEGALMI_EOF'
import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';
import { Alquiler, EstadoAlquiler } from '../models/alquiler.model';
import { Pagina } from '../models/pagina.model';

const API = environment.apiUrl;

@Injectable({ providedIn: 'root' })
export class AlquilerService {
  private http = inject(HttpClient);

  // Ficha · "Alquilar": POST /api/alquileres { dias, videojuegos: [ids] } (sin copias → 409)
  crear(dias: number, videojuegos: number[]): Observable<Alquiler> {
    return this.http.post<Alquiler>(`${API}/alquileres`, { dias, videojuegos });
  }

  // GET /api/alquileres?estado=activo|retrasado|devuelto
  listar(estado?: EstadoAlquiler, page = 1, limit = 50): Observable<Pagina<Alquiler>> {
    const params: Record<string, string | number> = { page, limit };
    if (estado) params['estado'] = estado;
    return this.http.get<Pagina<Alquiler>>(`${API}/alquileres`, { params });
  }

  // "Devolver": PUT /api/alquileres/{id}/devolver (sin cuerpo = todos los juegos)
  devolver(id: number): Observable<Alquiler> {
    return this.http.put<Alquiler>(`${API}/alquileres/${id}/devolver`, {});
  }

  // Fecha de devolución que se mostrará antes de alquilar (hoy + días)
  fechaDevolucion(dias: number, desde = new Date()): string {
    const fin = new Date(desde);
    fin.setDate(fin.getDate() + dias);
    return fin.toISOString().slice(0, 10);
  }
}
JUEGALMI_EOF

mkdir -p src/app/services
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
});
JUEGALMI_EOF

mkdir -p src/app/services
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
  anadir(producto: Producto, cantidad = 1): void {
    const lista = this.lineas();
    const existe = lista.find(l => l.producto.id === producto.id);
    this.guardar(existe
      ? lista.map(l => l.producto.id === producto.id ? { ...l, cantidad: l.cantidad + cantidad } : l)
      : [...lista, { producto, cantidad }]);
  }

  // Botones − y + de la cesta (si llega a 0 se quita)
  cambiarCantidad(productoId: number, cambio: number): void {
    this.guardar(this.lineas()
      .map(l => l.producto.id === productoId ? { ...l, cantidad: l.cantidad + cambio } : l)
      .filter(l => l.cantidad > 0));
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

mkdir -p src/app/services
cat > src/app/services/domicilio.service.ts <<'JUEGALMI_EOF'
import { Injectable, inject, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, map, tap } from 'rxjs';
import { environment } from '../../environments/environment';
import { DatosDireccion, Domicilio } from '../models/domicilio.model';
import { Pagina, soloDatos } from '../models/pagina.model';

const API = environment.apiUrl;
const CLAVE = 'juegalmi_domicilio';    // domicilio elegido para la cesta (localStorage)

@Injectable({ providedIn: 'root' })
export class DomicilioService {
  private http = inject(HttpClient);

  readonly lista = signal<Domicilio[]>([]);                 // domicilios activos
  readonly elegidoId = signal<number | null>(this.leer());  // el que usa la cesta

  // GET /api/domicilios (activos, el más reciente primero)
  cargar(): Observable<Domicilio[]> {
    return this.http.get<Domicilio[] | Pagina<Domicilio>>(`${API}/domicilios`).pipe(
      map(r => soloDatos(r)),
      tap(l => this.lista.set(l)),
    );
  }

  // El de la cesta: el elegido o, si no hay, el primero
  elegido(): Domicilio | null {
    const l = this.lista();
    return l.find(d => d.id === this.elegidoId()) ?? l[0] ?? null;
  }

  elegir(id: number): void {
    this.elegidoId.set(id);
    try { localStorage.setItem(CLAVE, String(id)); } catch { /* sin almacenamiento */ }
  }

  // POST /api/domicilios → 201 con el domicilio nuevo
  crear(d: DatosDireccion): Observable<Domicilio> {
    return this.http.post<Domicilio>(`${API}/domicilios`, d);
  }

  // PUT /api/domicilios/{id} con solo lo que cambia. La API da de baja el antiguo y crea
  // uno nuevo (otro id, "sustituye_a" = id antiguo): si era el de la cesta, pasa a ser el nuevo
  editar(id: number, cambios: Partial<DatosDireccion>): Observable<Domicilio> {
    return this.http.put<Domicilio>(`${API}/domicilios/${id}`, cambios).pipe(
      tap(nuevo => { if (this.elegidoId() === (nuevo.sustituye_a ?? id)) this.elegir(nuevo.id); }),
    );
  }

  // DELETE /api/domicilios/{id} → baja (los pedidos antiguos lo conservan)
  borrar(id: number): Observable<unknown> {
    return this.http.delete(`${API}/domicilios/${id}`);
  }

  private leer(): number | null {
    try { const v = localStorage.getItem(CLAVE); return v ? Number(v) : null; } catch { return null; }
  }
}
JUEGALMI_EOF

mkdir -p src/app/services
cat > src/app/services/foto.service.ts <<'JUEGALMI_EOF'
import { Injectable } from '@angular/core';
import { Camera, CameraResultType, CameraSource } from '@capacitor/camera';

@Injectable({ providedIn: 'root' })
export class FotoService {
  // Abre la cámara (o la galería) y devuelve la foto como dataURL para la vista previa
  async hacerFoto(): Promise<string | null> {
    try {
      const foto = await Camera.getPhoto({
        quality: 70,                         // menos peso = subida más rápida
        width: 1280,                         // tamaño máximo
        resultType: CameraResultType.DataUrl,
        source: CameraSource.Prompt,         // el usuario elige cámara o galería
        promptLabelHeader: 'Foto del dispositivo',
        promptLabelPhoto: 'Elegir de la galería',
        promptLabelPicture: 'Hacer foto',
        promptLabelCancel: 'Cancelar',
      });
      return foto.dataUrl ?? null;
    } catch (e) {
      // Si el usuario cancela no es un error
      if (String(e).toLowerCase().includes('cancel')) return null;
      throw e;
    }
  }

  // "data:image/jpeg;base64,..." → Blob (archivo binario para el multipart)
  aBlob(dataUrl: string): Blob {
    const [cabecera, datos] = dataUrl.split(',');
    const tipo = cabecera.match(/:(.*?);/)?.[1] ?? 'image/jpeg';
    const binario = atob(datos);
    const bytes = new Uint8Array(binario.length);
    for (let i = 0; i < binario.length; i++) bytes[i] = binario.charCodeAt(i);
    return new Blob([bytes], { type: tipo });
  }

  extension(dataUrl: string): string {
    if (dataUrl.startsWith('data:image/png')) return 'png';
    if (dataUrl.startsWith('data:image/webp')) return 'webp';
    return 'jpg';
  }
}
JUEGALMI_EOF

mkdir -p src/app/services
cat > src/app/services/pedido.service.ts <<'JUEGALMI_EOF'
import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';
import { LineaCesta, Pedido, PedidoResumen } from '../models/pedido.model';
import { Pagina } from '../models/pagina.model';

const API = environment.apiUrl;

@Injectable({ providedIn: 'root' })
export class PedidoService {
  private http = inject(HttpClient);

  // Cesta · "Confirmar pedido": POST /api/pedidos (todo o nada; sin stock → 409)
  crear(idDomicilio: number, lineas: LineaCesta[]): Observable<Pedido> {
    return this.http.post<Pedido>(`${API}/pedidos`, {
      id_domicilio: idDomicilio,
      lineas: lineas.map(l => ({ id_producto: l.producto.id, cantidad: l.cantidad })),
    });
  }

  // Mis pedidos: GET /api/pedidos (el más reciente primero)
  listar(page = 1, limit = 50): Observable<Pagina<PedidoResumen>> {
    return this.http.get<Pagina<PedidoResumen>>(`${API}/pedidos`, { params: { page, limit } });
  }

  // Detalle: GET /api/pedidos/{id}
  obtener(id: number): Observable<Pedido> {
    return this.http.get<Pedido>(`${API}/pedidos/${id}`);
  }

  // PUT /api/pedidos/{id}/cancelar (solo pendiente o pagado)
  cancelar(id: number): Observable<Pedido> {
    return this.http.put<Pedido>(`${API}/pedidos/${id}/cancelar`, {});
  }
}
JUEGALMI_EOF

mkdir -p src/app/services
cat > src/app/services/producto.service.ts <<'JUEGALMI_EOF'
import { Injectable, inject } from '@angular/core';
import { HttpClient, HttpParams } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';
import { Producto, TipoProducto } from '../models/producto.model';
import { Pagina } from '../models/pagina.model';

const API = environment.apiUrl;

@Injectable({ providedIn: 'root' })
export class ProductoService {
  private http = inject(HttpClient);

  // Tienda · comprar: GET /api/productos?tipo=&q=&page=&limit=
  listar(f: { tipo?: TipoProducto; q?: string; page?: number; limit?: number } = {}): Observable<Pagina<Producto>> {
    return this.http.get<Pagina<Producto>>(`${API}/productos`, { params: this.params(f) });
  }

  // Tienda · alquilar: GET /api/videojuegos/alquiler?plataforma=&page=&limit=
  alquiler(f: { plataforma?: string; page?: number; limit?: number } = {}): Observable<Pagina<Producto>> {
    return this.http.get<Pagina<Producto>>(`${API}/videojuegos/alquiler`, { params: this.params(f) });
  }

  // Botones de filtro: ["Multi","PS5","Switch","Xbox"]
  plataformas(): Observable<string[]> {
    return this.http.get<string[]>(`${API}/videojuegos/plataformas`);
  }

  // Ficha: GET /api/productos/{id}
  obtener(id: number): Observable<Producto> {
    return this.http.get<Producto>(`${API}/productos/${id}`);
  }

  // Convierte los filtros en ?clave=valor (sin los vacíos)
  private params(f: object): HttpParams {
    let p = new HttpParams();
    for (const [clave, valor] of Object.entries(f)) {
      if (valor !== undefined && valor !== null && valor !== '') p = p.set(clave, String(valor));
    }
    return p;
  }
}
JUEGALMI_EOF

mkdir -p src/app/services
cat > src/app/services/reparacion.service.ts <<'JUEGALMI_EOF'
import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment';
import { NuevaReparacion, Reparacion } from '../models/reparacion.model';
import { Pagina } from '../models/pagina.model';

const API = environment.apiUrl;

@Injectable({ providedIn: 'root' })
export class ReparacionService {
  private http = inject(HttpClient);

  // Nueva reparación: POST /api/reparaciones → 201 en estado "recibida"
  crear(datos: NuevaReparacion): Observable<Reparacion> {
    return this.http.post<Reparacion>(`${API}/reparaciones`, datos);
  }

  // Foto de la cámara: POST /api/reparaciones/{id}/fotos (multipart, campo "imagen")
  subirFoto(id: number, imagen: Blob, nombre: string): Observable<Reparacion> {
    const form = new FormData();
    form.append('imagen', imagen, nombre);
    return this.http.post<Reparacion>(`${API}/reparaciones/${id}/fotos`, form);
  }

  // Mis reparaciones / Inicio: GET /api/reparaciones (la más reciente primero)
  listar(page = 1, limit = 50): Observable<Pagina<Reparacion>> {
    return this.http.get<Pagina<Reparacion>>(`${API}/reparaciones`, { params: { page, limit } });
  }

  // Seguimiento: GET /api/reparaciones/{id}
  obtener(id: number): Observable<Reparacion> {
    return this.http.get<Reparacion>(`${API}/reparaciones/${id}`);
  }

  // Cancelar (solo en "recibida"): DELETE /api/reparaciones/{id}
  cancelar(id: number): Observable<Reparacion> {
    return this.http.delete<Reparacion>(`${API}/reparaciones/${id}`);
  }
}
JUEGALMI_EOF

mkdir -p src/app/services
cat > src/app/services/resumen.service.ts <<'JUEGALMI_EOF'
import { Injectable, inject, signal } from '@angular/core';
import { SesionService } from './sesion.service';
import { AlquilerService } from './alquiler.service';
import { Alquiler } from '../models/alquiler.model';

// Contadores del menú y de Cuenta: vienen en GET /api/yo
@Injectable({ providedIn: 'root' })
export class ResumenService {
  private sesion = inject(SesionService);
  private alquileres = inject(AlquilerService);

  readonly pedidos = signal(0);
  readonly alquileresActivos = signal(0);
  readonly reparacionesEnCurso = signal(0);
  readonly alquilerActivo = signal<Alquiler | null>(null);   // tarjeta de Cuenta

  // Se llama al abrir el menú y al entrar en Cuenta
  refrescar(): void {
    if (!this.sesion.logueado()) return;
    this.sesion.refrescar().subscribe({
      next: u => {
        this.pedidos.set(u.contadores?.pedidos ?? 0);
        this.alquileresActivos.set(u.contadores?.alquileres_activos ?? 0);
        this.reparacionesEnCurso.set(u.contadores?.reparaciones_en_curso ?? 0);
      },
      error: () => { /* sin conexión: se quedan los últimos valores */ },
    });
    this.alquileres.listar('activo', 1, 1).subscribe({
      next: r => this.alquilerActivo.set(r.datos[0] ?? null),
      error: () => this.alquilerActivo.set(null),
    });
  }
}
JUEGALMI_EOF

mkdir -p src/app/services
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

mkdir -p src/app/services
cat > src/app/services/tienda.service.ts <<'JUEGALMI_EOF'
import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, shareReplay } from 'rxjs';
import { environment } from '../../environments/environment';
import { FotoTienda, Tienda } from '../models/tienda.model';

const API = environment.apiUrl;

@Injectable({ providedIn: 'root' })
export class TiendaService {
  private http = inject(HttpClient);

  // Se piden una vez y se reutilizan (no cambian mientras se usa la app)
  private tienda$ = this.http.get<Tienda>(`${API}/tienda`).pipe(shareReplay(1));
  private fotos$ = this.http.get<FotoTienda[]>(`${API}/tienda/fotos`).pipe(shareReplay(1));

  obtener(): Observable<Tienda> { return this.tienda$; }
  fotos(): Observable<FotoTienda[]> { return this.fotos$; }
}
JUEGALMI_EOF

mkdir -p src/app/validators
cat > src/app/validators/validadores.spec.ts <<'JUEGALMI_EOF'
import { describe, it, expect } from 'vitest';
import { FormControl } from '@angular/forms';
import { dniValido, telefonoValido } from './validadores';

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
JUEGALMI_EOF

mkdir -p src/app/validators
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
JUEGALMI_EOF

mkdir -p src/environments
cat > src/environments/environment.prod.ts <<'JUEGALMI_EOF'
// Configuración en producción (APK / docker)
export const environment = {
  production: true,
  apiUrl: 'http://192.168.2.74:8000/api',   // cambiar por la URL HTTPS de AWS cuando esté desplegada
};
JUEGALMI_EOF

mkdir -p src/environments
cat > src/environments/environment.ts <<'JUEGALMI_EOF'
// Configuración en desarrollo (ionic serve)
export const environment = {
  production: false,
  apiUrl: 'http://192.168.2.74:8000/api',   // BASE_URL de la API de Aketza (su VM, misma wifi)
};
JUEGALMI_EOF

mkdir -p src
cat > src/main.ts <<'JUEGALMI_EOF'
import { bootstrapApplication } from '@angular/platform-browser';
import { RouteReuseStrategy, provideRouter, withPreloading, PreloadAllModules } from '@angular/router';
import { provideHttpClient, withInterceptors } from '@angular/common/http';
import { IonicRouteStrategy, provideIonicAngular } from '@ionic/angular';
import { defineCustomElements } from '@ionic/pwa-elements/loader';
import { routes } from './app/app.routes';
import { AppComponent } from './app/app.component';
import { apiInterceptor } from './app/interceptors/api.interceptor';

bootstrapApplication(AppComponent, {
  providers: [
    { provide: RouteReuseStrategy, useClass: IonicRouteStrategy },  // mantiene las páginas en memoria al navegar
    provideIonicAngular({ mode: 'md' }),                            // mismo aspecto en iOS y Android
    provideRouter(routes, withPreloading(PreloadAllModules)),       // rutas con precarga
    provideHttpClient(withInterceptors([apiInterceptor])),          // HTTP + token y GPS en cada petición
  ],
});

defineCustomElements(window);   // ventana de cámara web cuando la app corre en el navegador
JUEGALMI_EOF

# ---------------------------------------------------------------------
# 3. Android: la API de desarrollo va por http (se quita cuando haya HTTPS en AWS)
# ---------------------------------------------------------------------
cat > permisos-nativos.py <<'JUEGALMI_EOF'
# Añade los permisos de cámara, ubicación, micrófono/voz y movimiento a Android e iOS (si las carpetas existen)
import os

manifest = 'android/app/src/main/AndroidManifest.xml'
if os.path.exists(manifest):
    xml = open(manifest, encoding='utf-8').read()
    permisos = ['android.permission.CAMERA', 'android.permission.ACCESS_COARSE_LOCATION',
                'android.permission.ACCESS_FINE_LOCATION', 'android.permission.INTERNET',
                'android.permission.RECORD_AUDIO']
    nuevos = ''.join(f'    <uses-permission android:name="{p}" />\n' for p in permisos if p not in xml)
    if 'android.hardware.location.gps' not in xml:
        nuevos += '    <uses-feature android:name="android.hardware.location.gps" android:required="false" />\n'
    # Android 11+: hay que declarar que la app abre el reconocedor de voz de Google
    if 'android.speech.action.RECOGNIZE_SPEECH' not in xml:
        nuevos += ('    <queries>\n        <intent>\n'
                   '            <action android:name="android.speech.action.RECOGNIZE_SPEECH" />\n'
                   '        </intent>\n    </queries>\n')
    # La API de desarrollo va por http (VM de Aketza): se quita cuando la API tenga HTTPS
    http = 'usesCleartextTraffic' not in xml
    if http:
        xml = xml.replace('<application', '<application\n        android:usesCleartextTraffic="true"', 1)
    if nuevos or http:
        xml = xml.replace('</manifest>', nuevos + '</manifest>')
        open(manifest, 'w', encoding='utf-8').write(xml)
    print('✔ Permisos de Android revisados')

plist = 'ios/App/App/Info.plist'
if os.path.exists(plist):
    txt = open(plist, encoding='utf-8').read()
    claves = {
        'NSCameraUsageDescription': 'JuegAlmi usa la cámara para fotografiar el dispositivo que quieres reparar.',
        'NSPhotoLibraryUsageDescription': 'JuegAlmi necesita acceder a tus fotos para adjuntarlas a la reparación.',
        'NSPhotoLibraryAddUsageDescription': 'JuegAlmi guarda en tu galería las fotos que haces para el taller.',
        'NSLocationWhenInUseUsageDescription': 'JuegAlmi usa tu ubicación para mostrar la distancia a la tienda y registrar tus consultas.',
        'NSMicrophoneUsageDescription': 'JuegAlmi usa el micrófono para que controles la app por voz.',
        'NSSpeechRecognitionUsageDescription': 'JuegAlmi convierte tu voz en órdenes como «tienda» o «buscar Zelda».',
        'NSMotionUsageDescription': 'JuegAlmi detecta cuando agitas el móvil para recargar la pantalla.',
    }
    nuevas = ''.join(f'\t<key>{k}</key>\n\t<string>{v}</string>\n' for k, v in claves.items() if k not in txt)
    if nuevas:
        pos = txt.rfind('</dict>')
        txt = txt[:pos] + nuevas + txt[pos:]
        open(plist, 'w', encoding='utf-8').write(txt)
    print('✔ Permisos de iOS revisados')
JUEGALMI_EOF

python3 - <<'JUEGALMI_PY'
import os
f = 'capacitor.config.ts'
if os.path.exists(f):
    s = open(f, encoding='utf-8').read()
    if 'androidScheme' not in s:
        i = s.find('webDir')
        fin = s.find('\n', i)
        if not s[:fin].rstrip().endswith(','):          # webDir: 'www'  →  webDir: 'www',
            s = s[:fin].rstrip() + ',' + s[fin:]
            fin = s.find('\n', i)
        s = s[:fin + 1] + "  server: { androidScheme: 'http', cleartext: true },   // API por http en desarrollo (quitar con HTTPS)\n" + s[fin + 1:]
        open(f, 'w', encoding='utf-8').write(s)
        print('✔ capacitor.config.ts: permite llamar a la API por http')
JUEGALMI_PY
if [ -d android ]; then python3 permisos-nativos.py; fi

# Ionic 9: los imports standalone van en '@ionic/angular'
grep -rl "@ionic/angular/standalone" src | xargs -r sed -i "s#@ionic/angular/standalone#@ionic/angular#g"

echo ""
echo "✔ Paso 15 aplicado: la app ya trabaja contra la API de Aketza"
echo "  API: $(grep -o "http[^']*" src/environments/environment.ts | head -1)"
echo "  1) ionic serve  (misma wifi que la VM de Aketza)"
echo "  2) Si tenías sesión abierta, cierra sesión y entra con demo@juegalmi.es / 1234"
