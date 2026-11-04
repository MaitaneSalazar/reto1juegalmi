import { Component, ElementRef, effect, inject, viewChild } from '@angular/core';
import { IonTabs, IonTabBar, IonTabButton, IonIcon, IonLabel, AnimationController } from '@ionic/angular';
import { addIcons } from 'ionicons';
import { homeOutline, storefrontOutline, buildOutline, bagHandleOutline,
         informationCircleOutline, personOutline } from 'ionicons/icons';
import { CestaService } from '../services/cesta.service';

interface Pestana { ruta: string; titulo: string; icono: string; }

@Component({
  selector: 'app-tabs',
  templateUrl: 'tabs.page.html',
  styleUrls: ['tabs.page.scss'],
  imports: [IonTabs, IonTabBar, IonTabButton, IonIcon, IonLabel],
})
export class TabsPage {
  cesta = inject(CestaService);
  private animaciones = inject(AnimationController);
  private badge = viewChild('badge', { read: ElementRef });   // <span #badge>
  private anterior = this.cesta.unidades();

  pestanas: Pestana[] = [
    { ruta: 'inicio',   titulo: 'Inicio',   icono: 'home-outline' },
    { ruta: 'tienda',   titulo: 'Tienda',   icono: 'storefront-outline' },
    { ruta: 'taller',   titulo: 'Taller',   icono: 'build-outline' },
    { ruta: 'cesta',    titulo: 'Cesta',    icono: 'bag-handle-outline' },
    { ruta: 'nosotros', titulo: 'Nosotros', icono: 'information-circle-outline' },
    { ruta: 'cuenta',   titulo: 'Cuenta',   icono: 'person-outline' },
  ];

  constructor() {
    addIcons({ homeOutline, storefrontOutline, buildOutline, bagHandleOutline,
               informationCircleOutline, personOutline });

    // Al añadir algo a la cesta, el punto rojo bota
    effect(() => {
      const unidades = this.cesta.unidades();
      if (unidades > this.anterior) setTimeout(() => this.botar());
      this.anterior = unidades;
    });
  }

  private botar(): void {
    const el = this.badge()?.nativeElement as HTMLElement | undefined;
    if (!el) return;
    this.animaciones.create()
      .addElement(el)
      .duration(450)
      .easing('cubic-bezier(.34, 1.56, .64, 1)')
      .keyframes([
        { offset: 0, transform: 'scale(1)' },
        { offset: 0.4, transform: 'scale(1.8)' },
        { offset: 1, transform: 'scale(1)' },
      ])
      .play();
  }
}
