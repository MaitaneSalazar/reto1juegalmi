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
import com.example.retoindividual_1.utilidades.FormatosReparacion;
import com.google.android.material.progressindicator.CircularProgressIndicator;

import java.util.List;

public class ReparacionAdapter extends RecyclerView.Adapter<RecyclerView.ViewHolder> {

    public interface AlPulsar {
        void abrir(Reparacion reparacion);
    }

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

    private static String titulo(Context contexto, Reparacion reparacion) {
        return FormatosReparacion.titulo(contexto, reparacion.getTipoDispositivo(),
                reparacion.getMarca(), reparacion.getModelo());
    }

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
            tvEntrada.setText(FormatosReparacion.fechaCorta(reparacion.getFecha()));

            // Si el listado no trae el presupuesto, la fila no se enseña
            llPresupuesto.setVisibility(reparacion.traePresupuesto() ? View.VISIBLE : View.GONE);
            tvPresupuesto.setText(reparacion.getPresupuesto() == null
                    ? contexto.getString(R.string.mis_rep_presupuesto_pendiente)
                    : FormatosReparacion.precio(reparacion.getPresupuesto()));

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
                        : contexto.getString(R.string.mis_rep_entregada_el,
                        FormatosReparacion.fechaCorta(reparacion.getFechaEntrega())));
            }

            boolean conPrecio = !reparacion.estaCancelada() && reparacion.getPresupuesto() != null;
            tvPrecio.setVisibility(conPrecio ? View.VISIBLE : View.GONE);
            if (conPrecio) {
                tvPrecio.setText(FormatosReparacion.precio(reparacion.getPresupuesto()));
            }

            itemView.setOnClickListener(v -> alPulsar.abrir(reparacion));
        }
    }
}