package com.example.retoindividual_1.inicio;

import com.example.retoindividual_1.R;
import com.example.retoindividual_1.alquileres.MisAlquileresActivity;
import com.example.retoindividual_1.principal.MainActivity;
import com.example.retoindividual_1.tienda.TiendaFragment;
import android.content.Intent;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.content.ContextCompat;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.bumptech.glide.Glide;
import com.example.retoindividual_1.adaptadores.ProductoAdapter;
import com.example.retoindividual_1.datos.Repositorio;
import com.example.retoindividual_1.modelos.Alquiler;
import com.example.retoindividual_1.modelos.Producto;
import com.example.retoindividual_1.modelos.Reparacion;
import com.example.retoindividual_1.utilidades.Animaciones;
import com.example.retoindividual_1.utilidades.FormatosReparacion;
import com.google.android.material.progressindicator.CircularProgressIndicator;


import java.util.List;

//INICIO (03 DEL MOCKUP): EL SALUDO, ACCESOS A TALLER Y TIENDA, LO QUE TIENES EN CURSO Y LAS NOVEDADES
public class InicioFragment extends Fragment {

    private TextView tvHola;
    private LinearLayout llReparacion;
    private CircularProgressIndicator cpiReparacion;
    private TextView tvReparacionPaso;
    private TextView tvReparacionTitulo;
    private TextView tvReparacionEstado;
    private LinearLayout llAlquiler;
    private ImageView ivAlquiler;
    private TextView tvAlquilerNombre;
    private TextView tvAlquilerDias;
    private TextView tvAlquilerDiasTexto;
    private LinearLayout llNovedadesTitulo;
    private RecyclerView rvNovedades;
    private Repositorio datos;

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        return inflater.inflate(R.layout.fragment_inicio, container, false);
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        datos = new Repositorio(requireContext(), getViewLifecycleOwner());
        tvHola = view.findViewById(R.id.tvInicioHola);
        llReparacion = view.findViewById(R.id.llInicioReparacion);
        cpiReparacion = view.findViewById(R.id.cpiInicioReparacion);
        tvReparacionPaso = view.findViewById(R.id.tvInicioReparacionPaso);
        tvReparacionTitulo = view.findViewById(R.id.tvInicioReparacionTitulo);
        tvReparacionEstado = view.findViewById(R.id.tvInicioReparacionEstado);
        llAlquiler = view.findViewById(R.id.llInicioAlquiler);
        ivAlquiler = view.findViewById(R.id.ivInicioAlquiler);
        tvAlquilerNombre = view.findViewById(R.id.tvInicioAlquilerNombre);
        tvAlquilerDias = view.findViewById(R.id.tvInicioAlquilerDias);
        tvAlquilerDiasTexto = view.findViewById(R.id.tvInicioAlquilerDiasTexto);
        llNovedadesTitulo = view.findViewById(R.id.llInicioNovedadesTitulo);
        rvNovedades = view.findViewById(R.id.rvInicioNovedades);

        rvNovedades.setLayoutManager(new LinearLayoutManager(getContext(), LinearLayoutManager.HORIZONTAL, false));

        //LOS ACCESOS PULSAN LA PESTAÑA DE ABAJO, ASI LA BARRA SE MARCA BIEN
        view.findViewById(R.id.btnInicioPedirReparacion).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                irAPestana(R.id.llNavTaller);
            }
        });
        view.findViewById(R.id.llInicioComprar).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                irAPestana(R.id.llNavTienda);
            }
        });
        view.findViewById(R.id.tvInicioVerTodo).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                irAPestana(R.id.llNavTienda);
            }
        });
        //PARA ALQUILAR LE DEJAMOS UN AVISO A LA TIENDA PARA QUE SE ABRA YA EN ALQUILAR
        view.findViewById(R.id.llInicioAlquilar).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                Bundle modo = new Bundle();
                modo.putBoolean(TiendaFragment.EMPEZAR_ALQUILANDO, true);
                getParentFragmentManager().setFragmentResult(TiendaFragment.MODO, modo);
                irAPestana(R.id.llNavTienda);
            }
        });
        llAlquiler.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                startActivity(new Intent(requireContext(), MisAlquileresActivity.class));
            }
        });

        cargarUsuario();
        cargarReparacion();
        cargarAlquiler();
        cargarNovedades();
    }

    private void irAPestana(int idPestana) {
        requireActivity().findViewById(idPestana).performClick();
    }

    //"Hola, Ane". SI FALLA SE QUEDA EN "Hola"
    private void cargarUsuario() {
        datos.nombreUsuario(new SiSaleBien<String>() {
            @Override
            public void bien(String nombre) {
                tvHola.setText(getString(R.string.inicio_hola, nombre));
            }
        });
    }

    //LA PRIMERA REPARACION QUE SIGA EN CURSO, CON SU ANILLO DE PASOS
    private void cargarReparacion() {
        datos.reparaciones(20, new SiSaleBien<List<Reparacion>>() {
            @Override
            public void bien(List<Reparacion> reparaciones) {
                for (Reparacion reparacion : reparaciones) {
                    if (reparacion.estaEnCurso()) {
                        pintarReparacion(reparacion);
                        return;
                    }
                }
            }
        });
    }

    private void pintarReparacion(Reparacion reparacion) {
        cpiReparacion.setMax(reparacion.getTotalPasos());
        //EL CIRCULO SE VA LLENANDO HASTA EL PASO EN EL QUE ESTA
        cpiReparacion.setProgressCompat(reparacion.getPaso(), true);
        tvReparacionPaso.setText(getString(R.string.inicio_paso, reparacion.getPaso(), reparacion.getTotalPasos()));
        tvReparacionTitulo.setText(FormatosReparacion.titulo(requireContext(),
                reparacion.getTipoDispositivo(), reparacion.getMarca(), reparacion.getModelo()));
        tvReparacionEstado.setText(reparacion.getEstadoTexto());
        Animaciones.aparecer(llReparacion);

        //EL SEGUIMIENTO LO ABRE LA ACTIVITY, COMO DESDE EL TALLER
        llReparacion.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                ((MainActivity) requireActivity()).abrirSeguimiento(reparacion.getId());
            }
        });
    }

    //EL PRIMER ALQUILER SIN DEVOLVER, CON LOS DIAS QUE QUEDAN (O LOS DE RETRASO EN ROJO)
    private void cargarAlquiler() {
        datos.alquileres(20, new SiSaleBien<List<Alquiler>>() {
            @Override
            public void bien(List<Alquiler> alquileres) {
                for (Alquiler alquiler : alquileres) {
                    if (!alquiler.estaDevuelto() && !alquiler.getLineas().isEmpty()) {
                        pintarAlquiler(alquiler);
                        return;
                    }
                }
            }
        });
    }

    private void pintarAlquiler(Alquiler alquiler) {
        Producto juego = alquiler.getLineas().get(0).getVideojuego();
        int dias = Math.abs(alquiler.getDiasRestantes());

        tvAlquilerNombre.setText(juego.getNombre());
        tvAlquilerDias.setText(String.valueOf(dias));
        tvAlquilerDias.setTextColor(ContextCompat.getColor(requireContext(),
                alquiler.estaRetrasado() ? R.color.color_alerta : R.color.color_texto));
        tvAlquilerDiasTexto.setText(getResources().getQuantityString(
                alquiler.estaRetrasado() ? R.plurals.alq_dias_retraso : R.plurals.alq_dias_quedan, dias));
        Glide.with(this).load(juego.getMiniaturaUrl())
                .placeholder(R.drawable.placeholder_producto)
                .error(R.drawable.placeholder_producto)
                .into(ivAlquiler);
        Animaciones.aparecer(llAlquiler);
    }

    //LOS ULTIMOS PRODUCTOS DE LA TIENDA EN UNA FILA QUE SE DESLIZA
    private void cargarNovedades() {
        datos.productos(null, null, 1, 8, new SiSaleBien<Repositorio.Pagina<Producto>>() {
            @Override
            public void bien(Repositorio.Pagina<Producto> pagina) {
                if (!pagina.getLista().isEmpty()) {
                    rvNovedades.setAdapter(new ProductoAdapter(pagina.getLista(), false));
                    rvNovedades.scheduleLayoutAnimation();
                    llNovedadesTitulo.setVisibility(View.VISIBLE);
                }
            }
        });
    }

    //SI FALLA ALGO NO SE ENSEÑA ESA PARTE Y YA, EL INICIO NO SE LLENA DE AVISOS
    private abstract static class SiSaleBien<T> implements Repositorio.Resultado<T> {
        @Override
        public void mal(String mensaje) {
        }
    }
}
