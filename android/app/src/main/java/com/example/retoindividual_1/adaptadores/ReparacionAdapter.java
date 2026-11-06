package com.example.retoindividual_1.adaptadores;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.example.retoindividual_1.R;
import com.example.retoindividual_1.modelos.Reparacion;
import com.google.android.material.progressindicator.CircularProgressIndicator;

import java.util.List;
import java.util.Locale;

// Una sola lista con 3 tipos de fila: encabezado, reparación en curso y reparación terminada
public class ReparacionAdapter extends RecyclerView.Adapter<RecyclerView.ViewHolder> {

    public interface AlPulsar {
        void abrir(Reparacion reparacion);
    }

    // Fila de título de sección ("En curso", "Entregadas"...)
    public static class Encabezado {
        final String texto;
        final boolean grande;

        public Encabezado(String texto, boolean grande) {
            this.texto = texto;
            this.grande = grande;
        }
    }

    private static final int TIPO_ENCABEZADO = 0;
    private static final int TIPO_EN_CURSO = 1;
    private static final int TIPO_TERMINADA = 2;

    private static final String[] MESES = {"ene", "feb", "mar", "abr", "may", "jun",
            "jul", "ago", "sep", "oct", "nov", "dic"};
    private static final Locale ESPANOL = Locale.forLanguageTag("es-ES");

    private final List<Object> filas;
    private final AlPulsar alPulsar;

    public ReparacionAdapter(List<Object> filas, AlPulsar alPulsar) {
        this.filas = filas;
        this.alPulsar = alPulsar;
    }

    @Override
    public int getItemViewType(int posicion) {
        Object fila = filas.get(posicion);
        if (fila instanceof Encabezado) {
            return TIPO_ENCABEZADO;
        }
        return ((Reparacion) fila).estaEnCurso() ? TIPO_EN_CURSO : TIPO_TERMINADA;
    }

    @Override
    public int getItemCount() {
        return filas.size();
    }

    @NonNull
    @Override
    public RecyclerView.ViewHolder onCreateViewHolder(@NonNull ViewGroup padre, int tipo) {
        LayoutInflater inflater = LayoutInflater.from(padre.getContext());
        if (tipo == TIPO_ENCABEZADO) {
            return new EncabezadoHolder(inflater.inflate(R.layout.item_encabezado_reparaciones, padre, false));
        }
        if (tipo == TIPO_EN_CURSO) {
            return new EnCursoHolder(inflater.inflate(R.layout.item_reparacion_en_curso, padre, false));
        }
        return new TerminadaHolder(inflater.inflate(R.layout.item_reparacion_terminada, padre, false));
    }

    @Override
    public void onBindViewHolder(@NonNull RecyclerView.ViewHolder holder, int posicion) {
        Object fila = filas.get(posicion);
        if (holder instanceof EncabezadoHolder) {
            ((EncabezadoHolder) holder).pintar((Encabezado) fila);
        } else if (holder instanceof EnCursoHolder) {
            ((EnCursoHolder) holder).pintar((Reparacion) fila, alPulsar);
        } else {
            ((TerminadaHolder) holder).pintar((Reparacion) fila, alPulsar);
        }
    }

    // ============================ FILAS ============================

    static class EncabezadoHolder extends RecyclerView.ViewHolder {
        private final TextView tvTitulo;

        EncabezadoHolder(View vista) {
            super(vista);
            tvTitulo = vista.findViewById(R.id.tvEncabezado);
        }

        void pintar(Encabezado encabezado) {
            tvTitulo.setText(encabezado.texto);
            tvTitulo.setTextSize(encabezado.grande ? 40 : 24);
        }
    }

    static class EnCursoHolder extends RecyclerView.ViewHolder {
        private final CircularProgressIndicator cpiProgreso;
        private final TextView tvProgreso;
        private final TextView tvTitulo;
        private final TextView tvEstado;
        private final TextView tvEntrada;
        private final View llPresupuesto;
        private final TextView tvPresupuesto;

        EnCursoHolder(View vista) {
            super(vista);
            cpiProgreso = vista.findViewById(R.id.cpiReparacionProgreso);
            tvProgreso = vista.findViewById(R.id.tvReparacionProgreso);
            tvTitulo = vista.findViewById(R.id.tvReparacionTitulo);
            tvEstado = vista.findViewById(R.id.tvReparacionEstado);
            tvEntrada = vista.findViewById(R.id.tvReparacionEntrada);
            llPresupuesto = vista.findViewById(R.id.llReparacionPresupuesto);
            tvPresupuesto = vista.findViewById(R.id.tvReparacionPresupuesto);
        }

        void pintar(Reparacion reparacion, AlPulsar alPulsar) {
            Context contexto = itemView.getContext();
            cpiProgreso.setMax(reparacion.getTotalPasos());
            cpiProgreso.setProgress(reparacion.getPaso());
            tvProgreso.setText(contexto.getString(R.string.mis_rep_progreso,
                    reparacion.getPaso(), reparacion.getTotalPasos()));
            tvTitulo.setText(titulo(contexto, reparacion));
            tvEstado.setText(reparacion.getEstadoTexto());
            tvEntrada.setText(fechaCorta(reparacion.getFecha()));

            // Si el listado no trae el presupuesto, la fila no se enseña
            llPresupuesto.setVisibility(reparacion.traePresupuesto() ? View.VISIBLE : View.GONE);
            tvPresupuesto.setText(reparacion.getPresupuesto() == null
                    ? contexto.getString(R.string.mis_rep_presupuesto_pendiente)
                    : precio(reparacion.getPresupuesto()));

            itemView.setOnClickListener(v -> alPulsar.abrir(reparacion));
        }
    }

    static class TerminadaHolder extends RecyclerView.ViewHolder {
        private final ImageView ivIcono;
        private final TextView tvTitulo;
        private final TextView tvDetalle;
        private final TextView tvPrecio;

        TerminadaHolder(View vista) {
            super(vista);
            ivIcono = vista.findViewById(R.id.ivReparacionIcono);
            tvTitulo = vista.findViewById(R.id.tvReparacionTitulo);
            tvDetalle = vista.findViewById(R.id.tvReparacionDetalle);
            tvPrecio = vista.findViewById(R.id.tvReparacionPrecio);
        }

        void pintar(Reparacion reparacion, AlPulsar alPulsar) {
            Context contexto = itemView.getContext();
            tvTitulo.setText(titulo(contexto, reparacion));

            if (reparacion.estaCancelada()) {
                ivIcono.setImageResource(R.drawable.ic_cancelada);
                tvDetalle.setText(R.string.mis_rep_cancelada);
            } else {
                ivIcono.setImageResource(R.drawable.ic_check_circulo);
                tvDetalle.setText(reparacion.getFechaEntrega() == null
                        ? contexto.getString(R.string.mis_rep_entregada)
                        : contexto.getString(R.string.mis_rep_entregada_el, fechaCorta(reparacion.getFechaEntrega())));
            }

            boolean conPrecio = !reparacion.estaCancelada() && reparacion.getPresupuesto() != null;
            tvPrecio.setVisibility(conPrecio ? View.VISIBLE : View.GONE);
            if (conPrecio) {
                tvPrecio.setText(precio(reparacion.getPresupuesto()));
            }

            itemView.setOnClickListener(v -> alPulsar.abrir(reparacion));
        }
    }

    // ============================ FORMATOS ============================

    // "Mando · Sony DualSense"
    static String titulo(Context contexto, Reparacion reparacion) {
        String dispositivo = contexto.getString(nombreDispositivo(reparacion.getTipoDispositivo()));
        return contexto.getString(R.string.mis_rep_titulo, dispositivo,
                (reparacion.getMarca() + " " + reparacion.getModelo()).trim());
    }

    static int nombreDispositivo(String tipo) {
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

    // "2026-11-02T10:00:00+01:00" o "2026-11-02" -> "2 nov".
    // Los meses van escritos a mano porque Android, según la versión, añade un punto ("nov.")
    static String fechaCorta(String iso) {
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

    // 35.0 -> "35,00 €"
    static String precio(double valor) {
        return String.format(ESPANOL, "%.2f €", valor);
    }
}