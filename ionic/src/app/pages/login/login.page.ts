import { Component, inject, signal } from '@angular/core';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { Router, RouterLink } from '@angular/router';
import { IonContent, IonInput, IonButton, IonSpinner, MenuController } from '@ionic/angular';
import { SesionService } from '../../services/sesion.service';

@Component({
  selector: 'app-login',
  templateUrl: './login.page.html',
  styleUrls: ['./login.page.scss'],
  imports: [ReactiveFormsModule, RouterLink, IonContent, IonInput, IonButton, IonSpinner],
})
export class LoginPage {
  private sesion = inject(SesionService);
  private router = inject(Router);
  private menu = inject(MenuController);

  cargando = signal(false);   // muestra el spinner en el botón
  error = signal('');         // mensaje de error general

  // Formulario con validaciones
  form = inject(FormBuilder).nonNullable.group({
    email: ['', [Validators.required, Validators.email]],
    password: ['', Validators.required],
  });

  // Sin menú lateral en la pantalla de acceso
  ionViewWillEnter(): void { this.menu.enable(false); }
  ionViewWillLeave(): void { this.menu.enable(true); }

  // true si el campo está mal y el usuario ya lo ha tocado
  invalido(campo: 'email' | 'password'): boolean {
    const c = this.form.controls[campo];
    return c.invalid && c.touched;
  }

  entrar(): void {
    if (this.form.invalid) {                 // marca todos para que se vean los errores
      this.form.markAllAsTouched();
      return;
    }
    this.cargando.set(true);
    this.error.set('');
    const { email, password } = this.form.getRawValue();

    this.sesion.login(email.trim().toLowerCase(), password).subscribe({
      next: usuario => {
        this.cargando.set(false);
        this.form.reset();
        // El técnico va a su panel; el cliente, a Inicio
        this.router.navigateByUrl(usuario.rol === 'TECNICO' ? '/panel' : '/inicio', { replaceUrl: true });
      },
      error: (e: Error) => {
        this.cargando.set(false);
        this.error.set(e.message);
      },
    });
  }
}
