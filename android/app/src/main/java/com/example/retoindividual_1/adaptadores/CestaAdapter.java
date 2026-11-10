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
import com.example.retoindividual_1.modelos.Cesta;
import com.example.retoindividual_1.utilidades.FormatosReparacion;

import java.util.List;

//ADAPTADOR DE LA CESTA, CADA LINEA CON SUS BOTONES DE MAS Y MENOS
public class CestaAdapter extends RecyclerView.Adapter<CestaAdapter.CestaViewHolder> {

    //EL FRAGMENT DECIDE QUE HACER AL SUMAR O RESTAR (ACTUALIZAR EL TOTAL, AVISAR DEL STOCK...)
    public interface Acciones {
        void sumar(Cesta.Linea linea);

        void restar(Cesta.Linea linea);
    }

    private final List<Cesta.Linea> lineas;
    private final Acciones acciones;

    public CestaAdapter(List<Cesta.Linea> lineas, Acciones acciones) {
        this.lineas = lineas;
        this.acciones = acciones;
    }

    @NonNull
    @Override
    public CestaViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View vista = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_cesta, parent, false);
        return new CestaViewHolder(vista);
    }

    @Override
    public void onBindViewHolder(@NonNull CestaViewHolder holder, int position) {
        Cesta.Linea linea = lineas.get(position);

        holder.tvNombre.setText(linea.getProducto().getNombreConPlataforma());
        holder.tvPrecio.setText(FormatosReparacion.precio(linea.getPrecio()));
        if (linea.isAlquiler()) {
            holder.tvDetalle.setText(holder.itemView.getContext().getResources()
                    .getQuantityString(R.plurals.cesta_alquiler_dias, linea.getDias(), linea.getDias()));
        }
        holder.tvDetalle.setVisibility(linea.isAlquiler() ? View.VISIBLE : View.GONE);
        holder.tvCantidad.setText(String.valueOf(linea.getCantidad()));
        Glide.with(holder.itemView)
                .load(linea.getProducto().getMiniaturaUrl())
                .placeholder(R.drawable.placeholder_producto)
                .error(R.drawable.placeholder_producto)
                .into(holder.ivFoto);

        holder.ivSumar.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                acciones.sumar(linea);
            }
        });
        holder.ivRestar.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                acciones.restar(linea);
            }
        });
    }

    @Override
    public int getItemCount() {
        return lineas.size();
    }

    static class CestaViewHolder extends RecyclerView.ViewHolder {
        ImageView ivFoto;
        TextView tvNombre;
        TextView tvDetalle;
        TextView tvPrecio;
        TextView tvCantidad;
        ImageView ivSumar;
        ImageView ivRestar;

        CestaViewHolder(@NonNull View itemView) {
            super(itemView);
            ivFoto = itemView.findViewById(R.id.ivCestaFoto);
            tvNombre = itemView.findViewById(R.id.tvCestaNombre);
            tvDetalle = itemView.findViewById(R.id.tvCestaDetalle);
            tvPrecio = itemView.findViewById(R.id.tvCestaPrecio);
            tvCantidad = itemView.findViewById(R.id.tvCestaCantidad);
            ivSumar = itemView.findViewById(R.id.ivCestaSumar);
            ivRestar = itemView.findViewById(R.id.ivCestaRestar);
        }
    }
}
