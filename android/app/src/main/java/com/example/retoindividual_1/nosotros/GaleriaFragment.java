package com.example.retoindividual_1.nosotros;

import com.example.retoindividual_1.R;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import com.airbnb.lottie.LottieAnimationView;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.GridLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.example.retoindividual_1.adaptadores.FotoTiendaAdapter;
import com.example.retoindividual_1.modelos.FotoTienda;
import com.example.retoindividual_1.datos.Repositorio;

import java.util.List;

//PESTAÑA GALERIA, LAS FOTOS SALEN DE /tienda/fotos
public class GaleriaFragment extends Fragment {

    private Repositorio datos;

    private RecyclerView rvGaleria;
    private LottieAnimationView pbGaleria;
    private TextView tvAviso;

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        return inflater.inflate(R.layout.fragment_galeria, container, false);
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        datos = new Repositorio(requireContext(), getViewLifecycleOwner());

        rvGaleria = view.findViewById(R.id.rvGaleria);
        pbGaleria = view.findViewById(R.id.pbGaleria);
        tvAviso = view.findViewById(R.id.tvGaleriaAviso);

        //2 COLUMNAS, LAS FOTOS ANCHAS OCUPAN LAS DOS
        GridLayoutManager columnas = new GridLayoutManager(getContext(), 2);
        columnas.setSpanSizeLookup(new GridLayoutManager.SpanSizeLookup() {
            @Override
            public int getSpanSize(int position) {
                return FotoTiendaAdapter.esAncha(position) ? 2 : 1;
            }
        });
        rvGaleria.setLayoutManager(columnas);

        cargarFotos();
    }

    private void cargarFotos() {
        datos.fotosTienda(new Repositorio.Resultado<List<FotoTienda>>() {
            @Override
            public void bien(List<FotoTienda> fotos) {
                pbGaleria.setVisibility(View.GONE);
                if (fotos.isEmpty()) {
                    tvAviso.setText(R.string.nosotros_sin_fotos);
                    tvAviso.setVisibility(View.VISIBLE);
                } else {
                    rvGaleria.setAdapter(new FotoTiendaAdapter(fotos));
                    rvGaleria.scheduleLayoutAnimation();
                }
            }

            @Override
            public void mal(String mensaje) {
                pbGaleria.setVisibility(View.GONE);
                tvAviso.setText(mensaje);
                tvAviso.setVisibility(View.VISIBLE);
            }
        });
    }
}
