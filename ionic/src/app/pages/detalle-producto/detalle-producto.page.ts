import { FechaCortaPipe } from '../../pipes/fecha-corta.pipe';
import { Component, computed, inject, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { ActivatedRoute, Router } from '@angular/router';
import { IonContent, IonFooter, IonBackButton, IonSegment, IonSegmentButton, IonLabel, IonButton,
         IonSpinner, IonSkeletonText, IonIcon, ToastController } from '@ionic/angular';
import { addIcons } from 'ionicons';
import { notificationsOutline } from 'ionicons/icons';
import { PlataformasComponent } from '../../components/plataformas/plataformas.component';
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
            IonSpinner, IonSkeletonText, IonIcon, PlataformasComponent, MiniaturaProductoComponent, PrecioComponent, EurosPipe, FechaCortaPipe],
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
  // Lo que queda: unidades para comprar o copias libres para alquilar
  quedan = computed(() => {
    const p = this.producto();
    return !p ? 0 : this.modo() === 'alquilar' ? (p.copias_disponibles ?? 0) : p.stock;
  });
  textoStock = computed(() => {
    const n = this.quedan(), alq = this.modo() === 'alquilar';
    if (n <= 0) return alq ? 'Todas las copias están alquiladas' : 'Agotado';
    if (n === 1) return `¡Date prisa! Queda 1 ${alq ? 'copia' : 'unidad'}`;
    if (n === 2) return `¡Date prisa! Quedan 2 ${alq ? 'copias' : 'unidades'}`;
    return alq ? 'Disponible para alquilar' : 'En stock · envío en 24 h';
  });
  alquilable = computed(() => { const p = this.producto(); return !!p && esAlquilable(p); });

  // Pastilla de arriba a la derecha: "Switch", "Consola"...
  // Chips bajo el título
  chips = computed(() => {
    const p = this.producto();
    if (!p) return [];
    return p.tipo === 'videojuego'
      ? [p.genero, p.pegi ? `PEGI ${p.pegi}` : ''].filter(Boolean) as string[]
      : [p.empresa, NOMBRE_TIPO[p.tipo]];
  });

  constructor() {
    addIcons({ notificationsOutline });
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

  // Agotado: de momento solo se avisa (la API no tiene avisos de stock)
  async avisame(): Promise<void> {
    const t = await this.toast.create({ message: 'Te avisaremos cuando vuelva a estar disponible', duration: 2500, color: 'dark' });
    await t.present();
  }

  // Latido del botón al añadir (crece al 108 % y vuelve, 300 ms)
  latiendo = signal(false);
  private latir(): void {
    this.latiendo.set(false);
    setTimeout(() => { this.latiendo.set(true); setTimeout(() => this.latiendo.set(false), 300); });
  }

  private async anadirCesta(p: Producto): Promise<void> {
    if (!this.cesta.anadir(p)) {                       // ya tienes en la cesta todas las que quedan
      const t = await this.toast.create({ message: 'No quedan más unidades', duration: 2000, color: 'dark' });
      await t.present();
      return;
    }
    this.latir();                                      // el botón late, como en Android
    const t = await this.toast.create({
      message: 'Añadido a la cesta',
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
