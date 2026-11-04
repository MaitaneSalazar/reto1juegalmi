import { Component, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { IonHeader, IonToolbar, IonButtons, IonBackButton, IonTitle, IonContent, IonInput, IonButton,
         IonSpinner, NavController, ToastController } from '@ionic/angular';
import { SesionService } from '../../services/sesion.service';

type Campo = 'calle' | 'cp' | 'ciudad' | 'provincia';

@Component({
  selector: 'app-direcciones',
  templateUrl: './direcciones.page.html',
  styleUrls: ['../cuenta/subpagina.scss'],
  imports: [ReactiveFormsModule, IonHeader, IonToolbar, IonButtons, IonBackButton, IonTitle, IonContent,
            IonInput, IonButton, IonSpinner],
})
export class DireccionesPage {
  private sesion = inject(SesionService);
  private toast = inject(ToastController);
  private nav = inject(NavController);
  guardando = signal(false);

  form = inject(FormBuilder).nonNullable.group({
    calle: ['', [Validators.required, Validators.minLength(4)]],
    cp: ['', [Validators.required, Validators.pattern(/^\d{5}$/)]],   // código postal: 5 cifras
    ciudad: ['', Validators.required],
    provincia: ['', Validators.required],
  });

  ionViewWillEnter(): void {
    const d = this.sesion.usuario()?.direccion;
    if (d) this.form.reset(d);
  }

  invalido(c: Campo): boolean {
    return this.form.controls[c].invalid && this.form.controls[c].touched;
  }

  guardar(): void {
    if (this.form.invalid) { this.form.markAllAsTouched(); return; }
    this.guardando.set(true);
    this.sesion.actualizarDatos({ direccion: this.form.getRawValue() }).subscribe({
      next: async () => {
        this.guardando.set(false);
        const t = await this.toast.create({ message: 'Dirección guardada.', duration: 2000, color: 'dark' });
        await t.present();
        this.nav.back();          // vuelve a donde estaba (Cuenta o Cesta)
      },
      error: async (e: Error) => {
        this.guardando.set(false);
        const t = await this.toast.create({ message: e.message, duration: 2000, color: 'danger' });
        await t.present();
      },
    });
  }
}
