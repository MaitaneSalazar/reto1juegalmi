import { ExitoService } from '../../services/exito.service';
import { Component, computed, inject, signal } from '@angular/core';
import { ActivatedRoute } from '@angular/router';
import { FormBuilder, ReactiveFormsModule, Validators } from '@angular/forms';
import { IonHeader, IonToolbar, IonButtons, IonBackButton, IonContent, IonFooter, IonInput, IonButton,
         NavController, ToastController } from '@ionic/angular';
import { SesionService } from '../../services/sesion.service';
import { DomicilioService } from '../../services/domicilio.service';
import { DatosDireccion } from '../../models/domicilio.model';
import { textoError } from '../../validators/validadores';

type Campo = 'calle' | 'numero' | 'codigo_postal' | 'ciudad' | 'provincia';

@Component({
  selector: 'app-direccion',
  templateUrl: './direccion.page.html',
  styleUrls: ['../subpagina.scss'],
  imports: [ReactiveFormsModule, IonHeader, IonToolbar, IonButtons, IonBackButton, IonContent, IonFooter,
            IonInput, IonButton],
})
export class DireccionPage {
  private sesion = inject(SesionService);
  private domicilios = inject(DomicilioService);
  private nav = inject(NavController);
  private toast = inject(ToastController);
  private exito = inject(ExitoService);

  // Ruta /cuenta/direcciones/nueva → null · /cuenta/direcciones/3 → editar el domicilio 3
  id: number | null;
  guardando = signal(false);
  titulo = computed(() => this.id === null ? 'Nueva dirección' : 'Editar dirección');

  form = inject(FormBuilder).nonNullable.group({
    calle: ['', [Validators.required, Validators.minLength(3)]],
    numero: ['', Validators.required],
    piso: [''],
    codigo_postal: ['', [Validators.required, Validators.pattern(/^\d{5}$/)]],   // 5 cifras
    ciudad: ['', Validators.required],
    provincia: ['', Validators.required],
  });

  constructor() {
    const param = inject(ActivatedRoute).snapshot.paramMap.get('id');
    this.id = param === null || param === 'nueva' ? null : Number(param);
  }

  // Si se edita, rellena el formulario con el domicilio elegido
  ionViewWillEnter(): void {
    if (this.id === null) return;
    const d = this.domicilios.lista().find(x => x.id === this.id)?.direccion;
    if (d) this.form.reset({ ...d, piso: d.piso ?? '' });
  }

  // Código postal: vacío → genérico; mal escrito → el concreto (igual que Android)
  errorCp(): string {
    return textoError(this.form.controls.codigo_postal, 'El código postal tiene 5 números');
  }

  invalido(c: Campo): boolean {
    const control = this.form.controls[c];
    return control.invalid && control.touched;
  }

  // Nueva → POST /api/domicilios · Editar → PUT /api/domicilios/{id}
  guardar(): void {
    if (this.form.invalid) { this.form.markAllAsTouched(); return; }
    const v = this.form.getRawValue();
    const datos: DatosDireccion = {
      calle: v.calle.trim(), numero: v.numero.trim(), piso: v.piso.trim() || null,
      codigo_postal: v.codigo_postal, ciudad: v.ciudad.trim(), provincia: v.provincia.trim(),
    };
    if (this.id !== null && !Object.keys(this.cambios(datos)).length) { this.nav.back(); return; }   // nada que guardar
    const llamada = this.id === null ? this.domicilios.crear(datos) : this.domicilios.editar(this.id, this.cambios(datos));

    this.guardando.set(true);
    llamada.subscribe({
      next: async d => {
        this.guardando.set(false);
        if (this.id === null) this.domicilios.elegir(d.id);   // la nueva pasa a ser la de envío
        await this.exito.mostrar('Dirección guardada');
        this.nav.back();
      },
      error: e => { this.guardando.set(false); this.aviso(this.sesion.mensaje(e)); },
    });
  }

  // Solo los campos que han cambiado, p. ej. { piso: '4ºC' }
  private cambios(datos: DatosDireccion): Partial<DatosDireccion> {
    const antes = this.domicilios.lista().find(x => x.id === this.id)?.direccion;
    if (!antes) return datos;
    const c: Record<string, string | null> = {};
    for (const k of Object.keys(datos) as (keyof DatosDireccion)[]) {
      if ((datos[k] ?? null) !== (antes[k] ?? null)) c[k] = datos[k] ?? null;
    }
    return c as Partial<DatosDireccion>;
  }

  private async aviso(m: string): Promise<void> {
    const t = await this.toast.create({ message: m, duration: 2000 });
    await t.present();
  }
}
