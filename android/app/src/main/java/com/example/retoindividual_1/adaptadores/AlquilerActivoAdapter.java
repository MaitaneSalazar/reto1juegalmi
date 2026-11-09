package com.example.retoindividual_1.adaptadores;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.ProgressBar;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;
import androidx.recyclerview.widget.RecyclerView;

import com.bumptech.glide.Glide;
import com.example.retoindividual_1.R;
import com.example.retoindividual_1.modelos.Alquiler;
import com.example.retoindividual_1.modelos.Producto;
import com.example.retoindividual_1.utilidades.FormatosReparacion;

import java.util.List;

//ADAPTADOR DE LOS ALQUILERES SIN DEVOLVER, CADA UNO CON SUS DIAS Y EL BOTON DE DEVOLVER
public class AlquilerActivoAdapter extends RecyclerView.Adapter<AlquilerActivoAdapter.AlquilerActivoViewHolder> {

    //LO QUE PASA AL PULSAR DEVOLVER LO DECIDE LA ACTIVITY
    public interface AlDevolver {
        void devolver(Alquiler alquiler);
    }

    private final List<Alquiler> alquileres;
    private final AlDevolver alDevolver;

    public AlquilerActivoAdapter(List<Alquiler> alquileres, AlDevolver alDevolver) {
        this.alquileres = alquileres;
        this.alDevolver = alDevolver;
    }

    @NonNull
    @Override
    public AlquilerActivoViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View vista = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_alquiler_activo, parent, false);
        return new AlquilerActivoViewHolder(vista);
    }

    @Override
    public void onBindViewHolder(@NonNull AlquilerActivoViewHolder holder, int position) {
        Alquiler alquiler = alquileres.get(position);
        Alquiler.Linea linea = alquiler.getLineas().get(0);
        Producto juego = linea.getVideojuego();
        Context context = holder.itemView.getContext();

        holder.tvNombre.setText(juego.getNombre());
        Glide.with(holder.itemView)
                .load(juego.getMiniaturaUrl())
                .placeholder(R.drawable.placeholder_producto)
                .error(R.drawable.placeholder_producto)
                .into(holder.ivFoto);

        //SI SE HA PASADO LA FECHA ENSEÑAMOS LOS DIAS DE RETRASO EN ROJO
        int dias = Math.abs(alquiler.getDiasRestantes());
        int color = ContextCompat.getColor(context, alquiler.estaRetrasado() ? R.color.color_alerta : R.color.color_texto);
        holder.tvDias.setText(String.valueOf(dias));
        holder.tvDias.setTextColor(color);
        holder.tvDiasTexto.setText(context.getResources().getQuantityString(
                alquiler.estaRetrasado() ? R.plurals.alq_dias_retraso : R.plurals.alq_dias_quedan, dias));

        //LA BARRA VA DE 0 A LOS DIAS QUE DURA EL ALQUILER
        holder.pbAlquiler.setMax(Math.max(linea.getDias(), 1));
        holder.pbAlquiler.setProgress(linea.getDias() - alquiler.getDiasRestantes());
        holder.pbAlquiler.setProgressTintList(ContextCompat.getColorStateList(context,
                alquiler.estaRetrasado() ? R.color.color_alerta : R.color.color_marca));

        holder.tvInicio.setText(FormatosReparacion.fechaCorta(alquiler.getFechaInicio()));
        holder.tvFin.setText(context.getString(R.string.alq_devolver_antes, FormatosReparacion.fechaCorta(alquiler.getFechaFinPrevista())));

        holder.btnDevolver.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                alDevolver.devolver(alquiler);
            }
        });
    }

    @Override
    public int getItemCount() {
        return alquileres.size();
    }

    static class AlquilerActivoViewHolder extends RecyclerView.ViewHolder {
        ImageView ivFoto;
        TextView tvNombre;
        TextView tvDias;
        TextView tvDiasTexto;
        ProgressBar pbAlquiler;
        TextView tvInicio;
        TextView tvFin;
        Button btnDevolver;

        AlquilerActivoViewHolder(@NonNull View itemView) {
            super(itemView);
            ivFoto = itemView.findViewById(R.id.ivAlquilerFoto);
            tvNombre = itemView.findViewById(R.id.tvAlquilerNombre);
            tvDias = itemView.findViewById(R.id.tvAlquilerDias);
            tvDiasTexto = itemView.findViewById(R.id.tvAlquilerDiasTexto);
            pbAlquiler = itemView.findViewById(R.id.pbAlquiler);
            tvInicio = itemView.findViewById(R.id.tvAlquilerInicio);
            tvFin = itemView.findViewById(R.id.tvAlquilerFin);
            btnDevolver = itemView.findViewById(R.id.btnAlquilerDevolver);
        }
    }
}
