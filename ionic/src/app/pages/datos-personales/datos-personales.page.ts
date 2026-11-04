import { Component, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { IonHeader, IonToolbar, IonButtons, IonBackButton, IonTitle, IonContent, IonInput, IonButton,
         IonSpinner, ToastController } from '@ionic/angular';
import { SesionService } from '../../services/sesion.service';
import { telefonoValido } from '../../validators/validadores';

@Component({
  selector: 'app-datos-personales',
  templateUrl: './datos-personales.page.html',
  styleUrls: ['../cuenta/subpagina.scss'],
  imports: [ReactiveFormsModule, IonHeader, IonToolbar, IonButtons, IonBackButton, IonTitle, IonContent,
            IonInput, IonButton, IonSpinner],
})
export class DatosPersonalesPage {
  sesion = inject(SesionService);
  private toast = inject(ToastController);
  guardando = signal(false);

  form = inject(FormBuilder).nonNullable.group({
    nombre: ['', [Validators.required, Validators.minLength(2)]],
    apellido1: ['', [Validators.required, Validators.minLength(2)]],
    apellido2: [''],
    telefono: ['', [Validators.required, telefonoValido]],
  });

  // Rellena el formulario con los datos actuales
  ionViewWillEnter(): void {
    const u = this.sesion.usuario();
    if (u) this.form.reset({ nombre: u.nombre, apellido1: u.apellido1, apellido2: u.apellido2 ?? '', telefono: u.telefono });
  }

  invalido(c: 'nombre' | 'apellido1' | 'telefono'): boolean {
    return this.form.controls[c].invalid && this.form.controls[c].touched;
  }

  guardar(): void {
    if (this.form.invalid) { this.form.markAllAsTouched(); return; }
    this.guardando.set(true);
    this.sesion.actualizarDatos(this.form.getRawValue()).subscribe({
      next: () => { this.guardando.set(false); this.aviso('Datos guardados.', 'dark'); },
      error: (e: Error) => { this.guardando.set(false); this.aviso(e.message, 'danger'); },
    });
  }

  private async aviso(m: string, color: string): Promise<void> {
    const t = await this.toast.create({ message: m, duration: 2000, color });
    await t.present();
  }
}
