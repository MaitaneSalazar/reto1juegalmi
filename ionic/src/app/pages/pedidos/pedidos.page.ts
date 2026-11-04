import { Component, inject, signal } from '@angular/core';
import { IonHeader, IonToolbar, IonButtons, IonBackButton, IonTitle, IonContent, IonSkeletonText } from '@ionic/angular';
import { EurosPipe } from '../../pipes/euros.pipe';
import { PedidoService } from '../../services/pedido.service';
import { SesionService } from '../../services/sesion.service';
import { EstadoPedido, Pedido } from '../../models/pedido.model';

@Component({
  selector: 'app-pedidos',
  templateUrl: './pedidos.page.html',
  styleUrls: ['../cuenta/subpagina.scss', './pedidos.page.scss'],
  imports: [IonHeader, IonToolbar, IonButtons, IonBackButton, IonTitle, IonContent, IonSkeletonText, EurosPipe],
})
export class PedidosPage {
  private servicio = inject(PedidoService);
  private sesion = inject(SesionService);

  pedidos = signal<Pedido[]>([]);
  cargando = signal(true);

  ionViewWillEnter(): void {
    const id = this.sesion.usuario()?.id;
    if (!id) return;
    this.servicio.delUsuario(id).subscribe(lista => {
      this.pedidos.set([...lista].reverse());   // el más reciente primero
      this.cargando.set(false);
    });
  }

  // Texto y color de cada estado
  estado(e: EstadoPedido): { texto: string; clase: string } {
    const mapa: Record<EstadoPedido, { texto: string; clase: string }> = {
      PENDIENTE: { texto: 'PENDIENTE', clase: '' },
      PAGADO: { texto: 'PAGADO', clase: 'morado' },
      ENVIADO: { texto: 'ENVIADO', clase: 'morado' },
      ENTREGADO: { texto: 'ENTREGADO', clase: 'verde' },
      CANCELADO: { texto: 'CANCELADO', clase: 'rojo' },
    };
    return mapa[e];
  }

  // "Minecraft ×2, Redmi Note 14 Pro"
  resumen(p: Pedido): string {
    return p.lineas.map(l => l.cantidad > 1 ? `${l.nombre} ×${l.cantidad}` : l.nombre).join(', ');
  }
}
