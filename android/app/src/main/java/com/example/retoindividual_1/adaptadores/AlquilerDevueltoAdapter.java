package com.example.retoindividual_1.adaptadores;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.bumptech.glide.Glide;
import com.example.retoindividual_1.R;
import com.example.retoindividual_1.modelos.Alquiler;
import com.example.retoindividual_1.utilidades.FormatosReparacion;

import java.util.List;

//ADAPTADOR DE LOS JUEGOS YA DEVUELTOS
public class AlquilerDevueltoAdapter extends RecyclerView.Adapter<AlquilerDevueltoAdapter.AlquilerDevueltoViewHolder> {

    private final List<Alquiler.Linea> lineas;

    public AlquilerDevueltoAdapter(List<Alquiler.Linea> lineas) {
        this.lineas = lineas;
    }

    @NonNull
    @Override
    public AlquilerDevueltoViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View vista = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_alquiler_devuelto, parent, false);
        return new AlquilerDevueltoViewHolder(vista);
    }

    @Override
    public void onBindViewHolder(@NonNull AlquilerDevueltoViewHolder holder, int position) {
        Alquiler.Linea linea = lineas.get(position);

        holder.tvNombre.setText(linea.getVideojuego().getNombre());
        holder.tvFecha.setText(holder.itemView.getContext().getString(R.string.alq_devuelto_el,
                FormatosReparacion.fechaCorta(linea.getFechaDevolucion())));
        holder.tvImporte.setText(FormatosReparacion.precio(linea.getImporte()));
        Glide.with(holder.itemView)
                .load(linea.getVideojuego().getMiniaturaUrl())
                .placeholder(R.drawable.placeholder_producto)
                .error(R.drawable.placeholder_producto)
                .into(holder.ivFoto);
    }

    @Override
    public int getItemCount() {
        return lineas.size();
    }

    static class AlquilerDevueltoViewHolder extends RecyclerView.ViewHolder {
        ImageView ivFoto;
        TextView tvNombre;
        TextView tvFecha;
        TextView tvImporte;

        AlquilerDevueltoViewHolder(@NonNull View itemView) {
            super(itemView);
            ivFoto = itemView.findViewById(R.id.ivDevueltoFoto);
            tvNombre = itemView.findViewById(R.id.tvDevueltoNombre);
            tvFecha = itemView.findViewById(R.id.tvDevueltoFecha);
            tvImporte = itemView.findViewById(R.id.tvDevueltoImporte);
        }
    }
}
