package com.example.retoindividual_1.adaptadores;

import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.recyclerview.widget.RecyclerView;

import com.example.retoindividual_1.R;
import com.example.retoindividual_1.modelos.Domicilio;

import java.util.List;

public class DomicilioAdapter extends RecyclerView.Adapter<DomicilioAdapter.Holder> {

    public interface Acciones {
        void editar(Domicilio domicilio);

        void borrar(Domicilio domicilio);
    }

    private final List<Domicilio> domicilios;
    private final Acciones acciones;

    public DomicilioAdapter(List<Domicilio> domicilios, Acciones acciones) {
        this.domicilios = domicilios;
        this.acciones = acciones;
    }

    @NonNull
    @Override
    public Holder onCreateViewHolder(@NonNull ViewGroup padre, int tipo) {
        return new Holder(LayoutInflater.from(padre.getContext()).inflate(R.layout.item_domicilio, padre, false));
    }

    @Override
    public void onBindViewHolder(@NonNull Holder holder, int posicion) {
        Domicilio domicilio = domicilios.get(posicion);
        holder.tvLinea1.setText(domicilio.getLinea1());
        holder.tvLinea2.setText(holder.itemView.getContext().getString(R.string.dir_linea2,
                domicilio.getCodigoPostal(), domicilio.getCiudad(), domicilio.getProvincia()));
        holder.btnEditar.setOnClickListener(v -> acciones.editar(domicilio));
        holder.btnBorrar.setOnClickListener(v -> acciones.borrar(domicilio));
    }

    @Override
    public int getItemCount() {
        return domicilios.size();
    }

    static class Holder extends RecyclerView.ViewHolder {
        final TextView tvLinea1;
        final TextView tvLinea2;
        final View btnEditar;
        final View btnBorrar;

        Holder(View vista) {
            super(vista);
            tvLinea1 = vista.findViewById(R.id.tvDomicilioLinea1);
            tvLinea2 = vista.findViewById(R.id.tvDomicilioLinea2);
            btnEditar = vista.findViewById(R.id.btnDomicilioEditar);
            btnBorrar = vista.findViewById(R.id.btnDomicilioBorrar);
        }
    }
}