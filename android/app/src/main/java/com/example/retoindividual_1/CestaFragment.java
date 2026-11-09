package com.example.retoindividual_1;

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

import com.android.volley.AuthFailureError;
import com.android.volley.Request;
import com.android.volley.Response;
import com.android.volley.VolleyError;
import com.android.volley.toolbox.JsonArrayRequest;
import com.android.volley.toolbox.JsonObjectRequest;
import com.example.retoindividual_1.adaptadores.CestaAdapter;
import com.example.retoindividual_1.modelos.Cesta;
import com.example.retoindividual_1.modelos.Domicilio;
import com.example.retoindividual_1.network.ApiClient;
import com.example.retoindividual_1.utilidades.FormatosReparacion;
import com.google.android.material.dialog.MaterialAlertDialogBuilder;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;

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

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        return inflater.inflate(R.layout.fragment_cesta, container, false);
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

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

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        ApiClient.getInstance(requireContext()).getCola().cancelAll(this);
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
        ApiClient api = ApiClient.getInstance(requireContext());
        JsonArrayRequest peticion = new JsonArrayRequest(Request.Method.GET, ApiClient.BASE_URL + "domicilios", null,
                new Response.Listener<JSONArray>() {
                    @Override
                    public void onResponse(JSONArray respuesta) {
                        domicilios.clear();
                        for (int i = 0; i < respuesta.length(); i++) {
                            domicilios.add(new Domicilio(respuesta.optJSONObject(i)));
                        }
                        //SI LA QUE HABIA ELEGIDO YA NO ESTA (SE HA EDITADO O BORRADO) COGEMOS LA PRIMERA
                        Domicilio anterior = elegido;
                        elegido = domicilios.isEmpty() ? null : domicilios.get(0);
                        for (Domicilio domicilio : domicilios) {
                            if (anterior != null && domicilio.getId() == anterior.getId()) {
                                elegido = domicilio;
                            }
                        }
                        pintarDireccion();
                    }
                },
                new Response.ErrorListener() {
                    @Override
                    public void onErrorResponse(VolleyError error) {
                        tvDireccion.setText(ApiClient.mensajeDeError(error));
                    }
                }) {
            @Override
            public Map<String, String> getHeaders() throws AuthFailureError {
                return api.getCabeceras();
            }
        };
        peticion.setTag(this);
        ApiClient.getInstance(requireContext()).getCola().add(peticion);
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

    //SIN DIRECCIONES SE ABRE LA PANTALLA DE AÑADIR, CON DIRECCIONES SE ELIGE UNA EN UN DIALOGO
    private void cambiarDireccion() {
        if (domicilios.isEmpty()) {
            startActivity(NuevaDireccionActivity.crearIntent(requireContext(), null));
            return;
        }
        String[] textos = new String[domicilios.size()];
        for (int i = 0; i < domicilios.size(); i++) {
            textos[i] = domicilios.get(i).getLinea1() + " · " + domicilios.get(i).getCiudad();
        }
        new MaterialAlertDialogBuilder(requireContext())
                .setTitle(R.string.cesta_elegir_direccion)
                .setItems(textos, new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface dialogo, int posicion) {
                        elegido = domicilios.get(posicion);
                        pintarDireccion();
                    }
                })
                .show();
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

        enviar(ApiClient.BASE_URL + "pedidos", cuerpo, new Response.Listener<JSONObject>() {
            @Override
            public void onResponse(JSONObject respuesta) {
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

        enviar(ApiClient.BASE_URL + "alquileres", cuerpo, new Response.Listener<JSONObject>() {
            @Override
            public void onResponse(JSONObject respuesta) {
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

    //POST CON EL TOKEN. SI FALLA (POR EJEMPLO 409 SIN STOCK) SE PARA Y LA CESTA SE QUEDA CON LO QUE FALTA
    private void enviar(String url, JSONObject cuerpo, Response.Listener<JSONObject> siSaleBien) {
        ApiClient api = ApiClient.getInstance(requireContext());
        JsonObjectRequest peticion = new JsonObjectRequest(Request.Method.POST, url, cuerpo, siSaleBien,
                new Response.ErrorListener() {
                    @Override
                    public void onErrorResponse(VolleyError error) {
                        btnConfirmar.setEnabled(true);
                        pintarCesta();
                        Toast.makeText(getContext(), ApiClient.mensajeDeError(error), Toast.LENGTH_LONG).show();
                    }
                }) {
            @Override
            public Map<String, String> getHeaders() throws AuthFailureError {
                return api.getCabeceras();
            }
        };
        peticion.setTag(this);
        api.getCola().add(peticion);
    }
}
