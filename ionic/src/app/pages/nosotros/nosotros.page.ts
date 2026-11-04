import { Component, ElementRef, OnDestroy, inject, signal, viewChild } from '@angular/core';
import { IonHeader, IonContent, IonSegment, IonSegmentButton, IonLabel, IonIcon, IonButton, IonSkeletonText } from '@ionic/angular';
import { addIcons } from 'ionicons';
import { locationOutline, timeOutline, callOutline, navigateOutline, imageOutline,
         storefrontOutline, buildOutline, phonePortraitOutline, rocketOutline } from 'ionicons/icons';
import * as L from 'leaflet';
import { CabeceraComponent } from '../../components/cabecera/cabecera.component';
import { TiendaService } from '../../services/tienda.service';
import { UbicacionService } from '../../services/ubicacion.service';
import { Tienda } from '../../models/tienda.model';

type Vista = 'ubicacion' | 'historia' | 'galeria';

// Chincheta morada de la tienda (SVG propio: evita las imágenes por defecto de Leaflet)
const PIN = `<span class="pin"><svg width="22" height="22" viewBox="0 0 24 24" fill="none" stroke="#1f2329" stroke-width="2">
  <path d="M12 21s-7-6.2-7-12a7 7 0 0 1 14 0c0 5.8-7 12-7 12z"/><circle cx="12" cy="9" r="2.5"/></svg></span>`;

@Component({
  selector: 'app-nosotros',
  templateUrl: './nosotros.page.html',
  styleUrls: ['./nosotros.page.scss'],
  imports: [IonHeader, IonContent, IonSegment, IonSegmentButton, IonLabel, IonIcon, IonButton, IonSkeletonText, CabeceraComponent],
})
export class NosotrosPage implements OnDestroy {
  private tiendaSrv = inject(TiendaService);
  private ubicacion = inject(UbicacionService);

  mapaEl = viewChild<ElementRef<HTMLDivElement>>('mapa');   // <div #mapa>

  vista = signal<Vista>('ubicacion');
  tienda = signal<Tienda | null>(null);
  distancia = signal<number | null>(null);    // km hasta la tienda
  sinGps = signal(false);                     // el usuario no ha dado permiso

  iconosHito = ['storefront-outline', 'build-outline', 'phone-portrait-outline', 'rocket-outline'];

  private mapa?: L.Map;
  private marcaUsuario?: L.CircleMarker;

  constructor() {
    addIcons({ locationOutline, timeOutline, callOutline, navigateOutline, imageOutline,
               storefrontOutline, buildOutline, phonePortraitOutline, rocketOutline });
    this.tiendaSrv.obtener().subscribe(t => {
      this.tienda.set(t);
      setTimeout(() => this.crearMapa());     // espera a que exista el <div> del mapa
    });
  }

  // Al entrar: recoloca el mapa y vuelve a pedir la posición
  ionViewDidEnter(): void {
    this.mapa?.invalidateSize();
    this.localizar();
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

  textoDistancia(): string {
    const d = this.distancia();
    if (d === null) return '';
    return d < 1 ? `Estás a ${Math.round(d * 1000)} m de la tienda` : `Estás a ${d.toFixed(1).replace('.', ',')} km de la tienda`;
  }

  // Mapa de OpenStreetMap con la tienda (sin API key)
  private crearMapa(): void {
    const t = this.tienda();
    const el = this.mapaEl()?.nativeElement;
    if (!t || !el || this.mapa) return;

    this.mapa = L.map(el, { zoomControl: false }).setView([t.latitud, t.longitud], 16);
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 19,
      attribution: '© OpenStreetMap',
    }).addTo(this.mapa);

    L.marker([t.latitud, t.longitud], {
      icon: L.divIcon({ className: 'pin-tienda', html: PIN, iconSize: [72, 72], iconAnchor: [36, 36] }),
    }).addTo(this.mapa).bindPopup(t.nombre);

    this.localizar();
  }

  // Punto azul con la posición del usuario + distancia
  private async localizar(): Promise<void> {
    const pos = await this.ubicacion.obtener();
    const t = this.tienda();
    this.sinGps.set(!pos);
    if (!pos || !t || !this.mapa) return;

    this.distancia.set(this.ubicacion.distanciaKm(pos, { lat: t.latitud, lon: t.longitud }));
    if (this.marcaUsuario) {
      this.marcaUsuario.setLatLng([pos.lat, pos.lon]);
    } else {
      this.marcaUsuario = L.circleMarker([pos.lat, pos.lon], {
        radius: 8, color: '#ffffff', weight: 3, fillColor: '#1A73E8', fillOpacity: 1,
      }).addTo(this.mapa).bindPopup('Estás aquí');
    }
  }
}
