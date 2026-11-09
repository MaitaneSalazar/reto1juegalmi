#!/bin/bash
# =====================================================================
# PASO 22 · Mis pedidos con todos sus artículos
#   - Cada pedido muestra hasta 3 productos (con ×2 si hay varias unidades) y «+N»
#   - Si hay más de 3: botón «Ver más · N artículos» con la lista completa
#     (nombre · plataforma, cantidad × precio y subtotal), sacada de GET /api/pedidos/{id}
# Uso (desde la carpeta ionic/):   bash paso22-pedidos-varios.sh
# =====================================================================
set -e
if [ ! -f angular.json ] || ! grep -q "OrdenVoz" src/app/services/voz.service.ts 2>/dev/null; then
  echo "✘ Ejecútalo dentro de ionic/ y con el paso 21 aplicado"; exit 1
fi
mkdir -p ~/Escritorio/copias-ionic
tar czf ~/Escritorio/copias-ionic/ionic-src-antes-paso22.tgz src
echo "• Copia de seguridad: ~/Escritorio/copias-ionic/ionic-src-antes-paso22.tgz"

mkdir -p $(dirname src/app/models/pedido.model.ts)
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
  lineas: LineaPedido[];
}
export interface LineaPedido { id: number; producto: Producto; cantidad: number; precio_unitario: number; subtotal: number; }

// Línea de la cesta (antes de confirmar el pedido; vive solo en la app)
export interface LineaCesta {
  producto: Producto;
  cantidad: number;
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
            <!-- Hasta 3 productos de izquierda a derecha -->
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
            <app-precio [valor]="p.total"></app-precio>
          </div>

          @if (restantes(p) > 0) {
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
import { Component, inject, signal } from '@angular/core';
import { IonHeader, IonToolbar, IonButtons, IonBackButton, IonContent, IonSkeletonText, IonIcon,
         AlertController, ToastController } from '@ionic/angular';
import { EstadoComponent } from '../../components/estado/estado.component';
import { MiniaturaProductoComponent } from '../../components/miniatura-producto/miniatura-producto.component';
import { PrecioComponent } from '../../components/precio/precio.component';
import { FechaCortaPipe } from '../../pipes/fecha-corta.pipe';
import { PedidoService } from '../../services/pedido.service';
import { SesionService } from '../../services/sesion.service';
import { EstadoPedido, LineaPedido, PedidoResumen } from '../../models/pedido.model';
import { NombreProductoPipe } from '../../pipes/nombre-producto.pipe';
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
  styleUrls: ['../cuenta/subpagina.scss', './pedidos.page.scss'],
  imports: [IonHeader, IonToolbar, IonButtons, IonBackButton, IonContent, IonSkeletonText, IonIcon,
            EstadoComponent, MiniaturaProductoComponent, NombreProductoPipe, EurosPipe, PrecioComponent, FechaCortaPipe],
})
export class PedidosPage {
  private servicio = inject(PedidoService);
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

grep -rl "@ionic/angular/standalone" src | xargs -r sed -i "s#@ionic/angular/standalone#@ionic/angular#g"

echo ""
echo "✔ Paso 22 aplicado: Mis pedidos muestra hasta 3 productos y «Ver más» con todos los artículos."
echo "  Prueba: npx ng test --watch=false   y   ionic serve"
