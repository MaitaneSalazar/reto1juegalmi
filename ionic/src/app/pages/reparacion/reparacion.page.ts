import { Component, computed, inject, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { ActivatedRoute } from '@angular/router';
import { IonHeader, IonToolbar, IonButtons, IonBackButton, IonContent, IonIcon,
         IonSkeletonText, IonRefresher, IonRefresherContent, RefresherCustomEvent } from '@ionic/angular';
import { addIcons } from 'ionicons';
import { imageOutline, callOutline } from 'ionicons/icons';
import { PrecioComponent } from '../../components/precio/precio.component';
import { ReparacionService } from '../../services/reparacion.service';
import { TiendaService } from '../../services/tienda.service';
import { PASOS_REPARACION, Reparacion } from '../../models/reparacion.model';

// Paso de la línea de tiempo listo para pintar
interface PasoVista { titulo: string; texto: string; fecha?: string; hecho: boolean; actual: boolean; }

@Component({
  selector: 'app-reparacion',
  templateUrl: './reparacion.page.html',
  styleUrls: ['./reparacion.page.scss'],
  imports: [IonHeader, IonToolbar, IonButtons, IonBackButton, IonContent, IonIcon,
            IonSkeletonText, IonRefresher, IonRefresherContent, PrecioComponent],
})
export class ReparacionPage {
  private servicio = inject(ReparacionService);
  private id = 0;

  rep = signal<Reparacion | null>(null);
  telefono = signal('');                     // teléfono de la tienda para el botón de llamar

  pasos = computed<PasoVista[]>(() => {
    const r = this.rep();
    if (!r) return [];
    return PASOS_REPARACION.map(p => {
      const alcanzado = r.historial.find(h => h.estado === p.estado);
      return { titulo: p.titulo, texto: p.texto, fecha: alcanzado?.fecha, hecho: !!alcanzado, actual: p.estado === r.estado };
    });
  });

  // Título grande: "En reparación"
  estado = computed(() => PASOS_REPARACION.find(p => p.estado === this.rep()?.estado)?.titulo ?? '');
  tipo = computed(() => {
    const t = this.rep()?.tipoDispositivo ?? '';
    return t.charAt(0) + t.slice(1).toLowerCase();
  });
  numero = computed(() => String(this.rep()?.id ?? 0).padStart(4, '0'));

  constructor() {
    addIcons({ imageOutline, callOutline });
    inject(TiendaService).obtener().subscribe(t => this.telefono.set('tel:' + t.telefono.replace(/\s/g, '')));
    inject(ActivatedRoute).paramMap.pipe(takeUntilDestroyed()).subscribe(p => {
      this.id = Number(p.get('id'));
      this.cargar();
    });
  }

  refrescar(e: RefresherCustomEvent): void {
    this.cargar(() => e.target.complete());
  }

  // Las fotos de ejemplo no son URLs reales → icono provisional
  esImagen(url: string): boolean {
    return url.startsWith('http') || url.startsWith('data:') || url.startsWith('/');
  }

  private cargar(alTerminar?: () => void): void {
    this.servicio.obtener(this.id).subscribe({
      next: r => { this.rep.set(r); alTerminar?.(); },
      error: () => alTerminar?.(),
    });
  }
}
