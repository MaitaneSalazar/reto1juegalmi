import { Component, computed, inject, signal } from '@angular/core';
import { IonHeader, IonToolbar, IonButtons, IonBackButton, IonContent, IonIcon,
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
import { LottieComponent } from '../../components/lottie/lottie.component';

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
  imports: [LottieComponent, IonList, IonCard, NgTemplateOutlet, IonHeader, IonToolbar, IonButtons, IonBackButton, IonContent, IonIcon,
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
    const t = await this.toast.create({ message: mensaje, duration: 2500 });
    await t.present();
  }
}
