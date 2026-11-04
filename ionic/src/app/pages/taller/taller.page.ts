import { Component, computed, inject, signal } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { concatMap, from, last, of, switchMap } from 'rxjs';
import { IonHeader, IonContent, IonSegment, IonSegmentButton, IonLabel, IonIcon, IonInput, IonTextarea,
         IonChip, IonButton, IonSpinner, IonSkeletonText, ToastController } from '@ionic/angular';
import { addIcons } from 'ionicons';
import { gameControllerOutline, phonePortraitOutline, tabletLandscapeOutline, laptopOutline, tvOutline,
         headsetOutline, watchOutline, ellipsisHorizontal, cameraOutline, close, chevronForward, keypadOutline, checkmarkCircleOutline } from 'ionicons/icons';
import { CabeceraComponent } from '../../components/cabecera/cabecera.component';
import { EurosPipe } from '../../pipes/euros.pipe';
import { FechaCortaPipe } from '../../pipes/fecha-corta.pipe';
import { SesionService } from '../../services/sesion.service';
import { ReparacionService } from '../../services/reparacion.service';
import { FotoService } from '../../services/foto.service';
import { NOMBRE_DISPOSITIVO, Reparacion, TipoDispositivo } from '../../models/reparacion.model';

interface OpcionTipo { valor: TipoDispositivo; texto: string; icono: string; }

const MAX_FOTOS = 5;   // la API admite hasta 5 fotos por reparación

// Componentes que se ofrecen según el dispositivo
const COMPONENTES: Record<TipoDispositivo, string[]> = {
  consola:     ['HDMI', 'Ventilador', 'Lector de discos', 'Placa base', 'Puerto de carga', 'Botones'],
  movil:       ['Pantalla', 'Batería', 'Puerto de carga', 'Cámara', 'Botones', 'Altavoz'],
  tablet:      ['Pantalla', 'Batería', 'Puerto de carga', 'Cámara', 'Botones', 'Altavoz'],
  ordenador:   ['Pantalla', 'Batería', 'Teclado', 'Ventilador', 'Placa base', 'Disco duro'],
  mando:       ['Joystick', 'Botones', 'Gatillos', 'Batería', 'Puerto de carga'],
  auriculares: ['Batería', 'Altavoz', 'Micrófono', 'Puerto de carga', 'Bluetooth'],
  reloj:       ['Pantalla', 'Batería', 'Correa', 'Botones'],
  otro:        ['Pantalla', 'Batería', 'Puerto de carga', 'Botones', 'Otro'],
};

@Component({
  selector: 'app-taller',
  templateUrl: './taller.page.html',
  styleUrls: ['./taller.page.scss'],
  imports: [IonHeader, IonContent, IonSegment, IonSegmentButton, IonLabel, IonIcon, IonInput, IonTextarea,
            IonChip, IonButton, IonSpinner, IonSkeletonText, CabeceraComponent, EurosPipe, FechaCortaPipe],
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
    { valor: 'consola', texto: 'Consola', icono: 'game-controller-outline' },
    { valor: 'movil', texto: 'Móvil', icono: 'phone-portrait-outline' },
    { valor: 'tablet', texto: 'Tablet', icono: 'tablet-landscape-outline' },
    { valor: 'ordenador', texto: 'Ordenador', icono: 'laptop-outline' },
    { valor: 'mando', texto: 'Mando', icono: 'keypad-outline' },
    { valor: 'auriculares', texto: 'Auriculares', icono: 'headset-outline' },
    { valor: 'reloj', texto: 'Reloj', icono: 'watch-outline' },
    { valor: 'otro', texto: 'Otro', icono: 'ellipsis-horizontal' },
  ];

  componentes = computed(() => [...COMPONENTES[this.tipo() ?? 'otro'], 'No lo sé']);
  textoTipo = computed(() => this.tipos.find(t => t.valor === this.tipo())?.texto ?? '');

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
  enCurso = computed(() => this.mias().filter(r => r.estado !== 'entregada' && r.estado !== 'cancelada'));
  entregadas = computed(() => this.mias().filter(r => r.estado === 'entregada'));
  vuelta = 2 * Math.PI * 26;                 // perímetro del círculo de progreso (radio 26)

  constructor() {
    addIcons({ gameControllerOutline, phonePortraitOutline, tabletLandscapeOutline, laptopOutline, tvOutline,
               headsetOutline, watchOutline, ellipsisHorizontal, cameraOutline, close, chevronForward, keypadOutline, checkmarkCircleOutline });
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

  // ----- Enviar: POST /api/reparaciones y después sube las fotos con su id
  enviar(): void {
    const tipo = this.tipo();
    if (!tipo) return;
    this.enviando.set(true);
    const componente = this.componente() === 'No lo sé' ? undefined : this.componente();

    this.reparaciones.crear({
      tipo_dispositivo: tipo,
      marca: this.marca().trim(),
      modelo: this.modelo().trim(),
      componente,
      descripcion_averia: this.descripcion().trim(),
    }).pipe(
      // Fotos una detrás de otra (multipart, campo "imagen")
      switchMap(rep => this.listaFotos().length
        ? from(this.listaFotos()).pipe(
            concatMap((f, i) => this.reparaciones.subirFoto(rep.id, this.fotos.aBlob(f), `foto${i + 1}.${this.fotos.extension(f)}`)),
            last())
        : of(rep)),
    ).subscribe({
      next: rep => {
        this.enviando.set(false);
        this.reiniciar();
        this.aviso(`Solicitud ${rep.numero} enviada. Te avisaremos con el presupuesto.`, 'dark');
        this.router.navigate(['/taller/reparacion', rep.id]);    // directo al seguimiento
      },
      error: e => {
        this.enviando.set(false);
        this.aviso(this.sesion.mensaje(e), 'danger');
      },
    });
  }

  abrir(rep: Reparacion): void {
    this.router.navigate(['/taller/reparacion', rep.id]);
  }

  // Ayudas para la plantilla (paso, total_pasos y estado_texto ya vienen calculados de la API)
  hueco(r: Reparacion): number { return this.vuelta * (1 - r.paso / r.total_pasos); }
  tipoTexto(r: Reparacion): string { return NOMBRE_DISPOSITIVO[r.tipo_dispositivo] ?? ''; }

  // GET /api/reparaciones (la más reciente primero)
  private cargarMias(): void {
    this.reparaciones.listar(1, 50).subscribe({
      next: r => { this.mias.set(r.datos); this.cargandoMias.set(false); },
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
