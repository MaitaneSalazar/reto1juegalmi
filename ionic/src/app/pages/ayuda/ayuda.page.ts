import { Component, inject } from '@angular/core';
import { toSignal } from '@angular/core/rxjs-interop';
import { IonHeader, IonToolbar, IonButtons, IonBackButton, IonTitle, IonContent, IonAccordionGroup,
         IonAccordion, IonItem, IonLabel, IonIcon } from '@ionic/angular';
import { addIcons } from 'ionicons';
import { callOutline, mailOutline } from 'ionicons/icons';
import { TiendaService } from '../../services/tienda.service';

@Component({
  selector: 'app-ayuda',
  templateUrl: './ayuda.page.html',
  styleUrls: ['../cuenta/subpagina.scss', './ayuda.page.scss'],
  imports: [IonHeader, IonToolbar, IonButtons, IonBackButton, IonTitle, IonContent, IonAccordionGroup,
            IonAccordion, IonItem, IonLabel, IonIcon],
})
export class AyudaPage {
  tienda = toSignal(inject(TiendaService).obtener());   // teléfono de la tienda

  preguntas = [
    { p: '¿Cómo alquilo un videojuego?', r: 'En Tienda › Alquilar elige el juego, los días y pulsa Alquilar. Recógelo en la tienda y devuélvelo antes de la fecha indicada.' },
    { p: '¿Qué pasa si me retraso en la devolución?', r: 'El alquiler pasa a "Vencido" y se cobra cada día extra al mismo precio por día.' },
    { p: '¿Cuánto tarda una reparación?', r: 'El diagnóstico suele estar en 48 horas. Te avisamos con el presupuesto antes de reparar nada.' },
    { p: '¿Cuánto cuesta el envío?', r: 'El envío es gratis en todos los pedidos.' },
  ];

  telefono(): string {
    return 'tel:' + (this.tienda()?.telefono ?? '').replace(/\s/g, '');
  }
}
