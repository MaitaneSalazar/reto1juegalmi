package com.example.retoindividual_1.cesta;

import com.example.retoindividual_1.R;
import com.example.retoindividual_1.alquileres.MisAlquileresActivity;
import com.example.retoindividual_1.cuenta.DireccionesActivity;
import com.example.retoindividual_1.cuenta.NuevaDireccionActivity;
import com.example.retoindividual_1.network.SessionManager;
import com.example.retoindividual_1.pedidos.MisPedidosActivity;
import android.content.DialogInterface;
import android.content.Intent;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.example.retoindividual_1.adaptadores.CestaAdapter;
import com.example.retoindividual_1.datos.Repositorio;
import com.example.retoindividual_1.modelos.Cesta;
import com.example.retoindividual_1.modelos.Domicilio;
import com.example.retoindividual_1.utilidades.FormatosReparacion;
import com.google.android.material.dialog.MaterialAlertDialogBuilder;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;

//CESTA (07 DEL MOCKUP): LO QUE SE HA AÑADIDO DESDE LA FICHA, SE MANDA CON POST /pedidos
public class CestaFragment extends Fragment {

    private LinearLayout llVacia;
    private LinearLayout llContenido;
    private RecyclerView rvCesta;
    private TextView tvDireccion;
    private TextView tvCambiar;
    private TextView tvTotal;
    private Button btnConfirmar;

    private final List<Domicilio> domicilios = new ArrayList<>();
    private Domicilio elegido;
    private boolean huboPedido;
    private Repositorio datos;

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        return inflater.inflate(R.layout.fragment_cesta, container, false);
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        datos = new Repositorio(requireContext(), getViewLifecycleOwner());
        llVacia = view.findViewById(R.id.llCestaVacia);
        llContenido = view.findViewById(R.id.llCestaContenido);
        rvCesta = view.findViewById(R.id.rvCesta);
        tvDireccion = view.findViewById(R.id.tvCestaDireccion);
        tvCambiar = view.findViewById(R.id.tvCestaCambiar);
        tvTotal = view.findViewById(R.id.tvCestaTotal);
        btnConfirmar = view.findViewById(R.id.btnCestaConfirmar);

        rvCesta.setLayoutManager(new LinearLayoutManager(getContext()));

        tvCambiar.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                cambiarDireccion();
            }
        });

        btnConfirmar.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                confirmarPedido();
            }
        });
    }

    //EN onResume PORQUE SE PUEDE HABER AÑADIDO ALGO EN LA FICHA O UNA DIRECCION NUEVA
    @Override
    public void onResume() {
        super.onResume();
        pintarCesta();
        cargarDomicilios();
    }

    private void pintarCesta() {
        boolean vacia = Cesta.getLineas().isEmpty();
        llVacia.setVisibility(vacia ? View.VISIBLE : View.GONE);
        llContenido.setVisibility(vacia ? View.GONE : View.VISIBLE);
        tvTotal.setText(FormatosReparacion.precio(Cesta.getTotal()));

        rvCesta.setAdapter(new CestaAdapter(Cesta.getLineas(), new CestaAdapter.Acciones() {
            @Override
            public void sumar(Cesta.Linea linea) {
                //sumar YA MIRA EL STOCK (O LAS COPIAS) QUE QUEDAN
                if (!Cesta.sumar(linea)) {
                    Toast.makeText(getContext(), R.string.cesta_sin_stock, Toast.LENGTH_SHORT).show();
                }
                pintarCesta();
            }

            @Override
            public void restar(Cesta.Linea linea) {
                Cesta.restar(linea);
                pintarCesta();
            }
        }));
    }

    //DIRECCIONES DEL CLIENTE, LA API LAS MANDA DE LA MAS NUEVA A LA MAS ANTIGUA
    private void cargarDomicilios() {
        datos.domicilios(new Repositorio.Resultado<List<Domicilio>>() {
            @Override
            public void bien(List<Domicilio> lista) {
                domicilios.clear();
                domicilios.addAll(lista);
                //LA ELEGIDA ES LA QUE SE TOCO EN DIRECCIONES. SI NO HAY O YA NO EXISTE, LA PRIMERA
                SessionManager sesion = new SessionManager(requireContext());
                elegido = domicilios.isEmpty() ? null : domicilios.get(0);
                for (Domicilio domicilio : domicilios) {
                    if (domicilio.getId() == sesion.getDomicilio()) {
                        elegido = domicilio;
                    }
                }
                sesion.guardarDomicilio(elegido == null ? -1 : elegido.getId());
                pintarDireccion();
            }

            @Override
            public void mal(String mensaje) {
                tvDireccion.setText(mensaje);
            }
        });
    }

    private void pintarDireccion() {
        if (elegido == null) {
            tvDireccion.setText(R.string.cesta_anadir_direccion);
            tvCambiar.setText(R.string.cesta_anadir);
        } else {
            tvDireccion.setText(elegido.getLinea1() + " · " + elegido.getCiudad());
            tvCambiar.setText(R.string.cesta_cambiar);
        }
    }

    //LA DIRECCION SE ELIGE EN DIRECCIONES. AL VOLVER, onResume RECARGA Y PINTA LA ELEGIDA
    private void cambiarDireccion() {
        if (domicilios.isEmpty()) {
            startActivity(NuevaDireccionActivity.crearIntent(requireContext(), null));
            return;
        }
        startActivity(DireccionesActivity.elegirDesdeCesta(requireContext()));
    }

    //PRIMERO EL PEDIDO CON LO QUE SE COMPRA Y LUEGO LOS ALQUILERES. LO QUE SALE BIEN SE QUITA DE LA CESTA
    private void confirmarPedido() {
        List<Cesta.Linea> compras = new ArrayList<>();
        for (Cesta.Linea linea : Cesta.getLineas()) {
            if (!linea.isAlquiler()) {
                compras.add(linea);
            }
        }
        //LA DIRECCION SOLO HACE FALTA SI HAY ALGO QUE ENVIAR
        if (!compras.isEmpty() && elegido == null) {
            Toast.makeText(getContext(), R.string.cesta_sin_direccion, Toast.LENGTH_SHORT).show();
            return;
        }

        //DESACTIVAMOS EL BOTON PARA QUE NO SE MANDE DOS VECES
        btnConfirmar.setEnabled(false);
        huboPedido = false;
        if (compras.isEmpty()) {
            mandarAlquiler();
        } else {
            mandarPedido(compras);
        }
    }

    //MANDAMOS {"id_domicilio", "lineas": [{"id_producto", "cantidad"}]}
    private void mandarPedido(List<Cesta.Linea> compras) {
        JSONObject cuerpo = new JSONObject();
        try {
            JSONArray lineas = new JSONArray();
            for (Cesta.Linea linea : compras) {
                lineas.put(new JSONObject()
                        .put("id_producto", linea.getProducto().getId())
                        .put("cantidad", linea.getCantidad()));
            }
            cuerpo.put("id_domicilio", elegido.getId());
            cuerpo.put("lineas", lineas);
        } catch (JSONException e) {
            btnConfirmar.setEnabled(true);
            return;
        }

        datos.crearPedido(cuerpo, new AlEnviar() {
            @Override
            public void bien(JSONObject respuesta) {
                Cesta.getLineas().removeAll(compras);
                huboPedido = true;
                mandarAlquiler();
            }
        });
    }

    //LA API SOLO DEJA UNA COPIA DE CADA JUEGO POR ALQUILER Y LOS MISMOS DIAS PARA TODOS,
    //ASI QUE CADA VEZ MANDAMOS UNA COPIA DE CADA JUEGO QUE TENGA LOS MISMOS DIAS, HASTA QUE NO QUEDE NINGUNO
    private void mandarAlquiler() {
        List<Cesta.Linea> tanda = new ArrayList<>();
        for (Cesta.Linea linea : Cesta.getLineas()) {
            if (linea.isAlquiler() && (tanda.isEmpty() || linea.getDias() == tanda.get(0).getDias())) {
                tanda.add(linea);
            }
        }
        if (tanda.isEmpty()) {
            terminar();
            return;
        }

        JSONObject cuerpo = new JSONObject();
        try {
            JSONArray juegos = new JSONArray();
            for (Cesta.Linea linea : tanda) {
                juegos.put(linea.getProducto().getId());
            }
            cuerpo.put("dias", tanda.get(0).getDias());
            cuerpo.put("videojuegos", juegos);
        } catch (JSONException e) {
            btnConfirmar.setEnabled(true);
            return;
        }

        datos.crearAlquiler(cuerpo, new AlEnviar() {
            @Override
            public void bien(JSONObject respuesta) {
                for (Cesta.Linea linea : tanda) {
                    Cesta.restar(linea);
                }
                mandarAlquiler();
            }
        });
    }

    //TODO HA IDO BIEN: SE ABRE MIS PEDIDOS, O MIS ALQUILERES SI SOLO SE HA ALQUILADO
    private void terminar() {
        btnConfirmar.setEnabled(true);
        pintarCesta();
        Toast.makeText(getContext(), huboPedido ? R.string.cesta_pedido_ok : R.string.cesta_alquiler_ok, Toast.LENGTH_SHORT).show();
        startActivity(new Intent(requireContext(), huboPedido ? MisPedidosActivity.class : MisAlquileresActivity.class));
    }

    //SI FALLA UN ENVIO (POR EJEMPLO 409 SIN STOCK) SE PARA Y LA CESTA SE QUEDA CON LO QUE FALTA
    private abstract class AlEnviar implements Repositorio.Resultado<JSONObject> {
        @Override
        public void mal(String mensaje) {
            btnConfirmar.setEnabled(true);
            pintarCesta();
            Toast.makeText(getContext(), mensaje, Toast.LENGTH_LONG).show();
        }
    }
}
