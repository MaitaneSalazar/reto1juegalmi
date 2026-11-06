package com.example.retoindividual_1.utilidades;

import android.content.ContentResolver;
import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.graphics.Matrix;
import android.media.ExifInterface;
import android.net.Uri;

import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.InputStream;

/*
 * =====================================================================================
 *  Prepara una foto (de la cámara o de la galería) para subirla a la API:
 *   1. La reduce para que el lado más largo tenga como mucho 1600 px
 *      (una foto de móvil puede pesar 5 MB; así queda en unos 300 KB)
 *   2. La gira si hace falta (muchas cámaras guardan la orientación aparte, en el EXIF)
 *   3. La guarda como JPEG en la caché de la app y devuelve ese archivo
 *
 *  Tarda un poco, así que se llama SIEMPRE desde un hilo secundario, nunca desde el principal.
 * =====================================================================================
 */
public final class ProcesadorFotos {

    private static final int LADO_MAXIMO = 1600;
    private static final int CALIDAD_JPEG = 85;

    private ProcesadorFotos() {
    }

    public static File preparar(Context context, Uri origen) throws IOException {
        ContentResolver resolver = context.getContentResolver();

        BitmapFactory.Options medidas = new BitmapFactory.Options();
        medidas.inJustDecodeBounds = true;
        try (InputStream entrada = resolver.openInputStream(origen)) {
            BitmapFactory.decodeStream(entrada, null, medidas);
        }
        if (medidas.outWidth <= 0 || medidas.outHeight <= 0) {
            throw new IOException("El archivo no es una imagen");
        }

        int escala = 1;
        while (Math.max(medidas.outWidth, medidas.outHeight) / (escala * 2) >= LADO_MAXIMO) {
            escala *= 2;
        }
        BitmapFactory.Options carga = new BitmapFactory.Options();
        carga.inSampleSize = escala;
        Bitmap foto;
        try (InputStream entrada = resolver.openInputStream(origen)) {
            foto = BitmapFactory.decodeStream(entrada, null, carga);
        }
        if (foto == null) {
            throw new IOException("No se ha podido leer la imagen");
        }

        int ladoMayor = Math.max(foto.getWidth(), foto.getHeight());
        if (ladoMayor > LADO_MAXIMO) {
            float factor = (float) LADO_MAXIMO / ladoMayor;
            Bitmap reducida = Bitmap.createScaledBitmap(foto,
                    Math.round(foto.getWidth() * factor), Math.round(foto.getHeight() * factor), true);
            foto.recycle();
            foto = reducida;
        }

        int grados = leerGiro(resolver, origen);
        if (grados != 0) {
            Matrix giro = new Matrix();
            giro.postRotate(grados);
            Bitmap girada = Bitmap.createBitmap(foto, 0, 0, foto.getWidth(), foto.getHeight(), giro, true);
            foto.recycle();
            foto = girada;
        }

        File carpeta = new File(context.getCacheDir(), "fotos_reparacion");
        if (!carpeta.exists() && !carpeta.mkdirs()) {
            throw new IOException("No se ha podido crear la carpeta de fotos");
        }
        File destino = new File(carpeta, "foto_" + System.currentTimeMillis() + ".jpg");
        try (FileOutputStream salida = new FileOutputStream(destino)) {
            foto.compress(Bitmap.CompressFormat.JPEG, CALIDAD_JPEG, salida);
        } finally {
            foto.recycle();
        }
        return destino;
    }

    private static int leerGiro(ContentResolver resolver, Uri origen) {
        try (InputStream entrada = resolver.openInputStream(origen)) {
            if (entrada == null) {
                return 0;
            }
            ExifInterface exif = new ExifInterface(entrada);
            int orientacion = exif.getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL);
            switch (orientacion) {
                case ExifInterface.ORIENTATION_ROTATE_90:
                    return 90;
                case ExifInterface.ORIENTATION_ROTATE_180:
                    return 180;
                case ExifInterface.ORIENTATION_ROTATE_270:
                    return 270;
                default:
                    return 0;
            }
        } catch (IOException e) {
            return 0;
        }
    }
}