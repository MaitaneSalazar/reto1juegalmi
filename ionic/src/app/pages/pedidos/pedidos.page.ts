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
import { NombreProductoPipe } from '../../pipes/nombre-producto.pipe';
import { NgTemplateOutlet } from '@angular/common';
import { Router } from '@angular/router';
import { EurosPipe } from '../../pipes/euros.pipe';
import { catchError, forkJoin, map, of } from 'rxjs';
import { addIcons } from 'ionicons';
import { chevronForward, chevronUp } from 'ionicons/icons';
import { LottieComponent } from '../../components/lottie/lottie.component';
import { alAgitar } from '../../services/agitar.service';

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
  private agitar = alAgitar(() => { this.cargando.set(true); this.cargar(); });   // agitar el móvil = recargar esta pantalla (como Android)
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
    addIcons({ chevronForward, chevronUp });
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
  // Igual que PedidoAdapter.nombre() en Android: "Elden Ring +2" (cuenta unidades, no líneas)
  titulo(p: PedidoResumen): string {
    return p.unidades > 1 ? `${p.primer_producto} +${p.unidades - 1}` : p.primer_producto;
  }

  // «Cancelado», «Pendiente», «Pagado»... con mayúscula, como Android
  estadoMayus(p: PedidoResumen): string { return p.estado.charAt(0).toUpperCase() + p.estado.slice(1); }

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
        { text: 'Volver', role: 'cancel' },
        { text: 'Cancelar pedido', role: 'destructive', handler: () => {
          this.servicio.cancelar(p.id).subscribe({
            next: () => { this.aviso('Pedido cancelado'); this.cargar(); },
            error: e => this.aviso(this.sesion.mensaje(e)),
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

  private async aviso(mensaje: string): Promise<void> {
    const t = await this.toast.create({ message: mensaje, duration: 2500 });
    await t.present();
  }
}
