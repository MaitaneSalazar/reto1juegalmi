#!/bin/bash
# =====================================================================
# PASO 18 · Pulido final según Mockups.html y Prueba_interactiva.html
#   - Alquilar: los juegos sin copias libres salen apagados y en gris legible (#686A62)
#   - Editar datos: aviso «El DNI y el email no se pueden cambiar» + cambio de contraseña
#     (PUT /api/yo con password_actual y password_nueva)
# Uso (desde la carpeta ionic/):   bash paso18-pulido-mockups.sh
# =====================================================================
set -e
if [ ! -f angular.json ] || [ ! -f src/app/components/estado/estado.component.ts ]; then
  echo "✘ Ejecútalo dentro de ionic/ y con el paso 17 (mejoras del prototipo) aplicado"; exit 1
fi
tar czf ../ionic-src-antes-paso18.tgz src
echo "• Copia de seguridad: ../ionic-src-antes-paso18.tgz"

mkdir -p $(dirname src/app/pages/editar-datos/editar-datos.page.html)
cat > src/app/pages/editar-datos/editar-datos.page.html <<'JUEGALMI_EOF'
<ion-header class="ion-no-border">
  <ion-toolbar>
    <ion-buttons slot="start"><ion-back-button defaultHref="/cuenta/datos-personales" text=""></ion-back-button></ion-buttons>
  </ion-toolbar>
</ion-header>

<ion-content class="ion-padding">
  <h1 class="titulo">Editar datos</h1>

  <!-- Avatar con botón de cámara -->
  <div class="foto">
    <button type="button" class="avatar" (click)="cambiarFoto()" aria-label="Cambiar foto">
      @if (foto(); as f) { <img [src]="f" alt="Foto de perfil"> } @else { {{ sesion.iniciales() }} }
      <span class="camara"><ion-icon name="camera-outline"></ion-icon></span>
    </button>
    <span>Cambiar foto</span>
  </div>

  @if (sesion.usuario(); as u) {
    <form [formGroup]="form" (ngSubmit)="guardar()" novalidate>
      <div class="campo">
        <label>Nombre</label>
        <ion-input formControlName="nombre" autocomplete="given-name" aria-label="Nombre" [class.mal]="invalido('nombre')"></ion-input>
        @if (invalido('nombre')) { <p class="error">Escribe tu nombre.</p> }
      </div>

      <div class="fila2">
        <div class="campo">
          <label>Primer apellido</label>
          <ion-input formControlName="apellido1" aria-label="Primer apellido" [class.mal]="invalido('apellido1')"></ion-input>
          @if (invalido('apellido1')) { <p class="error">Escribe el apellido.</p> }
        </div>
        <div class="campo">
          <label>Segundo <small>(opcional)</small></label>
          <ion-input formControlName="apellido2" aria-label="Segundo apellido"></ion-input>
        </div>
      </div>

      <div class="campo">
        <label>Teléfono <small>(opcional)</small></label>
        <ion-input formControlName="telefono" type="tel" inputmode="tel" aria-label="Teléfono" [class.mal]="invalido('telefono')"></ion-input>
        @if (invalido('telefono')) { <p class="error">Teléfono de 9 cifras (empieza por 6, 7, 8 o 9).</p> }
      </div>

      <!-- DNI y email no se pueden cambiar -->
      <div class="campo">
        <label>DNI</label>
        <div class="fijo">{{ u.dni }} <ion-icon name="lock-closed-outline"></ion-icon></div>
      </div>
      <div class="campo">
        <label>Email</label>
        <div class="fijo">{{ u.email }} <ion-icon name="lock-closed-outline"></ion-icon></div>
      </div>
      <p class="nota">El DNI y el email no se pueden cambiar.</p>

      <!-- Contraseña: solo si se quiere cambiar (PUT /api/yo con password_actual y password_nueva) -->
      <h2>Contraseña</h2>
      <div class="campo">
        <label>Contraseña actual</label>
        <ion-input formControlName="password_actual" type="password" autocomplete="current-password"
                   aria-label="Contraseña actual" [class.mal]="invalido('password_actual')"></ion-input>
        @if (invalido('password_actual')) { <p class="error">Escribe tu contraseña actual.</p> }
      </div>
      <div class="campo">
        <label>Nueva contraseña</label>
        <ion-input formControlName="password_nueva" type="password" autocomplete="new-password" placeholder="Mínimo 6 caracteres"
                   aria-label="Nueva contraseña" [class.mal]="invalido('password_nueva')"></ion-input>
        @if (invalido('password_nueva')) { <p class="error">Mínimo 6 caracteres.</p> }
      </div>
    </form>
  }
</ion-content>

<ion-footer class="ion-no-border">
  <div class="pie-boton">
    <ion-button expand="block" (click)="guardar()" [disabled]="guardando()">
      @if (guardando()) { <ion-spinner name="crescent"></ion-spinner> } @else { Guardar cambios }
    </ion-button>
  </div>
</ion-footer>
JUEGALMI_EOF

mkdir -p $(dirname src/app/pages/editar-datos/editar-datos.page.scss)
cat > src/app/pages/editar-datos/editar-datos.page.scss <<'JUEGALMI_EOF'
.foto {
  display: flex; flex-direction: column; align-items: center; gap: 12px; margin: -4px 0 26px;
  span { font-size: 16px; font-weight: 500; }
}
.foto .avatar { position: relative; border: 0; overflow: visible; font-family: inherit; cursor: pointer; }
.foto .avatar img { border-radius: 50%; }
.camara {
  position: absolute; right: -6px; bottom: -6px;
  width: 42px; height: 42px; border-radius: 50%;
  display: flex; align-items: center; justify-content: center;
  background: #1f2329; color: #ffffff; font-size: 18px;
  border: 4px solid var(--ion-background-color);
}

.nota { margin: -8px 0 0; color: var(--jg-texto-sec); font-size: 13px; }
h2 { margin: 18px 0 0; }
JUEGALMI_EOF

mkdir -p $(dirname src/app/pages/editar-datos/editar-datos.page.ts)
cat > src/app/pages/editar-datos/editar-datos.page.ts <<'JUEGALMI_EOF'
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
JUEGALMI_EOF

mkdir -p $(dirname src/app/pages/tienda/tienda.page.html)
cat > src/app/pages/tienda/tienda.page.html <<'JUEGALMI_EOF'
<ion-header class="ion-no-border">
  <app-cabecera>
    <!-- Buscador por voz: se pone turquesa y late mientras escucha -->
    <button type="button" class="redondo microfono" [class.activo]="voz.escuchando()" (click)="buscarPorVoz()"
            [attr.aria-label]="voz.escuchando() ? 'Escuchando…' : 'Buscar por voz'">
      <ion-icon name="mic-outline"></ion-icon>
    </button>
    <button type="button" class="redondo" (click)="alternarBuscador()" [attr.aria-label]="buscando() ? 'Cerrar buscador' : 'Buscar'">
      <ion-icon [name]="buscando() ? 'close-outline' : 'search-outline'"></ion-icon>
    </button>
  </app-cabecera>
</ion-header>

<ion-content class="ion-padding">
  <h1 class="titulo">{{ modo() === 'alquilar' ? 'Alquilar' : 'Tienda' }}</h1>

  @if (buscando()) {
    <ion-searchbar placeholder="Buscar productos" [debounce]="300" [value]="texto()"
                   (ionInput)="buscar($event.detail.value)"></ion-searchbar>
  }

  <ion-segment [value]="modo()" (ionChange)="cambiarModo($event.detail.value)">
    <ion-segment-button value="comprar"><ion-label>Comprar</ion-label></ion-segment-button>
    <ion-segment-button value="alquilar"><ion-label>Alquilar</ion-label></ion-segment-button>
  </ion-segment>

  <div class="chips">
    @for (f of (modo() === 'comprar' ? filtrosComprar : filtrosAlquilar); track f.valor) {
      <ion-chip class="filtro" [class.activo]="filtro() === f.valor" (click)="elegirFiltro(f.valor)">{{ f.etiqueta }}</ion-chip>
    }
  </div>

  @if (error()) {
    <app-estado [error]="true" (reintentar)="cargar()"></app-estado>
  } @else if (cargando()) {
    <!-- Huesos grises mientras llega la API -->
    <div class="rejilla">
      @for (i of [1, 2, 3, 4]; track i) {
        <div class="hueso"><ion-skeleton-text [animated]="true" class="esq-foto"></ion-skeleton-text>
          <ion-skeleton-text [animated]="true" style="width: 80%"></ion-skeleton-text>
          <ion-skeleton-text [animated]="true" style="width: 40%"></ion-skeleton-text></div>
      }
    </div>
  } @else if (!productos().length) {
    @if (texto()) {
      <app-estado icono="search-outline" titulo="Sin resultados" [texto]="'No encontramos nada con «' + texto() + '». Prueba con otra palabra.'"></app-estado>
    } @else {
      <app-estado titulo="Aún no hay productos" texto="Estamos reponiendo la tienda. Vuelve en un rato o mira otra categoría."></app-estado>
    }
  } @else {
    <!-- Rejilla de 2 columnas -->
    <div class="rejilla cascada">
      @for (p of productos(); track p.id) {
        <button type="button" class="producto pulsable" [class.alquilado]="modo() === 'alquilar' && stock(p)?.tipo === 'off'" (click)="abrir(p)">
          <span class="foto">
            <app-miniatura-producto [producto]="p"></app-miniatura-producto>
            @if (stock(p); as e) { <span class="stock" [class.aviso]="e.tipo === 'aviso'">{{ e.texto }}</span> }
          </span>
          <span class="nombre">{{ p.nombre }}</span>
          @if (modo() === 'alquilar') { <app-precio [valor]="p.precio_alquiler_dia ?? 0" sufijo="/ día"></app-precio> }
          @else { <app-precio [valor]="p.precio_venta"></app-precio> }
        </button>
      }
    </div>

    <ion-infinite-scroll [disabled]="!hayMas()" (ionInfinite)="cargarMas($event)">
      <ion-infinite-scroll-content loadingSpinner="crescent"></ion-infinite-scroll-content>
    </ion-infinite-scroll>
  }
</ion-content>
JUEGALMI_EOF

mkdir -p $(dirname src/app/pages/tienda/tienda.page.scss)
cat > src/app/pages/tienda/tienda.page.scss <<'JUEGALMI_EOF'
ion-searchbar { --background: var(--jg-tarjeta); --border-radius: 999px; --box-shadow: none; padding: 0 0 14px; }

.producto { border: 0; padding: 0; background: none; font: inherit; color: var(--ion-text-color); text-align: left; }

// Rejilla de 2 columnas
.rejilla { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 14px; }
.producto {
  display: flex; flex-direction: column; gap: 4px; min-width: 0;
  .nombre { font-size: 15px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; margin-top: 6px; }
  app-precio { font-size: 22px; }
}
.foto {
  position: relative; display: block; aspect-ratio: 4 / 5;
  app-miniatura-producto { --tam: 100%; --radio: 22px; --fondo: var(--jg-tarjeta); width: 100%; height: 100%; }
}

// Alquilar: sin copias libres → apagado y textos en gris legible (#686A62, contraste 4,8:1)
.producto.alquilado {
  app-miniatura-producto { opacity: .55; }
  .nombre, app-precio { color: #686a62; }
}

// Etiqueta de stock: «Quedan 2», «Última unidad» (rojo) · «Agotado», «Alquilado» (blanco)
.stock {
  position: absolute; top: 10px; left: 10px; z-index: 1;
  padding: 4px 10px; border-radius: 999px;
  background: #ffffff; color: #1f2329; font-size: 11px; font-weight: 600;
  box-shadow: 0 2px 8px rgba(0, 0, 0, .12);
  &.aviso { background: #a72144; color: #ffffff; }
}

// Huesos grises mientras carga
.hueso { display: flex; flex-direction: column; gap: 6px; }
.esq-foto { aspect-ratio: 4 / 5; height: auto; border-radius: 22px; margin: 0 0 4px; }

// Micrófono del buscador: turquesa y latiendo mientras escucha
.microfono.activo {
  background: var(--jg-acento);
  color: #1f2329;
  animation: latido 1s ease-in-out infinite;
}
@keyframes latido {
  0%, 100% { box-shadow: 0 0 0 0 rgba(120, 205, 208, .6); }
  50%      { box-shadow: 0 0 0 10px rgba(120, 205, 208, 0); }
}
JUEGALMI_EOF

grep -rl "@ionic/angular/standalone" src | xargs -r sed -i "s#@ionic/angular/standalone#@ionic/angular#g"

echo ""
echo "✔ Paso 18 aplicado: alquilados en gris y cambio de contraseña en Editar datos."
echo "  Prueba: npx ng test --watch=false   y   ionic serve"
