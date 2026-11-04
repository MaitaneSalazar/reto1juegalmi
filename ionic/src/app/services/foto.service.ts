import { Injectable } from '@angular/core';
import { Camera, CameraResultType, CameraSource } from '@capacitor/camera';

@Injectable({ providedIn: 'root' })
export class FotoService {
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

  // "data:image/jpeg;base64,..." → Blob (archivo binario para el multipart)
  aBlob(dataUrl: string): Blob {
    const [cabecera, datos] = dataUrl.split(',');
    const tipo = cabecera.match(/:(.*?);/)?.[1] ?? 'image/jpeg';
    const binario = atob(datos);
    const bytes = new Uint8Array(binario.length);
    for (let i = 0; i < binario.length; i++) bytes[i] = binario.charCodeAt(i);
    return new Blob([bytes], { type: tipo });
  }

  extension(dataUrl: string): string {
    if (dataUrl.startsWith('data:image/png')) return 'png';
    if (dataUrl.startsWith('data:image/webp')) return 'webp';
    return 'jpg';
  }
}
