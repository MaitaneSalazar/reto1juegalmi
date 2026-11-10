import { ExitoService } from '../../services/exito.service';
import { Component, computed, inject, signal } from '@angular/core';
import { Router, RouterLink } from '@angular/router';
import { IonHeader, IonContent, IonIcon, IonButton, ToastController, IonList, IonCard } from '@ionic/angular';
import { addIcons } from 'ionicons';
import { locationOutline, bagHandleOutline } from 'ionicons/icons';
import { CabeceraComponent } from '../../components/cabecera/cabecera.component';
import { MiniaturaProductoComponent } from '../../components/miniatura-producto/miniatura-producto.component';
import { SelectorCantidadComponent } from '../../components/selector-cantidad/selector-cantidad.component';
import { PrecioComponent } from '../../components/precio/precio.component';
import { CestaService } from '../../services/cesta.service';
import { PedidoService } from '../../services/pedido.service';
import { AlquilerService } from '../../services/alquiler.service';
import { LineaCesta } from '../../models/pedido.model';
import { firstValueFrom } from 'rxjs';
import { SesionService } from '../../services/sesion.service';
import { DomicilioService } from '../../services/domicilio.service';
import { NombreProductoPipe } from '../../pipes/nombre-producto.pipe';
import { EstadoComponent } from '../../components/estado/estado.component';

@Component({
  selector: 'app-cesta',
  templateUrl: './cesta.page.html',
  styleUrls: ['./cesta.page.scss'],
  imports: [EstadoComponent, IonList, IonCard, RouterLink, IonHeader, IonContent, IonIcon, IonButton, CabeceraComponent, MiniaturaProductoComponent, SelectorCantidadComponent, PrecioComponent, NombreProductoPipe],
})
export class CestaPage {
  cesta = inject(CestaService);
  private sesion = inject(SesionService);
  private pedidos = inject(PedidoService);
  private alquileres = inject(AlquilerService);
  private domicilios = inject(DomicilioService);
  private router = inject(Router);
  private toast = inject(ToastController);
  private exito = inject(ExitoService);

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

  irATienda(): void { this.router.navigateByUrl('/tienda'); }

  cambiar(linea: LineaCesta, cambio: number): void {
    // si llega a 0 se quita; no deja pasar del stock (o de las copias libres)
    if (!this.cesta.cambiarCantidad(linea, cambio)) this.aviso('No quedan más unidades');
  }

  // Primero el pedido con las compras (POST /api/pedidos) y luego un alquiler por cada número de días
  // (POST /api/alquileres: los mismos días para todos sus juegos). Igual que CestaFragment en Android
  async confirmar(): Promise<void> {
    const compras = this.cesta.lineas().filter(l => !l.alquiler);
    const alquileres = this.cesta.lineas().filter(l => l.alquiler);
    const d = this.direccion();
    if (compras.length && !d) {                // la dirección solo hace falta si hay compras
      this.aviso('Elige una dirección de envío');
      return;
    }
    this.enviando.set(true);
    try {
      if (compras.length) {
        await firstValueFrom(this.pedidos.crear(d!.id, compras));
        compras.forEach(l => this.cesta.quitar(l));
      }
      for (const dias of [...new Set(alquileres.map(l => l.dias ?? 0))]) {
        const tanda = alquileres.filter(l => l.dias === dias);
        await firstValueFrom(this.alquileres.crear(dias, tanda.map(l => l.producto.id)));
        tanda.forEach(l => this.cesta.quitar(l));
      }
      await this.exito.mostrar(compras.length ? 'Pedido hecho' : 'Alquiler hecho');
      this.router.navigateByUrl(compras.length ? '/cuenta/pedidos' : '/cuenta/alquileres');
    } catch (e) {
      // p. ej. 409 sin stock: la cesta se queda con lo que falta, como en Android
      this.aviso(this.sesion.mensaje(e));
    } finally {
      this.enviando.set(false);
    }
  }

  private async aviso(mensaje: string): Promise<void> {
    const t = await this.toast.create({ message: mensaje, duration: 3000, position: 'bottom' });
    await t.present();
  }
}
