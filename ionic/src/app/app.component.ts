import { Component, computed, inject } from '@angular/core';
import { Router, RouterLink } from '@angular/router';
import { IonApp, IonMenu, IonContent, IonMenuToggle, IonIcon, IonRouterLinkWithHref, IonRouterOutlet } from '@ionic/angular';
import { addIcons } from 'ionicons';
import { receiptOutline, timeOutline, buildOutline, personOutline, locationOutline, logOutOutline } from 'ionicons/icons';
import { SesionService } from './services/sesion.service';
import { ResumenService } from './services/resumen.service';
import { UbicacionService } from './services/ubicacion.service';
import { AgitarService } from './services/agitar.service';

// Opción del menú
interface OpcionMenu { titulo: string; url: string; icono: string; query?: Record<string, string>; contador?: number; }

@Component({
  selector: 'app-root',
  templateUrl: 'app.component.html',
  styleUrls: ['app.component.scss'],
  imports: [RouterLink, IonApp, IonMenu, IonContent, IonMenuToggle, IonIcon, IonRouterLinkWithHref, IonRouterOutlet],
})
export class AppComponent {
  sesion = inject(SesionService);
  resumen = inject(ResumenService);
  private router = inject(Router);

  // Bloque 1: actividad con contadores reales · Bloque 2: mis datos
  grupos = computed<OpcionMenu[][]>(() => [
    [
      { titulo: 'Mis pedidos',      url: '/cuenta/pedidos',    icono: 'receipt-outline', contador: this.resumen.pedidos() },
      { titulo: 'Mis alquileres',   url: '/cuenta/alquileres', icono: 'time-outline',    contador: this.resumen.alquileresActivos() },
      { titulo: 'Mis reparaciones', url: '/taller', query: { vista: 'mis' }, icono: 'build-outline',
        contador: this.resumen.reparacionesEnCurso() },
    ],
    [
      { titulo: 'Datos personales', url: '/cuenta/datos-personales', icono: 'person-outline' },
      { titulo: 'Direcciones',      url: '/cuenta/direcciones',      icono: 'location-outline' },
    ],
  ]);

  constructor() {
    inject(UbicacionService).obtener();   // pide el GPS al abrir (lo usa el interceptor)
    inject(AgitarService).iniciar();      // acelerómetro: agitar el móvil = recargar
    addIcons({ receiptOutline, timeOutline, buildOutline, personOutline, locationOutline, logOutOutline });
  }

  cerrarSesion(): void {
    this.sesion.cerrar();
    this.router.navigateByUrl('/login', { replaceUrl: true });
  }
}
