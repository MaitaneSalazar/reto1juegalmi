package com.example.retoindividual_1.utilidades;

import android.content.Context;

import com.example.retoindividual_1.R;

import java.util.Locale;

public final class FormatosReparacion {

    private static final String[] MESES = {"ene", "feb", "mar", "abr", "may", "jun",
            "jul", "ago", "sep", "oct", "nov", "dic"};
    private static final Locale ESPANOL = Locale.forLanguageTag("es-ES");

    private FormatosReparacion() {
    }

    public static String titulo(Context contexto, String tipoDispositivo, String marca, String modelo) {
        return contexto.getString(R.string.mis_rep_titulo,
                contexto.getString(nombreDispositivo(tipoDispositivo)), (marca + " " + modelo).trim());
    }

    public static int nombreDispositivo(String tipo) {
        switch (tipo) {
            case "consola":
                return R.string.disp_consola;
            case "movil":
                return R.string.disp_movil;
            case "tablet":
                return R.string.disp_tablet;
            case "ordenador":
                return R.string.disp_ordenador;
            case "mando":
                return R.string.disp_mando;
            case "auriculares":
                return R.string.disp_auriculares;
            case "reloj":
                return R.string.disp_reloj;
            default:
                return R.string.disp_otro;
        }
    }

    // "2026-11-02..." -> "2 nov". Los meses van a mano porque Android, según la versión, escribe "nov."
    public static String fechaCorta(String iso) {
        if (iso == null || iso.length() < 10) {
            return "";
        }
        try {
            int mes = Integer.parseInt(iso.substring(5, 7));
            int dia = Integer.parseInt(iso.substring(8, 10));
            return dia + " " + MESES[mes - 1];
        } catch (NumberFormatException | ArrayIndexOutOfBoundsException e) {
            return "";
        }
    }

    public static String precio(double valor) {
        return String.format(ESPANOL, "%.2f €", valor);
    }
}