import { Component, signal } from '@angular/core';
import { IonHeader, IonToolbar, IonButtons, IonBackButton, IonTitle, IonContent, IonToggle } from '@ionic/angular';

const CLAVE = 'juegalmi_notificaciones';
type Preferencias = Record<string, boolean>;

@Component({
  selector: 'app-notificaciones',
  templateUrl: './notificaciones.page.html',
  styleUrls: ['../cuenta/subpagina.scss', './notificaciones.page.scss'],
  imports: [IonHeader, IonToolbar, IonButtons, IonBackButton, IonTitle, IonContent, IonToggle],
})
export class NotificacionesPage {
  opciones = [
    { clave: 'pedidos', titulo: 'Pedidos', texto: 'Cuando tu pedido se envíe o se entregue' },
    { clave: 'alquileres', titulo: 'Alquileres', texto: 'Un día antes de la fecha de devolución' },
    { clave: 'reparaciones', titulo: 'Reparaciones', texto: 'Cuando cambie el estado o haya presupuesto' },
    { clave: 'ofertas', titulo: 'Ofertas', texto: 'Novedades y descuentos de la tienda' },
  ];

  prefs = signal<Preferencias>(this.leer());

  cambiar(clave: string, valor: boolean): void {
    this.prefs.update(p => ({ ...p, [clave]: valor }));
    try { localStorage.setItem(CLAVE, JSON.stringify(this.prefs())); } catch { /* sin almacenamiento */ }
  }

  private leer(): Preferencias {
    const defecto = { pedidos: true, alquileres: true, reparaciones: true, ofertas: false };
    try { return { ...defecto, ...JSON.parse(localStorage.getItem(CLAVE) ?? '{}') }; } catch { return defecto; }
  }
}
