import { Injectable, inject } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable, map, of } from 'rxjs';
import { Camera, CameraResultType, CameraSource } from '@capacitor/camera';
import { environment } from '../../environments/environment';

// Carpetas que admite la API de Aketza
export type TipoImagen = 'soporte' | 'productos' | 'tienda';

@Injectable({ providedIn: 'root' })
export class FotoService {
  private http = inject(HttpClient);

  // Abre la cámara (o la galería) y devuelve la foto como dataURL para la vista previa
  async hacerFoto(): Promise<string | null> {
    try {
      const foto = await Camera.getPhoto({
        quality: 70,                         // menos peso = subida más rápida
        width: 1280,                         // tamaño máximo
        resultType: CameraResultType.DataUrl,
        source: CameraSource.Prompt,         // el usuario elige cámara o galería
        promptLabelHeader: 'Foto del dispositivo',
        promptLabelPhoto: 'Elegir de la galería',
        promptLabelPicture: 'Hacer foto',
        promptLabelCancel: 'Cancelar',
      });
      return foto.dataUrl ?? null;
    } catch (e) {
      // Si el usuario cancela no es un error
      if (String(e).toLowerCase().includes('cancel')) return null;
      throw e;
    }
  }

  // Sube la foto y devuelve su URL pública
  subir(dataUrl: string, tipo: TipoImagen = 'soporte'): Observable<string> {
    if (environment.usarDatosEjemplo) return of(dataUrl);   // modo ejemplo: la foto se queda en memoria

    const form = new FormData();
    form.append('imagen', this.aBlob(dataUrl), `foto.${this.extension(dataUrl)}`);  // campo que espera la API
    form.append('tipo', tipo);
    return this.http.post<{ ruta: string; url: string }>(`${environment.apiUrl}/imagenes`, form)
      .pipe(map(r => r.url));
  }

  // "data:image/jpeg;base64,..." → Blob (archivo binario para el multipart)
  private aBlob(dataUrl: string): Blob {
    const [cabecera, datos] = dataUrl.split(',');
    const tipo = cabecera.match(/:(.*?);/)?.[1] ?? 'image/jpeg';
    const binario = atob(datos);
    const bytes = new Uint8Array(binario.length);
    for (let i = 0; i < binario.length; i++) bytes[i] = binario.charCodeAt(i);
    return new Blob([bytes], { type: tipo });
  }

  private extension(dataUrl: string): string {
    if (dataUrl.startsWith('data:image/png')) return 'png';
    if (dataUrl.startsWith('data:image/webp')) return 'webp';
    return 'jpg';
  }
}
