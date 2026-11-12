import { ElementRef, Injectable, inject } from '@angular/core';
import { takeUntilDestroyed } from '@angular/core/rxjs-interop';
import { Subject } from 'rxjs';
import { Motion } from '@capacitor/motion';

const UMBRAL = 7;           // m/s² de sacudida (sin contar la gravedad) para considerar que se agita
const GRAVEDAD = 9.81;
const ESPERA_MS = 2500;     // evita que una misma sacudida recargue varias veces

@Injectable({ providedIn: 'root' })
export class AgitarService {
  readonly agitado$ = new Subject<void>();   // las pantallas se suscriben (alAgitar) y recargan sus datos
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

  // La pantalla que se está viendo recarga sus datos (sin recargar toda la app)
  private agitado(): void {
    this.agitado$.next();                      // sin aviso: solo se recarga la pantalla (salen los tres puntos)
  }
}

// Para usar en una pantalla: al agitar, si es la que se está viendo, ejecuta «recargar»
export function alAgitar(recargar: () => void): void {
  const el = inject(ElementRef).nativeElement as HTMLElement;
  inject(AgitarService).agitado$.pipe(takeUntilDestroyed()).subscribe(() => {
    if (el.offsetParent !== null && !el.classList.contains('ion-page-hidden')) recargar();   // solo la pantalla visible
  });
}
