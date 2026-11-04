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
  private router = inject(Router);
  private toast = inject(ToastController);

  enviando = signal(false);
  direccion = computed(() => this.sesion.usuario()?.direccion ?? null);

  constructor() {
    addIcons({ locationOutline, bagHandleOutline });
  }

  cambiar(productoId: number, cambio: number): void {
    this.cesta.cambiarCantidad(productoId, cambio);   // si llega a 0 se quita
  }

  confirmar(): void {
    const usuarioId = this.sesion.usuario()?.id;
    const d = this.direccion();
    if (!usuarioId) return;
    if (!d) {
      this.aviso('Añade una dirección de envío antes de confirmar.', 'danger');
      return;
    }
    this.enviando.set(true);

    this.pedidos.crear(this.cesta.lineas(), usuarioId, `${d.calle} · ${d.cp} ${d.ciudad}`).subscribe({
      next: pedido => {
        this.enviando.set(false);
        this.cesta.vaciar();
        this.aviso(`Pedido #${pedido.id} confirmado. ¡Gracias!`, 'dark');
        this.router.navigateByUrl('/inicio', { replaceUrl: true });
      },
      error: () => {
        this.enviando.set(false);
        this.aviso('No se ha podido confirmar el pedido. Inténtalo de nuevo.', 'danger');
      },
    });
  }

  private async aviso(mensaje: string, color: string): Promise<void> {
    const t = await this.toast.create({ message: mensaje, duration: 2500, position: 'bottom', color });
    await t.present();
  }
}
