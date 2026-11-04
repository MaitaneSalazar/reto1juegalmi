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
