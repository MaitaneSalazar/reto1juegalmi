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
