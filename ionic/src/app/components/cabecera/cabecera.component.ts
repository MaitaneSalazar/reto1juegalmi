import { Component, inject } from '@angular/core';
import { IonToolbar, IonButtons, IonMenuButton, IonIcon } from '@ionic/angular';
import { addIcons } from 'ionicons';
import { micOutline } from 'ionicons/icons';
import { VozService } from '../../services/voz.service';

// Cabecera común: ☰ + logo J + JuegAlmi + micrófono + hueco a la derecha
@Component({
  selector: 'app-cabecera',
  templateUrl: './cabecera.component.html',
  styleUrls: ['./cabecera.component.scss'],
  imports: [IonToolbar, IonButtons, IonMenuButton, IonIcon],
})
export class CabeceraComponent {
  voz = inject(VozService);

  constructor() {
    addIcons({ micOutline });
  }
}
