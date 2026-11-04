import { Component, computed, inject, signal } from '@angular/core';
import { Router } from '@angular/router';
import { IonContent, IonSegment, IonSegmentButton, IonLabel, IonIcon, IonInput, IonButton, IonSpinner,
         IonSkeletonText, IonRefresher, IonRefresherContent, MenuController, RefresherCustomEvent,
         ToastController } from '@ionic/angular';
import { addIcons } from 'ionicons';
import { imageOutline, logOutOutline } from 'ionicons/icons';
import { SesionService } from '../../services/sesion.service';
import { ReparacionService } from '../../services/reparacion.service';
import { EstadoReparacion, PASOS_REPARACION, Reparacion } from '../../models/reparacion.model';

type Grupo = 'nuevas' | 'curso' | 'listas';

// Qué estados entran en cada pestaña
const GRUPOS: Record<Grupo, EstadoReparacion[]> = {
  nuevas: ['RECIBIDA'],
  curso: ['DIAGNOSTICO', 'EN_REPARACION'],
  listas: ['LISTA'],
};

@Component({
  selector: 'app-panel-trabajador',
  templateUrl: './panel-trabajador.page.html',
  styleUrls: ['./panel-trabajador.page.scss'],
  imports: [IonContent, IonSegment, IonSegmentButton, IonLabel, IonIcon, IonInput, IonButton, IonSpinner,
            IonSkeletonText, IonRefresher, IonRefresherContent],
})
export class PanelTrabajadorPage {
  sesion = inject(SesionService);
  private servicio = inject(ReparacionService);
  private menu = inject(MenuController);
  private router = inject(Router);
  private toast = inject(ToastController);

  todas = signal<Reparacion[]>([]);
  cargando = signal(true);
  grupo = signal<Grupo>('curso');
  presupuestos = signal<Record<number, number | null>>({});   // lo que escribe el técnico en cada tarjeta
  avanzando = signal<number | null>(null);                     // id de la que se está guardando

  // Número de cada pestaña ("Nuevas · 3")
  cuenta = computed(() => ({
    nuevas: this.todas().filter(r => GRUPOS.nuevas.includes(r.estado)).length,
    curso: this.todas().filter(r => GRUPOS.curso.includes(r.estado)).length,
    listas: this.todas().filter(r => GRUPOS.listas.includes(r.estado)).length,
  }));

  visibles = computed(() => this.todas().filter(r => GRUPOS[this.grupo()].includes(r.estado)));

  constructor() {
    addIcons({ imageOutline, logOutOutline });
  }

  // El técnico no usa el menú de cliente
  ionViewWillEnter(): void { this.menu.enable(false); this.cargar(); }
  ionViewWillLeave(): void { this.menu.enable(true); }

  refrescar(e: RefresherCustomEvent): void { this.cargar(() => e.target.complete()); }

  cambiarGrupo(v: unknown): void { this.grupo.set((v as Grupo) ?? 'curso'); }

  escribirPresupuesto(id: number, valor: string | null | undefined): void {
    const n = valor ? Number(String(valor).replace(',', '.')) : null;
    this.presupuestos.update(p => ({ ...p, [id]: n !== null && !isNaN(n) ? n : null }));
  }

  // Pasa la reparación al siguiente estado guardando el presupuesto
  avanzar(r: Reparacion): void {
    const presupuesto = this.presupuestos()[r.id] ?? r.presupuesto;
    if (r.estado === 'DIAGNOSTICO' && presupuesto == null) {
      this.aviso('Indica el presupuesto antes de empezar la reparación.', 'danger');
      return;
    }
    this.avanzando.set(r.id);
    this.servicio.avanzar(r, presupuesto ?? undefined).subscribe({
      next: nueva => {
        this.avanzando.set(null);
        this.aviso(`#${this.numero(r.id)} → ${this.estadoTexto(nueva.estado)}`, 'dark');
        this.cargar();
      },
      error: () => { this.avanzando.set(null); this.aviso('No se ha podido actualizar.', 'danger'); },
    });
  }

  cerrarSesion(): void {
    this.sesion.cerrar();
    this.router.navigateByUrl('/login', { replaceUrl: true });
  }

  // Ayudas para la plantilla
  numero(id: number): string { return String(id).padStart(4, '0'); }
  estadoTexto(e: EstadoReparacion): string { return PASOS_REPARACION.find(p => p.estado === e)?.titulo ?? e; }
  tipo(r: Reparacion): string { return r.tipoDispositivo.charAt(0) + r.tipoDispositivo.slice(1).toLowerCase(); }
  textoBoton(r: Reparacion): string { return r.estado === 'LISTA' ? 'Marcar entregada' : 'Siguiente estado'; }

  private cargar(alTerminar?: () => void): void {
    this.servicio.todas().subscribe({
      next: lista => { this.todas.set(lista); this.cargando.set(false); alTerminar?.(); },
      error: () => { this.cargando.set(false); alTerminar?.(); },
    });
  }

  private async aviso(m: string, color: string): Promise<void> {
    const t = await this.toast.create({ message: m, duration: 2000, position: 'bottom', color });
    await t.present();
  }
}
