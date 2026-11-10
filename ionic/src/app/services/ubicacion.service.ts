import { Injectable, signal } from '@angular/core';
import { Geolocation } from '@capacitor/geolocation';

export interface Posicion { lat: number; lon: number; }

const CADUCA_MS = 2 * 60 * 1000;   // una posición vale 2 minutos

@Injectable({ providedIn: 'root' })
export class UbicacionService {
  readonly posicion = signal<Posicion | null>(null);   // última posición conocida
  private hora = 0;                                     // cuándo se obtuvo
  private pendiente: Promise<Posicion | null> | null = null;

  // Pide la posición al GPS (si el usuario no da permiso devuelve null)
  obtener(): Promise<Posicion | null> {
    if (this.pendiente) return this.pendiente;          // no pedirla dos veces a la vez
    this.pendiente = Geolocation.getCurrentPosition({
      enableHighAccuracy: false,                         // precisión normal: gasta menos batería
      timeout: 8000,
      maximumAge: 60000,
    })
      .then(p => {
        const pos = { lat: p.coords.latitude, lon: p.coords.longitude };
        this.posicion.set(pos);
        this.hora = Date.now();
        return pos;
      })
      .catch(() => null)
      .finally(() => { this.pendiente = null; });
    return this.pendiente;
  }

  // Para el interceptor: devuelve la posición guardada al momento;
  // si no hay, espera como mucho "esperaMax" ms para no bloquear la petición
  async actual(esperaMax = 1500): Promise<Posicion | null> {
    const p = this.posicion();
    if (p) {
      if (Date.now() - this.hora > CADUCA_MS) this.obtener();   // se actualiza en segundo plano
      return p;
    }
    return Promise.race([
      this.obtener(),
      new Promise<null>(resolver => setTimeout(() => resolver(null), esperaMax)),
    ]);
  }

  // Distancia en km entre dos puntos
  distanciaKm(a: Posicion, b: Posicion): number {
    const rad = (g: number) => g * Math.PI / 180;
    const dLat = rad(b.lat - a.lat);
    const dLon = rad(b.lon - a.lon);
    const h = Math.sin(dLat / 2) ** 2 + Math.cos(rad(a.lat)) * Math.cos(rad(b.lat)) * Math.sin(dLon / 2) ** 2;
    return 6371 * 2 * Math.atan2(Math.sqrt(h), Math.sqrt(1 - h));
  }
}
