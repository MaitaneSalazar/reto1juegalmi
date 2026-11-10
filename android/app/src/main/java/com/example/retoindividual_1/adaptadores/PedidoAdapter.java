package com.example.retoindividual_1.adaptadores;

import android.content.Context;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.bumptech.glide.Glide;
import com.example.retoindividual_1.R;
import com.example.retoindividual_1.modelos.Pedido;
import com.example.retoindividual_1.utilidades.FormatosReparacion;

import java.util.HashSet;
import java.util.List;
import java.util.Set;

//ADAPTADOR DE LOS PEDIDOS ANTERIORES, CON LAS FOTOS DE SUS PRODUCTOS Y CANCELAR SI TODAVIA SE PUEDE
public class PedidoAdapter extends RecyclerView.Adapter<PedidoAdapter.PedidoViewHolder> {

    //LO QUE PASA AL PULSAR CANCELAR LO DECIDE LA ACTIVITY
    public interface AlCancelar {
        void cancelar(Pedido pedido);
    }

    private static final int MAX_FOTOS = 3;

    private final List<Pedido> pedidos;
    private final AlCancelar alCancelar;
    //LOS PEDIDOS CON "VER MAS" ABIERTO. SE GUARDAN AQUI PORQUE EL RecyclerView REUTILIZA LAS TARJETAS AL HACER SCROLL
    private final Set<Integer> abiertos = new HashSet<>();

    public PedidoAdapter(List<Pedido> pedidos, AlCancelar alCancelar) {
        this.pedidos = pedidos;
        this.alCancelar = alCancelar;
    }

    @NonNull
    @Override
    public PedidoViewHolder onCreateViewHolder(@NonNull ViewGroup parent, int viewType) {
        View vista = LayoutInflater.from(parent.getContext())
                .inflate(R.layout.item_pedido, parent, false);
        return new PedidoViewHolder(vista);
    }

    @Override
    public void onBindViewHolder(@NonNull PedidoViewHolder holder, int position) {
        Pedido pedido = pedidos.get(position);
        Context context = holder.itemView.getContext();

        holder.tvNombre.setText(nombre(context, pedido));
        holder.tvResumen.setText(context.getString(R.string.ped_resumen, pedido.getId(),
                FormatosReparacion.fechaCorta(pedido.getFecha()), conMayuscula(pedido.getEstado())));
        holder.tvTotal.setText(FormatosReparacion.precio(pedido.getTotal()));
        pintarFotos(holder.llFotos, pedido);

        pintarVerMas(holder, pedido);

        holder.btnCancelar.setVisibility(pedido.isSePuedeCancelar() ? View.VISIBLE : View.GONE);
        holder.btnCancelar.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                alCancelar.cancelar(pedido);
            }
        });
    }

    //"VER MAS · 3 ARTICULOS" DESPLIEGA LAS LINEAS DEL PEDIDO (SALEN DEL DETALLE QUE YA SE PIDE PARA LAS FOTOS)
    private void pintarVerMas(PedidoViewHolder holder, Pedido pedido) {
        Context context = holder.itemView.getContext();
        List<Pedido.Linea> lineas = pedido.getLineas();
        boolean abierto = abiertos.contains(pedido.getId());

        holder.tvVerMas.setVisibility(lineas.size() > 1 ? View.VISIBLE : View.GONE);
        holder.tvVerMas.setText(abierto ? context.getString(R.string.ped_ver_menos)
                : context.getString(R.string.ped_ver_mas, lineas.size()));
        holder.tvVerMas.setCompoundDrawablesRelativeWithIntrinsicBounds(0, 0,
                abierto ? R.drawable.ic_contraer : R.drawable.ic_expandir, 0);
        holder.tvVerMas.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (!abiertos.remove(pedido.getId())) {
                    abiertos.add(pedido.getId());
                }
                notifyItemChanged(holder.getBindingAdapterPosition());
            }
        });

        holder.llLineas.removeAllViews();
        holder.llLineas.setVisibility(abierto ? View.VISIBLE : View.GONE);
        if (!abierto) {
            return;
        }
        LayoutInflater inflater = LayoutInflater.from(context);
        for (Pedido.Linea linea : lineas) {
            View fila = inflater.inflate(R.layout.item_linea_pedido, holder.llLineas, false);
            ImageView ivFoto = fila.findViewById(R.id.ivLineaFoto);
            ivFoto.setClipToOutline(true);
            Glide.with(ivFoto)
                    .load(linea.getUrl())
                    .placeholder(R.drawable.placeholder_producto)
                    .error(R.drawable.placeholder_producto)
                    .into(ivFoto);
            ((TextView) fila.findViewById(R.id.tvLineaNombre)).setText(linea.getNombre());
            ((TextView) fila.findViewById(R.id.tvLineaCantidad)).setText(context.getString(R.string.ped_linea_cantidad,
                    linea.getCantidad(), FormatosReparacion.precio(linea.getPrecioUnitario())));
            ((TextView) fila.findViewById(R.id.tvLineaSubtotal)).setText(FormatosReparacion.precio(linea.getSubtotal()));
            holder.llLineas.addView(fila);
        }
    }

    //"Elden Ring +2" SI EL PEDIDO LLEVA MAS UNIDADES. LA USA TAMBIEN LA TARJETA GRANDE
    public static String nombre(Context context, Pedido pedido) {
        if (pedido.getUnidades() > 1) {
            return context.getString(R.string.ped_mas, pedido.getPrimerProducto(), pedido.getUnidades() - 1);
        }
        return pedido.getPrimerProducto();
    }

    //CREAMOS UNA FOTO PEQUEÑA POR PRODUCTO CON SU xCANTIDAD SI ES MAS DE UNO. LA USA TAMBIEN LA TARJETA GRANDE
    //SI HAY MAS DE 3 PRODUCTOS SOLO SALEN 3 Y UN RECUADRO CON + QUE NO HACE NADA
    public static void pintarFotos(LinearLayout llFotos, Pedido pedido) {
        LayoutInflater inflater = LayoutInflater.from(llFotos.getContext());
        List<Pedido.Miniatura> miniaturas = pedido.getMiniaturas();
        llFotos.removeAllViews();
        for (int i = 0; i < Math.min(miniaturas.size(), MAX_FOTOS); i++) {
            Pedido.Miniatura miniatura = miniaturas.get(i);
            View vista = inflater.inflate(R.layout.item_miniatura_pedido, llFotos, false);
            Glide.with(llFotos)
                    .load(miniatura.getUrl())
                    .placeholder(R.drawable.placeholder_producto)
                    .error(R.drawable.placeholder_producto)
                    .into((ImageView) vista.findViewById(R.id.ivMiniatura));
            TextView tvCantidad = vista.findViewById(R.id.tvMiniaturaCantidad);
            tvCantidad.setText(llFotos.getContext().getString(R.string.ped_por_cantidad, miniatura.getCantidad()));
            tvCantidad.setVisibility(miniatura.getCantidad() > 1 ? View.VISIBLE : View.GONE);
            llFotos.addView(vista);
        }
        if (miniaturas.size() > MAX_FOTOS) {
            llFotos.addView(inflater.inflate(R.layout.item_miniatura_mas, llFotos, false));
        }
    }

    //"cancelado" -> "Cancelado" (LA API MANDA EL ESTADO EN MINUSCULA)
    private static String conMayuscula(String texto) {
        return texto.isEmpty() ? texto : texto.substring(0, 1).toUpperCase() + texto.substring(1);
    }

    @Override
    public int getItemCount() {
        return pedidos.size();
    }

    static class PedidoViewHolder extends RecyclerView.ViewHolder {
        TextView tvNombre;
        TextView tvResumen;
        TextView tvTotal;
        LinearLayout llFotos;
        TextView tvVerMas;
        LinearLayout llLineas;
        Button btnCancelar;

        PedidoViewHolder(@NonNull View itemView) {
            super(itemView);
            tvNombre = itemView.findViewById(R.id.tvPedidoNombre);
            tvResumen = itemView.findViewById(R.id.tvPedidoResumen);
            tvTotal = itemView.findViewById(R.id.tvPedidoTotal);
            llFotos = itemView.findViewById(R.id.llPedidoFotos);
            tvVerMas = itemView.findViewById(R.id.tvPedidoVerMas);
            llLineas = itemView.findViewById(R.id.llPedidoLineas);
            btnCancelar = itemView.findViewById(R.id.btnPedidoCancelar);
        }
    }
}