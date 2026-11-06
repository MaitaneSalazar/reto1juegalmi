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
import com.example.retoindividual_1.modelos.FotoTienda;

import java.util.List;

//ADAPTADOR DE LA GALERIA, UNA FOTO ANCHA Y LUEGO DOS PEQUEÑAS, Y ASI
public class FotoTiendaAdapter extends RecyclerView.Adapter<FotoTiendaAdapter.FotoTiendaViewHolder> {

    private final List<FotoTienda> fotos;

    public FotoTiendaAdapter(List<FotoTienda> fotos) {
        this.fotos = fotos;
    }

    //LA USA EL GridLayoutManager PARA SABER CUANTAS COLUMNAS OCUPA CADA FOTO
    public static boolean esAncha(int position) {
        return position % 3 == 0;
    }

    @NonNull
    @Override
    public FotoTiendaViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View vista = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_foto_tienda, parent, false);
        return new FotoTiendaViewHolder(vista);
    }

    @Override
    public void onBindViewHolder(@NonNull FotoTiendaViewHolder holder, int position) {
        FotoTienda foto = fotos.get(position);

        holder.tvTitulo.setText(foto.getTitulo());
        holder.itemView.getLayoutParams().height = holder.itemView.getResources()
                .getDimensionPixelSize(esAncha(position) ? R.dimen.galeria_alto_ancha : R.dimen.galeria_alto_cuadrada);

        //MIENTRAS SE DESCARGA, O SI NO HAY FOTO, SALE LA IMAGEN PROVISIONAL
        Glide.with(holder.itemView)
                .load(foto.getUrl())
                .placeholder(R.drawable.placeholder_producto)
                .error(R.drawable.placeholder_producto)
                .into(holder.ivFoto);
    }

    @Override
    public int getItemCount() {
        return fotos.size();
    }

    static class FotoTiendaViewHolder extends RecyclerView.ViewHolder {
        ImageView ivFoto;
        TextView tvTitulo;

        FotoTiendaViewHolder(@NonNull View itemView) {
            super(itemView);
            ivFoto = itemView.findViewById(R.id.ivFotoTienda);
            tvTitulo = itemView.findViewById(R.id.tvFotoTienda);
        }
    }
}
