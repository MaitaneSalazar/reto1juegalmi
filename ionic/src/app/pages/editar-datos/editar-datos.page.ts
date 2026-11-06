import { Component, inject, signal } from '@angular/core';
import { AbstractControl, FormBuilder, ReactiveFormsModule, ValidationErrors, Validators } from '@angular/forms';
import { IonHeader, IonToolbar, IonButtons, IonBackButton, IonContent, IonFooter, IonInput, IonButton,
         IonIcon, IonSpinner, NavController, ToastController } from '@ionic/angular';
import { addIcons } from 'ionicons';
import { cameraOutline, lockClosedOutline } from 'ionicons/icons';
import { SesionService } from '../../services/sesion.service';
import { FotoService } from '../../services/foto.service';
import { telefonoValido } from '../../validators/validadores';

type Campo = 'nombre' | 'apellido1' | 'telefono' | 'password_actual' | 'password_nueva';

// Contraseña: o las dos vacías (no se cambia) o las dos rellenas
function parejaContrasena(g: AbstractControl): ValidationErrors | null {
  const actual = g.get('password_actual'), nueva = g.get('password_nueva');
  const unaSola = !!actual?.value !== !!nueva?.value;
  actual?.setErrors(unaSola && !actual.value ? { required: true } : null);
  if (unaSola && !nueva?.value) nueva?.setErrors({ required: true });
  else if (nueva?.value && nueva.value.length < 6) nueva.setErrors({ minlength: true });
  else nueva?.setErrors(null);
  return null;
}

@Component({
  selector: 'app-editar-datos',
  templateUrl: './editar-datos.page.html',
  styleUrls: ['../cuenta/subpagina.scss', '../datos-personales/datos-personales.page.scss', './editar-datos.page.scss'],
  imports: [ReactiveFormsModule, IonHeader, IonToolbar, IonButtons, IonBackButton, IonContent, IonFooter,
            IonInput, IonButton, IonIcon, IonSpinner],
})
export class EditarDatosPage {
  sesion = inject(SesionService);
  private fotos = inject(FotoService);
  private nav = inject(NavController);
  private toast = inject(ToastController);

  guardando = signal(false);
  foto = signal<string | null>(null);          // foto nueva (o la que ya tenía)

  form = inject(FormBuilder).nonNullable.group({
    nombre: ['', [Validators.required, Validators.minLength(2)]],
    apellido1: ['', [Validators.required, Validators.minLength(2)]],
    apellido2: [''],
    telefono: ['', telefonoValido],             // opcional, pero si se pone tiene que ser válido
    password_actual: [''],
    password_nueva: [''],
  }, { validators: parejaContrasena });

  constructor() {
    addIcons({ cameraOutline, lockClosedOutline });
  }

  // Rellena el formulario con los datos actuales
  ionViewWillEnter(): void {
    const u = this.sesion.usuario();
    if (!u) return;
    this.form.reset({ nombre: u.nombre, apellido1: u.apellido1, apellido2: u.apellido2 ?? '', telefono: u.telefono ?? '',
                     password_actual: '', password_nueva: '' });
    this.foto.set(u.foto_perfil ?? null);
  }

  invalido(c: Campo): boolean {
    const control = this.form.controls[c];
    return control.invalid && control.touched;
  }

  // Botón de la cámara sobre el avatar
  async cambiarFoto(): Promise<void> {
    try {
      const nueva = await this.fotos.hacerFoto();
      if (nueva) this.foto.set(nueva);
    } catch {
      this.aviso('No se ha podido usar la cámara. Revisa los permisos.', 'danger');
    }
  }

  guardar(): void {
    if (this.form.invalid) { this.form.markAllAsTouched(); return; }
    this.guardando.set(true);
    // PUT /api/yo: solo lo que cambia (vacío → null). La foto solo si es nueva
    const v = this.form.getRawValue();
    const datos: Record<string, string | null> = {
      nombre: v.nombre.trim(), apellido1: v.apellido1.trim(),
      apellido2: v.apellido2.trim() || null, telefono: v.telefono.trim() || null,
    };
    if (this.foto() && this.foto() !== this.sesion.usuario()?.foto_perfil) datos['foto_perfil'] = this.foto();
    if (v.password_nueva) { datos['password_actual'] = v.password_actual; datos['password_nueva'] = v.password_nueva; }
    this.sesion.actualizarDatos(datos).subscribe({
      next: () => { this.guardando.set(false); this.aviso('Datos guardados.', 'dark'); this.nav.back(); },
      error: e => { this.guardando.set(false); this.aviso(this.sesion.mensaje(e), 'danger'); },   // p. ej. contraseña actual incorrecta
    });
  }

  private async aviso(m: string, color: string): Promise<void> {
    const t = await this.toast.create({ message: m, duration: 2000, color });
    await t.present();
  }
}
