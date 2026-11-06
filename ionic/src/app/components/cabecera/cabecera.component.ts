import { Component } from '@angular/core';
import { IonToolbar, IonButtons, IonMenuButton } from '@ionic/angular';

// Cabecera común: ☰ + logo J + JuegAlmi + hueco a la derecha (cada página pone sus botones)
@Component({
  selector: 'app-cabecera',
  templateUrl: './cabecera.component.html',
  styleUrls: ['./cabecera.component.scss'],
  imports: [IonToolbar, IonButtons, IonMenuButton],
})
export class CabeceraComponent {}
