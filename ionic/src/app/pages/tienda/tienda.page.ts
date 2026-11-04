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
import { FiltroProductos, ProductoService } from '../../services/producto.service';
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
    { etiqueta: 'Videojuegos', valor: 'VIDEOJUEGO' },
    { etiqueta: 'Consolas', valor: 'CONSOLA' },
    { etiqueta: 'Móviles', valor: 'MOVIL' },
    { etiqueta: 'Tablets', valor: 'TABLET' },
  ];
  filtrosAlquilar: Filtro[] = [
    { etiqueta: 'Todas', valor: '' },
    { etiqueta: 'Switch', valor: 'Switch' },
    { etiqueta: 'PS5', valor: 'PS5' },
    { etiqueta: 'Xbox', valor: 'Xbox' },
    { etiqueta: 'Multi', valor: 'Multi' },
  ];

  private pagina = 1;
  private peticion = 0;   // descarta respuestas antiguas

  constructor() {
    addIcons({ searchOutline, closeOutline });
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

    const filtros: FiltroProductos = this.modo() === 'alquilar'
      ? { alquilable: true, plataforma: this.filtro() || undefined }
      : { tipo: (this.filtro() || undefined) as TipoProducto | undefined };

    const texto = this.texto().trim();
    const peticion$ = texto
      ? this.servicio.buscar(texto, filtros)
      : this.servicio.listar({ ...filtros, page: this.pagina, limit: POR_PAGINA });

    peticion$.subscribe({
      next: lista => {
        if (id !== this.peticion) return;
        this.productos.update(actual => reiniciar ? lista : [...actual, ...lista]);
        this.hayMas.set(!texto && lista.length === POR_PAGINA);
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
