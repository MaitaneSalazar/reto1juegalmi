import { Injectable, inject, signal } from '@angular/core';
import { Capacitor } from '@capacitor/core';
import { SpeechRecognition } from '@capacitor-community/speech-recognition';
import { ToastController } from '@ionic/angular';

// Orden de voz que lleva a otra parte de la app
export interface OrdenVoz { ruta: string; query?: Record<string, string>; texto: string; }

// Palabras clave → pantalla (de la más concreta a la más general; sin tildes)
const ORDENES: { claves: string[]; orden: OrdenVoz }[] = [
  { claves: ['mis pedidos', 'pedidos'],                      orden: { ruta: '/cuenta/pedidos', texto: 'Mis pedidos' } },
  { claves: ['mis alquileres', 'alquileres'],                orden: { ruta: '/cuenta/alquileres', texto: 'Mis alquileres' } },
  { claves: ['mis reparaciones', 'reparaciones'],            orden: { ruta: '/taller', query: { vista: 'mis' }, texto: 'Mis reparaciones' } },
  { claves: ['direcciones', 'direccion de envio'],           orden: { ruta: '/cuenta/direcciones', texto: 'Direcciones' } },
  { claves: ['mis datos', 'datos personales', 'perfil'],     orden: { ruta: '/cuenta/datos-personales', texto: 'Datos personales' } },
  { claves: ['cesta', 'carrito'],                            orden: { ruta: '/cesta', texto: 'Cesta' } },
  { claves: ['taller', 'reparar', 'reparacion'],             orden: { ruta: '/taller', texto: 'Taller' } },
  { claves: ['nosotros', 'donde estais', 'ubicacion', 'horario'], orden: { ruta: '/nosotros', texto: 'Sobre nosotros' } },
  { claves: ['alquilar', 'modo alquiler'],                   orden: { ruta: '/tienda', query: { modo: 'alquilar' }, texto: 'Alquilar' } },
  { claves: ['comprar', 'modo compra'],                      orden: { ruta: '/tienda', query: { modo: 'comprar' }, texto: 'Comprar' } },
  { claves: ['inicio', 'portada'],                           orden: { ruta: '/inicio', texto: 'Inicio' } },
];

// Micrófono de la Tienda: busca productos o lleva a otra parte de la app («ir a la cesta»)
@Injectable({ providedIn: 'root' })
export class VozService {
  private toast = inject(ToastController);

  escuchando = signal(false);              // el micrófono está abierto (anima el botón)

  // Botón del micrófono: devuelve lo que se ha dicho ("" si no se ha entendido)
  async escuchar(): Promise<string> {
    if (this.escuchando()) return '';
    this.escuchando.set(true);
    try {
      const frase = Capacitor.isNativePlatform() ? await this.escucharNativo() : await this.escucharWeb();
      const texto = this.textoBusqueda(frase);
      if (!texto) this.aviso('No te he oído. Pulsa el micrófono y di, por ejemplo, «Zelda».');
      return texto;
    } catch (e) {
      this.aviso(e instanceof Error ? e.message : 'No te he entendido. Inténtalo otra vez.');
      return '';
    } finally {
      this.escuchando.set(false);
    }
  }

  // "Buscar Zelda." → "zelda" · "¿Tenéis la PlayStation?" → "tenéis la playstation"
  textoBusqueda(frase: string): string {
    return frase.toLowerCase()
      .replace(/[¿?¡!.,]/g, '')                    // sin signos
      .replace(/^\s*(buscar|busca|busco)\s+/, '')  // sin la palabra "buscar" del principio
      .trim();
  }

  // «Ir a la cesta», «abre mis pedidos», «modo alquiler»... → orden; si no es una orden → null (se busca)
  orden(frase: string): OrdenVoz | null {
    if (/^\s*(buscar|busca|busco)\b/i.test(frase)) return null;            // «buscar …» siempre busca
    const t = ' ' + frase.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '')   // sin tildes
      .replace(/[¿?¡!.,]/g, '').trim() + ' ';
    return ORDENES.find(o => o.claves.some(c => t.includes(' ' + c + ' ')))?.orden ?? null;
  }

  // ----- Móvil (Android / iOS): plugin de Capacitor
  private async escucharNativo(): Promise<string> {
    const { available } = await SpeechRecognition.available();
    if (!available) throw new Error('El reconocimiento de voz no está disponible en este móvil.');
    const permiso = await SpeechRecognition.requestPermissions();
    if (permiso.speechRecognition !== 'granted') throw new Error('Necesito permiso de micrófono para entenderte.');
    const r = await SpeechRecognition.start({
      language: 'es-ES', maxResults: 1, prompt: '¿Qué buscas?',
      partialResults: false, popup: true,          // ventana de Google en Android
    });
    return r.matches?.[0] ?? '';
  }

  // ----- Navegador: Web Speech API (Chrome, Edge y Safari; Firefox no la tiene)
  private escucharWeb(): Promise<string> {
    const w = window as unknown as Record<string, any>;
    const Reconocedor = w['SpeechRecognition'] ?? w['webkitSpeechRecognition'];
    if (!Reconocedor) {
      return Promise.reject(new Error('Este navegador no permite buscar por voz. Prueba con Chrome o con la app.'));
    }
    return new Promise((resolver, rechazar) => {
      const rec = new Reconocedor();
      rec.lang = 'es-ES';
      rec.interimResults = false;
      rec.maxAlternatives = 1;
      rec.onresult = (e: any) => resolver(e.results[0][0].transcript);
      rec.onerror = (e: any) => rechazar(new Error(e.error === 'not-allowed'
        ? 'Permite el micrófono para buscar por voz.'
        : 'No te he entendido. Inténtalo otra vez.'));
      rec.onend = () => resolver('');             // terminó sin oír nada
      rec.start();
      setTimeout(() => { rec.abort?.(); resolver(''); }, 8000);   // seguridad: nunca se queda escuchando para siempre
    });
  }

  private async aviso(mensaje: string): Promise<void> {
    const t = await this.toast.create({ message: mensaje, duration: 2500, position: 'top' });
    await t.present();
  }
}
