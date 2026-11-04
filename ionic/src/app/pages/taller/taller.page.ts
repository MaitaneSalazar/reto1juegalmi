import { Component, computed, inject, signal } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { forkJoin, of, switchMap } from 'rxjs';
import { IonHeader, IonContent, IonSegment, IonSegmentButton, IonLabel, IonIcon, IonInput, IonTextarea,
         IonChip, IonButton, IonSpinner, IonSkeletonText, ToastController } from '@ionic/angular';
import { addIcons } from 'ionicons';
import { gameControllerOutline, phonePortraitOutline, tabletLandscapeOutline, laptopOutline, tvOutline,
         headsetOutline, watchOutline, ellipsisHorizontal, cameraOutline, close, chevronForward, keypadOutline } from 'ionicons/icons';
import { CabeceraComponent } from '../../components/cabecera/cabecera.component';
import { SesionService } from '../../services/sesion.service';
import { ReparacionService } from '../../services/reparacion.service';
import { FotoService } from '../../services/foto.service';
import { PASOS_REPARACION, Reparacion, TipoDispositivo, departamentoDe } from '../../models/reparacion.model';

interface OpcionTipo { valor: TipoDispositivo; texto: string; icono: string; }

const MAX_FOTOS = 3;

// Componentes que se ofrecen según el dispositivo
const COMPONENTES: Record<TipoDispositivo, string[]> = {
  CONSOLA:     ['HDMI', 'Ventilador', 'Lector de discos', 'Placa base', 'Puerto de carga', 'Botones'],
  MOVIL:       ['Pantalla', 'Batería', 'Puerto de carga', 'Cámara', 'Botones', 'Altavoz'],
  TABLET:      ['Pantalla', 'Batería', 'Puerto de carga', 'Cámara', 'Botones', 'Altavoz'],
  ORDENADOR:   ['Pantalla', 'Batería', 'Teclado', 'Ventilador', 'Placa base', 'Disco duro'],
  MANDO:       ['Joystick', 'Botones', 'Gatillos', 'Batería', 'Puerto de carga'],
  AURICULARES: ['Batería', 'Altavoz', 'Micrófono', 'Puerto de carga', 'Bluetooth'],
  RELOJ:       ['Pantalla', 'Batería', 'Correa', 'Botones'],
  OTRO:        ['Pantalla', 'Batería', 'Puerto de carga', 'Botones', 'Otro'],
};

@Component({
  selector: 'app-taller',
  templateUrl: './taller.page.html',
  styleUrls: ['./taller.page.scss'],
  imports: [IonHeader, IonContent, IonSegment, IonSegmentButton, IonLabel, IonIcon, IonInput, IonTextarea,
            IonChip, IonButton, IonSpinner, IonSkeletonText, CabeceraComponent],
})
export class TallerPage {
  private sesion = inject(SesionService);
  private reparaciones = inject(ReparacionService);
  private fotos = inject(FotoService);
  private router = inject(Router);
  private ruta = inject(ActivatedRoute);
  private toast = inject(ToastController);

  vista = signal<'nueva' | 'mis'>('nueva');

  // ----- Formulario en 3 pasos (estado con signals)
  paso = signal(1);
  intentado = signal(false);                 // true al pulsar Siguiente → muestra errores
  tipo = signal<TipoDispositivo | null>(null);
  marca = signal('');                        // "Sony"
  modelo = signal('');                       // "PlayStation 5"
  componente = signal('');
  descripcion = signal('');
  listaFotos = signal<string[]>([]);          // dataURL de cada foto
  enviando = signal(false);
  maxFotos = MAX_FOTOS;

  tipos: OpcionTipo[] = [
    { valor: 'CONSOLA', texto: 'Consola', icono: 'game-controller-outline' },
    { valor: 'MOVIL', texto: 'Móvil', icono: 'phone-portrait-outline' },
    { valor: 'TABLET', texto: 'Tablet', icono: 'tablet-landscape-outline' },
    { valor: 'ORDENADOR', texto: 'Ordenador', icono: 'laptop-outline' },
    { valor: 'MANDO', texto: 'Mando', icono: 'keypad-outline' },
    { valor: 'AURICULARES', texto: 'Auriculares', icono: 'headset-outline' },
    { valor: 'RELOJ', texto: 'Reloj', icono: 'watch-outline' },
    { valor: 'OTRO', texto: 'Otro', icono: 'ellipsis-horizontal' },
  ];

  componentes = computed(() => [...COMPONENTES[this.tipo() ?? 'OTRO'], 'No lo sé']);
  textoTipo = computed(() => this.tipos.find(t => t.valor === this.tipo())?.texto ?? '');
  departamento = computed(() => {
    const t = this.tipo();
    return t ? (departamentoDe(t) === 'TELEFONIA' ? 'Telefonía' : 'Consolas') : '';
  });

  // Errores de cada paso
  errorTipo = computed(() => !this.tipo());
  errorMarca = computed(() => this.marca().trim().length < 2);
  errorModelo = computed(() => this.modelo().trim().length < 1);
  errorComponente = computed(() => !this.componente());
  errorDescripcion = computed(() => this.descripcion().trim().length < 10);
  pasoValido = computed(() => this.paso() === 1
    ? !this.errorTipo() && !this.errorMarca() && !this.errorModelo() && !this.errorComponente()
    : this.paso() === 2 ? !this.errorDescripcion() : true);

  // ----- Mis reparaciones
  mias = signal<Reparacion[]>([]);
  cargandoMias = signal(true);

  constructor() {
    addIcons({ gameControllerOutline, phonePortraitOutline, tabletLandscapeOutline, laptopOutline, tvOutline,
               headsetOutline, watchOutline, ellipsisHorizontal, cameraOutline, close, chevronForward, keypadOutline });
  }

  ionViewWillEnter(): void {
    if (this.ruta.snapshot.queryParamMap.get('vista') === 'mis') this.vista.set('mis');   // viene del menú lateral
    this.cargarMias();
  }

  cambiarVista(valor: unknown): void {
    this.vista.set(valor === 'mis' ? 'mis' : 'nueva');
    if (valor === 'mis') this.cargarMias();
  }

  elegirTipo(t: TipoDispositivo): void {
    this.tipo.set(t);
    if (!COMPONENTES[t].includes(this.componente())) this.componente.set('');   // el componente depende del tipo
  }

  siguiente(): void {
    this.intentado.set(true);
    if (!this.pasoValido()) return;
    this.intentado.set(false);
    this.paso.update(p => p + 1);
  }

  atras(): void {
    this.intentado.set(false);
    this.paso.update(p => Math.max(1, p - 1));
  }

  // ----- Cámara
  async anadirFoto(): Promise<void> {
    if (this.listaFotos().length >= MAX_FOTOS) return;
    try {
      const foto = await this.fotos.hacerFoto();
      if (foto) this.listaFotos.update(l => [...l, foto]);
    } catch {
      this.aviso('No se ha podido usar la cámara. Revisa los permisos.', 'danger');
    }
  }

  quitarFoto(i: number): void {
    this.listaFotos.update(l => l.filter((_, pos) => pos !== i));
  }

  // ----- Enviar: sube las fotos y crea la reparación
  enviar(): void {
    const u = this.sesion.usuario();
    const tipo = this.tipo();
    if (!u || !tipo) return;
    this.enviando.set(true);

    const subidas$ = this.listaFotos().length
      ? forkJoin(this.listaFotos().map(f => this.fotos.subir(f, 'soporte')))   // todas a la vez
      : of([] as string[]);

    subidas$.pipe(
      switchMap(urls => this.reparaciones.crear({
        usuarioId: u.id,
        clienteNombre: `${u.nombre} ${u.apellido1[0]}.`,
        tipoDispositivo: tipo,
        marcaModelo: `${this.marca().trim()} ${this.modelo().trim()}`,   // la API lo recibe junto
        componente: this.componente(),
        descripcion: this.descripcion().trim(),
        fotos: urls,
      })),
    ).subscribe({
      next: rep => {
        this.enviando.set(false);
        this.reiniciar();
        this.aviso(`Solicitud #${this.numero(rep.id)} enviada al departamento de ${this.departamentoTexto(rep)}.`, 'dark');
        this.router.navigate(['/taller/reparacion', rep.id]);    // directo al seguimiento
      },
      error: () => {
        this.enviando.set(false);
        this.aviso('No se ha podido enviar la solicitud. Inténtalo de nuevo.', 'danger');
      },
    });
  }

  abrir(rep: Reparacion): void {
    this.router.navigate(['/taller/reparacion', rep.id]);
  }

  // Ayudas para la plantilla
  numero(id: number): string { return String(id).padStart(4, '0'); }
  estadoTexto(r: Reparacion): string { return PASOS_REPARACION.find(p => p.estado === r.estado)?.titulo ?? r.estado; }
  progreso(r: Reparacion): number {
    const orden = PASOS_REPARACION.map(p => p.estado);
    return orden.indexOf(r.estado) / (orden.length - 1);
  }
  tipoTexto(r: Reparacion): string { return this.tipos.find(t => t.valor === r.tipoDispositivo)?.texto ?? ''; }
  private departamentoTexto(r: Reparacion): string { return r.departamento === 'TELEFONIA' ? 'Telefonía' : 'Consolas'; }

  private cargarMias(): void {
    const id = this.sesion.usuario()?.id;
    if (!id) return;
    this.reparaciones.delUsuario(id).subscribe({
      next: lista => { this.mias.set([...lista].reverse()); this.cargandoMias.set(false); },   // la más nueva primero
      error: () => this.cargandoMias.set(false),
    });
  }

  private reiniciar(): void {
    this.paso.set(1); this.intentado.set(false); this.tipo.set(null);
    this.marca.set(''); this.modelo.set(''); this.componente.set(''); this.descripcion.set(''); this.listaFotos.set([]);
  }

  private async aviso(mensaje: string, color: string): Promise<void> {
    const t = await this.toast.create({ message: mensaje, duration: 3000, position: 'bottom', color });
    await t.present();
  }
}
