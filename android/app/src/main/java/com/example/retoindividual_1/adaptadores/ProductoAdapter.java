package com.example.retoindividual_1.adaptadores;

import android.content.Context;
import android.content.Intent;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;
import androidx.recyclerview.widget.RecyclerView;

import com.bumptech.glide.Glide;
import com.example.retoindividual_1.FichaProductoActivity;
import com.example.retoindividual_1.R;
import com.example.retoindividual_1.modelos.Producto;

import java.text.NumberFormat;
import java.util.List;
import java.util.Locale;

//ADAPTADOR DE LA TIENDA, CADA PRODUCTO ES UNA TARJETA CON SU PORTADA, NOMBRE Y PRECIO
public class ProductoAdapter extends RecyclerView.Adapter<ProductoAdapter.ProductoViewHolder> {

    private static final NumberFormat EUROS = NumberFormat.getCurrencyInstance(Locale.forLanguageTag("es-ES"));

    private final List<Producto> productos;
    private final boolean alquiler;

    public ProductoAdapter(List<Producto> productos, boolean alquiler) {
        this.productos = productos;
        this.alquiler = alquiler;
    }

    @NonNull
    @Override
    public ProductoViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View vista = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_producto, parent, false);
        return new ProductoViewHolder(vista);
    }

    @Override
    public void onBindViewHolder(@NonNull ProductoViewHolder holder, int position) {
        Producto producto = productos.get(position);
        Context context = holder.itemView.getContext();

        holder.tvNombre.setText(producto.getNombre());
        holder.tvPrecio.setText(EUROS.format(alquiler ? producto.getPrecioAlquilerDia() : producto.getPrecioVenta()));
        holder.tvPorDia.setVisibility(alquiler ? View.VISIBLE : View.GONE);

        //PORTADA HECHA A MANO CON EL COLOR DE LA PLATAFORMA, SE VE SI NO HAY FOTO
        int color = producto.esVideojuego() ? colorPlataforma(producto.getPlataforma()) : R.color.color_oscuro;
        holder.flSinFoto.setBackgroundColor(ContextCompat.getColor(context, color));
        holder.tvInicial.setText(producto.getNombre().substring(0, 1));
        holder.tvEtiqueta.setText(producto.esVideojuego() ? producto.getPlataforma() : producto.getEmpresa());
        holder.tvTituloPortada.setText(producto.getNombre());

        if (producto.getMiniaturaUrl() != null) {
            //CON FOTO QUITAMOS LA PORTADA HECHA A MANO PARA QUE NO SE VEA DETRAS
            holder.flSinFoto.setVisibility(View.GONE);
            holder.ivFoto.setVisibility(View.VISIBLE);
            //LOS JUEGOS OCUPAN TODA LA TARJETA, LAS CONSOLAS Y MOVILES SE VEN ENTEROS SOBRE BLANCO
            int margen = producto.esVideojuego() ? 0 : context.getResources().getDimensionPixelSize(R.dimen.tienda_margen_foto);
            holder.ivFoto.setPadding(margen, margen, margen, margen);
            holder.ivFoto.setScaleType(producto.esVideojuego() ? ImageView.ScaleType.CENTER_CROP : ImageView.ScaleType.FIT_CENTER);
            //MIENTRAS SE DESCARGA LA FOTO SALE LA IMAGEN PROVISIONAL
            Glide.with(holder.itemView)
                    .load(producto.getMiniaturaUrl())
                    .placeholder(R.drawable.placeholder_producto)
                    .into(holder.ivFoto);
        } else {
            Glide.with(holder.itemView).clear(holder.ivFoto);
            holder.ivFoto.setVisibility(View.GONE);
            holder.flSinFoto.setVisibility(View.VISIBLE);
        }

        pintarAviso(holder, producto);

        //AL PULSAR SE ABRE LA FICHA DEL PRODUCTO (LA HACE MAITANE)
        holder.itemView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Intent intent = FichaProductoActivity.crearIntent(v.getContext(), producto.getId(), producto.esVideojuego());
                //SI VENIMOS DE ALQUILAR LA FICHA SE ABRE YA EN ALQUILAR
                intent.putExtra(FichaProductoActivity.EXTRA_EMPEZAR_ALQUILANDO, alquiler);
                v.getContext().startActivity(intent);
            }
        });
    }

    //SOLO SE AVISA CUANDO QUEDAN POCOS O NO QUEDA NINGUNO
    private void pintarAviso(ProductoViewHolder holder, Producto producto) {
        Context context = holder.itemView.getContext();
        int quedan = alquiler ? producto.getCopiasDisponibles() : producto.getStock();
        boolean agotado = quedan <= 0 || !producto.isDisponible();
        holder.itemView.setAlpha(agotado ? 0.55f : 1f);

        if (agotado) {
            holder.tvAviso.setText(alquiler ? R.string.tienda_alquilado : R.string.tienda_agotado);
            holder.tvAviso.setBackgroundResource(R.drawable.bg_pildora_hoja);
            holder.tvAviso.setTextColor(ContextCompat.getColor(context, R.color.color_texto));
        } else if (quedan == 1) {
            holder.tvAviso.setText(alquiler ? R.string.tienda_ultima_copia : R.string.tienda_ultima_unidad);
        } else if (quedan == 2) {
            holder.tvAviso.setText(context.getString(R.string.tienda_quedan, quedan));
        }
        if (!agotado && quedan <= 2) {
            holder.tvAviso.setBackgroundResource(R.drawable.bg_pildora_alerta);
            holder.tvAviso.setTextColor(ContextCompat.getColor(context, R.color.white));
        }
        holder.tvAviso.setVisibility(agotado || quedan <= 2 ? View.VISIBLE : View.GONE);
    }

    private int colorPlataforma(String plataforma) {
        if (plataforma.equals("PS5")) {
            return R.color.color_marca_texto;
        } else if (plataforma.equals("Xbox")) {
            return R.color.color_texto_suave;
        } else if (plataforma.equals("Switch")) {
            return R.color.color_marca_intenso;
        } else {
            return R.color.color_alquiler;
        }
    }

    @Override
    public int getItemCount() {
        return productos.size();
    }

    static class ProductoViewHolder extends RecyclerView.ViewHolder {
        FrameLayout flSinFoto;
        ImageView ivFoto;
        TextView tvInicial;
        TextView tvEtiqueta;
        TextView tvTituloPortada;
        TextView tvAviso;
        TextView tvNombre;
        TextView tvPrecio;
        TextView tvPorDia;

        ProductoViewHolder(@NonNull View itemView) {
            super(itemView);
            flSinFoto = itemView.findViewById(R.id.flProductoSinFoto);
            ivFoto = itemView.findViewById(R.id.ivProductoFoto);
            tvInicial = itemView.findViewById(R.id.tvProductoInicial);
            tvEtiqueta = itemView.findViewById(R.id.tvProductoEtiqueta);
            tvTituloPortada = itemView.findViewById(R.id.tvProductoTituloPortada);
            tvAviso = itemView.findViewById(R.id.tvProductoAviso);
            tvNombre = itemView.findViewById(R.id.tvProductoNombre);
            tvPrecio = itemView.findViewById(R.id.tvProductoPrecio);
            tvPorDia = itemView.findViewById(R.id.tvProductoPorDia);
        }
    }
}
