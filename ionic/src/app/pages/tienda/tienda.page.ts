import { Component, inject, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { ActivatedRoute, Router } from '@angular/router';
import { IonHeader, IonContent, IonSegment, IonSegmentButton, IonLabel, IonSearchbar, IonChip, IonIcon,
         IonInfiniteScroll, IonInfiniteScrollContent, InfiniteScrollCustomEvent, ToastController, IonCard } from '@ionic/angular';
import { addIcons } from 'ionicons';
import { searchOutline, closeOutline, micOutline } from 'ionicons/icons';
import { CabeceraComponent } from '../../components/cabecera/cabecera.component';
import { MiniaturaProductoComponent } from '../../components/miniatura-producto/miniatura-producto.component';
import { PrecioComponent } from '../../components/precio/precio.component';
import { PlataformasComponent } from '../../components/plataformas/plataformas.component';
import { ProductoService } from '../../services/producto.service';
import { VozService } from '../../services/voz.service';
import { Producto, TipoProducto, avisoStock, colorPlataforma, nombrePlataforma } from '../../models/producto.model';
import { EstadoComponent } from '../../components/estado/estado.component';
import { LottieComponent } from '../../components/lottie/lottie.component';
import { alAgitar } from '../../services/agitar.service';

type Modo = 'comprar' | 'alquilar';
interface Filtro { etiqueta: string; valor: string; }   // valor '' = todos

const POR_PAGINA = 8;   // carga progresiva

@Component({
  selector: 'app-tienda',
  templateUrl: './tienda.page.html',
  styleUrls: ['./tienda.page.scss'],
  imports: [LottieComponent, IonCard, IonHeader, IonContent, IonSegment, IonSegmentButton, IonLabel, IonSearchbar, IonChip, IonIcon,
            IonInfiniteScroll, IonInfiniteScrollContent,
            CabeceraComponent, MiniaturaProductoComponent, PrecioComponent, EstadoComponent, PlataformasComponent],
})
export class TiendaPage {
  private agitar = alAgitar(() => this.cargar());   // agitar el móvil = recargar esta pantalla (como Android)
  private servicio = inject(ProductoService);
  private router = inject(Router);
  voz = inject(VozService);
  private toast = inject(ToastController);

  modo = signal<Modo>('comprar');
  filtro = signal('');
  texto = signal('');
  buscando = signal(false);          // muestra el buscador (botón lupa)
  productos = signal<Producto[]>([]);
  cargando = signal(true);
  error = signal(false);             // la API no responde → «Sin conexión» + Reintentar
  hayMas = signal(true);

  filtrosComprar: Filtro[] = [
    { etiqueta: 'Todo', valor: '' },
    { etiqueta: 'Videojuegos', valor: 'videojuego' },
    { etiqueta: 'Consolas', valor: 'consola' },
    { etiqueta: 'Móviles', valor: 'movil' },
    { etiqueta: 'Tablets', valor: 'tablet' },
  ];
  // Plataformas de alquiler: se piden a la API (GET /api/videojuegos/plataformas)
  filtrosAlquilar: Filtro[] = [{ etiqueta: 'Todas', valor: '' }];

  plataforma = signal('');           // Comprar → Videojuegos: Todas · PlayStation · Nintendo Switch · Xbox
  plataformasComprar = ['', 'PlayStation', 'Switch', 'Xbox'];
  colorPlataforma = colorPlataforma;
  nombrePlataforma = nombrePlataforma;

  private pagina = 1;
  private peticion = 0;   // descarta respuestas antiguas

  constructor() {
    addIcons({ searchOutline, closeOutline, micOutline });
    this.servicio.plataformas().subscribe({
      // Por si la API aún manda «Multi» (ya no existe: cada juego viene una vez por plataforma)
      next: lista => this.filtrosAlquilar = [{ etiqueta: 'Todas', valor: '' },
        ...lista.filter(p => p !== 'Multi').map(p => ({ etiqueta: nombrePlataforma(p), valor: p }))],   // el valor, como lo entiende la API
      error: () => { /* sin conexión: solo "Todas" */ },
    });
    // ?modo=alquilar (desde la tarjeta "Alquilar" de Inicio)
    inject(ActivatedRoute).queryParamMap.pipe(takeUntilDestroyed()).subscribe(params => {
      this.modo.set(params.get('modo') === 'alquilar' ? 'alquilar' : 'comprar');
      this.filtro.set('');
      this.plataforma.set('');
      this.cargar();
    });
  }

  cambiarModo(valor: unknown): void {
    this.modo.set(valor === 'alquilar' ? 'alquilar' : 'comprar');
    this.filtro.set('');
    this.plataforma.set('');
    this.cargar();
  }

  elegirFiltro(valor: string): void {
    this.filtro.set(valor);
    this.plataforma.set('');
    this.cargar();
  }

  alternarBuscador(): void {
    this.buscando.update(b => !b);
    if (!this.buscando() && this.texto()) this.buscar('');   // al cerrar se limpia
  }

  // Micrófono: «ir a la cesta», «mis pedidos»... cambian de pantalla; cualquier otra cosa se busca
  async buscarPorVoz(): Promise<void> {
    const texto = await this.voz.escuchar();
    if (!texto) return;
    const orden = this.voz.orden(texto);
    if (orden) {
      this.avisoVoz(`Abriendo ${orden.texto}`);
      this.router.navigate([orden.ruta], { queryParams: orden.query });
      return;
    }
    this.buscando.set(true);
    this.buscar(texto);
  }

  private async avisoVoz(mensaje: string): Promise<void> {
    const t = await this.toast.create({ message: '🎤 ' + mensaje, duration: 1500, position: 'top' });
    await t.present();
  }

  buscar(texto: string | null | undefined): void {
    this.texto.set(texto ?? '');
    this.cargar();
  }

  cargarMas(evento: InfiniteScrollCustomEvent): void {
    this.cargar(false, evento);
  }

  // Comprar: unidades en stock · Alquilar: copias libres
  stock(p: Producto) {
    return avisoStock(p, this.modo() === 'alquilar');
  }

  abrir(p: Producto): void {
    this.router.navigate(['/producto', p.id], { queryParams: { modo: this.modo() } });
  }

  cargar(reiniciar = true, evento?: InfiniteScrollCustomEvent): void {
    if (reiniciar) {
      this.pagina = 1;
      this.cargando.set(true);
      this.error.set(false);
      this.hayMas.set(true);
    }
    const id = ++this.peticion;
    const texto = this.texto().trim();

    // Comprar: GET /api/productos (con q= para buscar) · Alquilar: GET /api/videojuegos/alquiler
    const peticion$ = this.modo() === 'alquilar'
      ? this.servicio.alquiler({ plataforma: this.filtro() || undefined, page: this.pagina, limit: POR_PAGINA })
      : this.servicio.listar({ tipo: (this.filtro() || undefined) as TipoProducto | undefined, plataforma: this.plataforma() || undefined, q: texto || undefined,
                               page: this.pagina, limit: POR_PAGINA });

    peticion$.subscribe({
      next: r => {
        if (id !== this.peticion) return;                         // llegó tarde: se ignora
        // En alquiler la API no tiene búsqueda: se filtra lo recibido por el nombre
        const lista = this.modo() === 'alquilar' && texto
          ? r.datos.filter(p => p.nombre.toLowerCase().includes(texto.toLowerCase()))
          : r.datos;
        this.productos.update(actual => reiniciar ? lista : [...actual, ...lista]);
        this.hayMas.set(r.paginacion.pagina < r.paginacion.paginas);   // quedan más páginas
        this.pagina++;
        this.cargando.set(false);
        evento?.target.complete();
      },
      error: () => {
        if (id !== this.peticion) return;
        this.cargando.set(false);
        if (reiniciar) this.error.set(true);
        evento?.target.complete();
      },
    });
  }
}
