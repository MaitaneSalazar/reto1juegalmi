import { Component, computed, inject } from '@angular/core';
import { RouterLink } from '@angular/router';
import { IonHeader, IonToolbar, IonButtons, IonBackButton, IonContent, IonFooter, IonButton, IonIcon } from '@ionic/angular';
import { addIcons } from 'ionicons';
import { createOutline } from 'ionicons/icons';
import { SesionService } from '../../services/sesion.service';

const FORMATO = new Intl.DateTimeFormat('es-ES', { day: 'numeric', month: 'short', year: 'numeric' });

@Component({
  selector: 'app-datos-personales',
  templateUrl: './datos-personales.page.html',
  styleUrls: ['../subpagina.scss', './datos-personales.page.scss'],
  imports: [RouterLink, IonHeader, IonToolbar, IonButtons, IonBackButton, IonContent, IonFooter, IonButton, IonIcon],
})
export class DatosPersonalesPage {
  sesion = inject(SesionService);

  // "Cliente desde 1 sept 2025"
  desde = computed(() => {
    const f = this.sesion.usuario()?.fecha_registro;
    return f ? 'Cliente desde ' + FORMATO.format(new Date(f.slice(0, 10) + 'T00:00:00')).replace('.', '') : 'Cliente de JuegAlmi';
  });

  constructor() {
    addIcons({ createOutline });
  }
}
