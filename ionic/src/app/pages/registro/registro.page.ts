import { Component, inject, signal } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { IonContent, IonInput, IonButton, IonSpinner, MenuController } from '@ionic/angular';
import { SesionService } from '../../services/sesion.service';
import { dniValido, telefonoValido } from '../../validators/validadores';

const BORRADOR = 'juegalmi_registro';   // clave en sessionStorage

type Campo = 'nombre' | 'apellido1' | 'apellido2' | 'dni' | 'telefono' | 'email' | 'password';

@Component({
  selector: 'app-registro',
  templateUrl: './registro.page.html',
  styleUrls: ['../login/login.page.scss', './registro.page.scss'],   // reutiliza los estilos del login
  imports: [ReactiveFormsModule, RouterLink, IonContent, IonInput, IonButton, IonSpinner],
})
export class RegistroPage {
  private sesion = inject(SesionService);
  private router = inject(Router);
  private menu = inject(MenuController);

  cargando = signal(false);
  error = signal('');

  form = inject(FormBuilder).nonNullable.group({
    nombre: ['', [Validators.required, Validators.minLength(2)]],
    apellido1: ['', [Validators.required, Validators.minLength(2)]],
    apellido2: [''],                                               // opcional
    dni: ['', [Validators.required, dniValido]],
    telefono: ['', telefonoValido],                               // opcional
    email: ['', [Validators.required, Validators.email]],
    password: ['', [Validators.required, Validators.minLength(6)]],
  });

  // Mensaje de error de cada campo
  mensajes: Record<Campo, string> = {
    nombre: 'Escribe tu nombre.',
    apellido1: 'Escribe tu primer apellido.',
    apellido2: '',
    dni: 'DNI o NIE no válido (12345678Z o X1234567L).',
    telefono: 'Teléfono no válido (9 cifras).',
    email: 'Introduce un email válido.',
    password: 'Mínimo 6 caracteres.',
  };

  constructor() {
    // sessionStorage: si sales y vuelves en la misma sesión, el formulario conserva lo escrito
    try {
      const guardado = sessionStorage.getItem(BORRADOR);
      if (guardado) this.form.patchValue(JSON.parse(guardado));
    } catch { /* sin almacenamiento */ }

    this.form.valueChanges.pipe(takeUntilDestroyed()).subscribe(valor => {
      const { password: _, ...sinClave } = valor;                  // la contraseña nunca se guarda
      try { sessionStorage.setItem(BORRADOR, JSON.stringify(sinClave)); } catch { /* sin almacenamiento */ }
    });
  }

  ionViewWillEnter(): void { this.menu.enable(false); }
  ionViewWillLeave(): void { this.menu.enable(true); }

  invalido(campo: Campo): boolean {
    const c = this.form.controls[campo];
    return c.invalid && c.touched;
  }

  registrar(): void {
    if (this.form.invalid) {
      this.form.markAllAsTouched();
      return;
    }
    this.cargando.set(true);
    this.error.set('');
    const v = this.form.getRawValue();

    this.sesion.registrar({
      ...v,
      email: v.email.trim().toLowerCase(),
      dni: v.dni.trim().toUpperCase(),
      telefono: v.telefono.replace(/\s/g, '') || undefined,      // opcional
      apellido2: v.apellido2.trim() || undefined,
    }).subscribe({
      next: () => {
        this.cargando.set(false);
        try { sessionStorage.removeItem(BORRADOR); } catch { /* sin almacenamiento */ }
        this.form.reset();
        this.router.navigateByUrl('/inicio', { replaceUrl: true });   // ya queda dentro
      },
      error: (e: Error) => {
        this.cargando.set(false);
        this.error.set(e.message);
      },
    });
  }
}
