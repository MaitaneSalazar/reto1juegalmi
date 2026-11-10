import { Component, ElementRef, OnDestroy, inject, signal, viewChild } from '@angular/core';
import { IonHeader, IonContent, IonSegment, IonSegmentButton, IonLabel, IonIcon, IonButton, IonCard, IonImg } from '@ionic/angular';
import { addIcons } from 'ionicons';
import { locationOutline, timeOutline, callOutline, navigateOutline, imageOutline,
         storefrontOutline, buildOutline, phonePortraitOutline, rocketOutline } from 'ionicons/icons';
import * as L from 'leaflet';
import { CabeceraComponent } from '../../components/cabecera/cabecera.component';
import { TiendaService } from '../../services/tienda.service';
import { FOTOS_LOCALES, FotoTienda, HISTORIA, HITOS, HORARIO, Tienda } from '../../models/tienda.model';
import { LottieComponent } from '../../components/lottie/lottie.component';

type Vista = 'ubicacion' | 'historia' | 'galeria';

// Chincheta morada de la tienda (SVG propio: evita las imágenes por defecto de Leaflet)
const PIN = `<span class="pin"><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#1f2329" stroke-width="2">
  <path d="M12 21s-7-6.2-7-12a7 7 0 0 1 14 0c0 5.8-7 12-7 12z"/><circle cx="12" cy="9" r="2.5"/></svg></span>`;

@Component({
  selector: 'app-nosotros',
  templateUrl: './nosotros.page.html',
  styleUrls: ['./nosotros.page.scss'],
  imports: [LottieComponent, IonCard, IonImg, IonHeader, IonContent, IonSegment, IonSegmentButton, IonLabel, IonIcon, IonButton, CabeceraComponent],
})
export class NosotrosPage implements OnDestroy {
  private tiendaSrv = inject(TiendaService);

  mapaEl = viewChild<ElementRef<HTMLDivElement>>('mapa');   // <div #mapa>

  vista = signal<Vista>('ubicacion');
  tienda = signal<Tienda | null>(null);

  // Horario e historia van escritos en la app (la API no los devuelve)
  horario = HORARIO;
  historia = HISTORIA;
  hitos = HITOS;
  fotos = signal<FotoTienda[]>(FOTOS_LOCALES);   // GET /api/tienda/fotos (si no hay, las locales)

  private mapa?: L.Map;

  constructor() {
    addIcons({ locationOutline, timeOutline, callOutline, navigateOutline, imageOutline,
               storefrontOutline, buildOutline, phonePortraitOutline, rocketOutline });
    this.tiendaSrv.obtener().subscribe({
      next: t => {
        this.tienda.set(t);
        setTimeout(() => this.crearMapa());     // espera a que exista el <div> del mapa
      },
      error: () => { /* sin conexión: se queda el esqueleto */ },
    });
    this.tiendaSrv.fotos().subscribe({
      next: l => { if (l.some(f => f.url)) this.fotos.set(l); },
      error: () => { /* se quedan las fotos locales */ },
    });
  }

  // Al entrar: recoloca el mapa
  ionViewDidEnter(): void {
    this.mapa?.invalidateSize();
  }

  ngOnDestroy(): void {
    this.mapa?.remove();
  }

  cambiarVista(valor: unknown): void {
    this.vista.set((valor as Vista) ?? 'ubicacion');
    if (valor === 'ubicacion') setTimeout(() => this.mapa?.invalidateSize(), 50);   // el mapa estaba oculto
  }

  // Abre la navegación hasta la tienda en la app de mapas
  comoLlegar(): void {
    const t = this.tienda();
    if (t) window.open(`https://www.google.com/maps/dir/?api=1&destination=${t.latitud},${t.longitud}`, '_blank');
  }

  telefonoEnlace(t: Tienda): string {
    return 'tel:' + t.telefono.replace(/\s/g, '');
  }

  // Mapa fijo, como en Android: no se arrastra ni se hace zoom; al tocarlo se abre la ruta
  private crearMapa(): void {
    const t = this.tienda();
    const el = this.mapaEl()?.nativeElement;
    if (!t || !el || this.mapa) return;

    this.mapa = L.map(el, {
      zoomControl: false, dragging: false, touchZoom: false, scrollWheelZoom: false,
      doubleClickZoom: false, boxZoom: false, keyboard: false,
    }).setView([t.latitud, t.longitud], 17);

    // Teselas de Esri (ojo: {z}/{y}/{x}, al revés que OpenStreetMap)
    L.tileLayer('https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/{z}/{y}/{x}', {
      maxZoom: 19,
      attribution: 'Tiles © Esri',
    }).addTo(this.mapa);

    L.marker([t.latitud, t.longitud], {
      icon: L.divIcon({ className: 'pin-tienda', html: PIN, iconSize: [72, 72], iconAnchor: [36, 36] }),
      interactive: false,
    }).addTo(this.mapa);

    this.mapa.on('click', () => this.comoLlegar());
  }
}
