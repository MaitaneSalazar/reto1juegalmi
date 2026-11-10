import { Injectable, inject } from '@angular/core';
import { Motion } from '@capacitor/motion';
import { ToastController } from '@ionic/angular';

const UMBRAL = 15;          // m/s² de sacudida (sin contar la gravedad) para considerar que se agita
const GRAVEDAD = 9.81;
const ESPERA_MS = 2500;     // evita que una misma sacudida recargue varias veces

@Injectable({ providedIn: 'root' })
export class AgitarService {
  private toast = inject(ToastController);
  private ultimo = 0;
  private activo = false;

  // Se llama una vez al abrir la app
  async iniciar(): Promise<void> {
    if (this.activo) return;
    this.activo = true;
    try {
      await Motion.addListener('accel', e => {
        const fuerza = this.fuerza(e.acceleration, e.accelerationIncludingGravity);
        if (fuerza > UMBRAL && Date.now() - this.ultimo > ESPERA_MS) {
          this.ultimo = Date.now();
          this.agitado();
        }
      });
    } catch {
      // Sin acelerómetro (ordenador): no pasa nada
    }
  }

  // Intensidad del movimiento; si el móvil no da la aceleración "limpia", se le resta la gravedad
  private fuerza(a: { x: number; y: number; z: number } | null, g: { x: number; y: number; z: number } | null): number {
    if (a && a.x != null && a.y != null && a.z != null) return Math.hypot(a.x, a.y, a.z);
    if (g && g.x != null) return Math.abs(Math.hypot(g.x, g.y, g.z) - GRAVEDAD);
    return 0;
  }

  // Aviso y recarga de la pantalla actual (la sesión y la cesta se conservan)
  private async agitado(): Promise<void> {
    const t = await this.toast.create({ message: 'Has agitado el móvil: recargando…', duration: 900, position: 'top' });
    await t.present();
    setTimeout(() => window.location.reload(), 700);
  }
}
