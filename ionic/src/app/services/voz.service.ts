import { Injectable, inject, signal } from '@angular/core';
import { Router } from '@angular/router';
import { Capacitor } from '@capacitor/core';
import { SpeechRecognition } from '@capacitor-community/speech-recognition';
import { ToastController } from '@ionic/angular';
import { SesionService } from './sesion.service';

// Orden de voz: palabras que la activan + qué hace (resto = lo dicho después de la palabra)
interface Comando { claves: string[]; nombre: string; accion: (resto: string) => void; }

@Injectable({ providedIn: 'root' })
export class VozService {
  private router = inject(Router);
  private sesion = inject(SesionService);
  private toast = inject(ToastController);

  escuchando = signal(false);              // el micrófono está abierto (anima el botón)

  // Orden importante: las frases más concretas van antes ("mis alquileres" antes que "alquilar")
  private comandos: Comando[] = [
    { claves: ['cerrar sesion', 'salir'], nombre: 'Cerrar sesión', accion: () => {
        this.sesion.cerrar();
        this.router.navigateByUrl('/login', { replaceUrl: true });
      } },
    { claves: ['buscar', 'busca'], nombre: 'Buscar', accion: resto =>
        this.router.navigate(['/tienda'], { queryParams: { modo: 'comprar', buscar: resto } }) },
    { claves: ['mis pedidos', 'pedidos'], nombre: 'Mis pedidos', accion: () => this.ir('/cuenta/pedidos') },
    { claves: ['mis alquileres'], nombre: 'Mis alquileres', accion: () => this.ir('/cuenta/alquileres') },
    { claves: ['mis reparaciones'], nombre: 'Mis reparaciones', accion: () =>
        this.router.navigate(['/taller'], { queryParams: { vista: 'mis' } }) },
    { claves: ['alquilar', 'alquiler'], nombre: 'Alquilar', accion: () =>
        this.router.navigate(['/tienda'], { queryParams: { modo: 'alquilar' } }) },
    { claves: ['reparar', 'reparacion', 'taller', 'arreglar'], nombre: 'Taller', accion: () => this.ir('/taller') },
    { claves: ['cesta', 'carrito'], nombre: 'Cesta', accion: () => this.ir('/cesta') },
    { claves: ['nosotros', 'donde', 'ubicacion', 'mapa', 'horario'], nombre: 'Sobre nosotros', accion: () => this.ir('/nosotros') },
    { claves: ['tienda', 'comprar', 'catalogo'], nombre: 'Tienda', accion: () =>
        this.router.navigate(['/tienda'], { queryParams: { modo: 'comprar' } }) },
    { claves: ['datos personales'], nombre: 'Datos personales', accion: () => this.ir('/cuenta/datos-personales') },
    { claves: ['direccion'], nombre: 'Direcciones', accion: () => this.ir('/cuenta/direcciones') },
    { claves: ['ajustes'], nombre: 'Ajustes', accion: () => this.ir('/cuenta/ajustes') },
    { claves: ['ayuda'], nombre: 'Ayuda', accion: () => this.ir('/cuenta/ayuda') },
    { claves: ['cuenta', 'perfil'], nombre: 'Cuenta', accion: () => this.ir('/cuenta') },
    { claves: ['inicio', 'casa', 'principal'], nombre: 'Inicio', accion: () => this.ir('/inicio') },
  ];

  // Botón del micrófono: escucha una frase y la ejecuta
  async escuchar(): Promise<void> {
    if (this.escuchando()) return;
    this.escuchando.set(true);
    try {
      const frase = Capacitor.isNativePlatform() ? await this.escucharNativo() : await this.escucharWeb();
      if (frase) this.ejecutar(frase);
    } catch (e) {
      this.aviso(e instanceof Error ? e.message : 'No te he entendido. Inténtalo otra vez.');
    } finally {
      this.escuchando.set(false);
    }
  }

  // Busca la primera orden que encaje con la frase y la ejecuta
  ejecutar(frase: string): boolean {
    const texto = this.normalizar(frase);
    for (const c of this.comandos) {
      const clave = c.claves.find(k => texto.includes(k));
      if (!clave) continue;
      const resto = texto.slice(texto.indexOf(clave) + clave.length).trim();   // "buscar zelda" → "zelda"
      c.accion(resto);
      this.aviso(`«${frase}» → ${c.nombre}${c.nombre === 'Buscar' && resto ? ' «' + resto + '»' : ''}`);
      return true;
    }
    this.aviso(`No entiendo «${frase}». Prueba: «tienda», «cesta», «buscar Zelda», «pedir reparación».`);
    return false;
  }

  // ----- Móvil (Android / iOS): plugin de Capacitor
  private async escucharNativo(): Promise<string> {
    const { available } = await SpeechRecognition.available();
    if (!available) throw new Error('El reconocimiento de voz no está disponible en este móvil.');
    const permiso = await SpeechRecognition.requestPermissions();
    if (permiso.speechRecognition !== 'granted') throw new Error('Necesito permiso de micrófono para entenderte.');
    const r = await SpeechRecognition.start({
      language: 'es-ES', maxResults: 1, prompt: 'Di una orden: «tienda», «cesta»…',
      partialResults: false, popup: true,          // ventana de Google en Android
    });
    return r.matches?.[0] ?? '';
  }

  // ----- Navegador: Web Speech API (Chrome, Edge y Safari; Firefox no la tiene)
  private escucharWeb(): Promise<string> {
    const w = window as unknown as Record<string, any>;
    const Reconocedor = w['SpeechRecognition'] ?? w['webkitSpeechRecognition'];
    if (!Reconocedor) {
      return Promise.reject(new Error('Este navegador no permite el control por voz. Prueba con Chrome o con la app.'));
    }
    return new Promise((resolver, rechazar) => {
      const rec = new Reconocedor();
      rec.lang = 'es-ES';
      rec.interimResults = false;
      rec.maxAlternatives = 1;
      rec.onresult = (e: any) => resolver(e.results[0][0].transcript);
      rec.onerror = (e: any) => rechazar(new Error(e.error === 'not-allowed'
        ? 'Permite el micrófono para usar la voz.'
        : 'No te he entendido. Inténtalo otra vez.'));
      rec.onend = () => resolver('');             // terminó sin oír nada
      rec.start();
      setTimeout(() => { rec.abort?.(); resolver(''); }, 8000);   // seguridad: nunca se queda escuchando para siempre
    });
  }

  // "¿Dónde ESTÁ la tienda?" → "donde esta la tienda"
  private normalizar(t: string): string {
    return t.toLowerCase().normalize('NFD').replace(/[̀-ͯ]/g, '').replace(/[¿?¡!.,]/g, '').trim();
  }

  private ir(url: string): void {
    this.router.navigateByUrl(url);
  }

  private async aviso(mensaje: string): Promise<void> {
    const t = await this.toast.create({ message: mensaje, duration: 2500, position: 'top', color: 'dark' });
    await t.present();
  }
}
