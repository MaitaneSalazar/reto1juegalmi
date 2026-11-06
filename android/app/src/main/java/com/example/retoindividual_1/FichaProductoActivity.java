package com.example.retoindividual_1;

import android.content.Context;
import android.content.Intent;
import android.content.res.ColorStateList;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;

import androidx.core.content.ContextCompat;

import com.android.volley.AuthFailureError;
import com.android.volley.Request;
import com.android.volley.Response;
import com.android.volley.VolleyError;
import com.android.volley.toolbox.JsonObjectRequest;
import com.bumptech.glide.Glide;
import com.example.retoindividual_1.modelos.Cesta;
import com.example.retoindividual_1.modelos.Producto;
import com.example.retoindividual_1.network.ApiClient;
import com.google.android.material.tabs.TabLayout;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.text.NumberFormat;
import java.util.Locale;
import java.util.Map;

//FICHA DE UN PRODUCTO, SE PIDE A LA API POR SU ID
public class FichaProductoActivity extends PaginaMenuActivity {

    public static final String EXTRA_ID_PRODUCTO = "id_producto";
    public static final String EXTRA_SE_ALQUILA = "se_alquila";
    public static final String EXTRA_EMPEZAR_ALQUILANDO = "empezar_alquilando";

    private static final NumberFormat EUROS = NumberFormat.getCurrencyInstance(Locale.forLanguageTag("es-ES"));
    private static final int[] DIAS = {1, 3, 5, 7};

    private ImageView ivFoto;
    private TextView tvPlataforma;
    private ProgressBar pbFicha;
    private TextView tvError;
    private LinearLayout llDatos;
    private TextView tvNombre;
    private TextView tvEtiqueta1;
    private TextView tvEtiqueta2;
    private TextView tvDescripcion;
    private TabLayout tlModo;
    private LinearLayout llDias;
    private TextView[] tvDias;
    private LinearLayout llPie;
    private TextView tvPrecio;
    private TextView tvPrecioDetalle;
    private Button btnFicha;

    private Producto producto;
    private boolean alquilando;
    private int diasElegidos = 3;

    //ASI SE ABRE LA FICHA DESDE CUALQUIER SITIO SIN EQUIVOCARSE CON LOS EXTRAS
    public static Intent crearIntent(Context context, int idProducto, boolean seAlquila) {
        Intent intent = new Intent(context, FichaProductoActivity.class);
        intent.putExtra(EXTRA_ID_PRODUCTO, idProducto);
        intent.putExtra(EXTRA_SE_ALQUILA, seAlquila);
        return intent;
    }

    @Override
    protected int getLayout() {
        return R.layout.activity_ficha_producto;
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        ivFoto = findViewById(R.id.ivFichaFoto);
        tvPlataforma = findViewById(R.id.tvFichaPlataforma);
        pbFicha = findViewById(R.id.pbFicha);
        tvError = findViewById(R.id.tvFichaError);
        llDatos = findViewById(R.id.llFichaDatos);
        tvNombre = findViewById(R.id.tvFichaNombre);
        tvEtiqueta1 = findViewById(R.id.tvFichaEtiqueta1);
        tvEtiqueta2 = findViewById(R.id.tvFichaEtiqueta2);
        tvDescripcion = findViewById(R.id.tvFichaDescripcion);
        tlModo = findViewById(R.id.tlFichaModo);
        llDias = findViewById(R.id.llFichaDias);
        tvDias = new TextView[]{findViewById(R.id.tvFichaDia1), findViewById(R.id.tvFichaDia3),
                findViewById(R.id.tvFichaDia5), findViewById(R.id.tvFichaDia7)};
        llPie = findViewById(R.id.llFichaPie);
        tvPrecio = findViewById(R.id.tvFichaPrecio);
        tvPrecioDetalle = findViewById(R.id.tvFichaPrecioDetalle);
        btnFicha = findViewById(R.id.btnFicha);

        boolean seAlquila = getIntent().getBooleanExtra(EXTRA_SE_ALQUILA, false);
        alquilando = seAlquila && getIntent().getBooleanExtra(EXTRA_EMPEZAR_ALQUILANDO, false);
        tlModo.setVisibility(seAlquila ? View.VISIBLE : View.GONE);

        //CAMBIAMOS ENTRE COMPRAR Y ALQUILAR
        tlModo.addOnTabSelectedListener(new TabLayout.OnTabSelectedListener() {
            @Override
            public void onTabSelected(TabLayout.Tab tab) {
                alquilando = tab.getPosition() == 1;
                pintarModo();
            }

            @Override
            public void onTabUnselected(TabLayout.Tab tab) {
            }

            @Override
            public void onTabReselected(TabLayout.Tab tab) {
            }
        });

        //CADA BALDOSA ELIGE SUS DIAS
        for (int i = 0; i < tvDias.length; i++) {
            final int dias = DIAS[i];
            tvDias[i].setText(getResources().getQuantityString(R.plurals.ficha_dias, dias, dias));
            tvDias[i].setOnClickListener(new View.OnClickListener() {
                @Override
                public void onClick(View v) {
                    diasElegidos = dias;
                    pintarModo();
                }
            });
        }

        btnFicha.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (alquilando) {
                    alquilar();
                } else {
                    anadirCesta();
                }
            }
        });

        cargarProducto(getIntent().getIntExtra(EXTRA_ID_PRODUCTO, -1));
    }

    //PEDIMOS EL PRODUCTO A LA API
    private void cargarProducto(int id) {
        JsonObjectRequest peticion = new JsonObjectRequest(Request.Method.GET, ApiClient.BASE_URL + "productos/" + id, null,
                new Response.Listener<JSONObject>() {
                    @Override
                    public void onResponse(JSONObject respuesta) {
                        producto = new Producto(respuesta);
                        pintarProducto();
                    }
                },
                new Response.ErrorListener() {
                    @Override
                    public void onErrorResponse(VolleyError error) {
                        pbFicha.setVisibility(View.GONE);
                        tvError.setText(getString(R.string.ficha_error) + "\n" + ApiClient.mensajeDeError(error));
                        tvError.setVisibility(View.VISIBLE);
                    }
                });
        peticion.setTag(this);
        ApiClient.getInstance(this).getCola().add(peticion);
    }

    private void pintarProducto() {
        pbFicha.setVisibility(View.GONE);
        llDatos.setVisibility(View.VISIBLE);
        llPie.setVisibility(View.VISIBLE);

        //LA FOTO SE VE ENTERA, SIN RECORTAR. LAS CONSOLAS Y MOVILES VAN SOBRE BLANCO COMO SUS FOTOS
        if (!producto.esVideojuego()) {
            int margen = getResources().getDimensionPixelSize(R.dimen.tienda_margen_foto);
            ivFoto.setPadding(margen, margen, margen, margen);
            ivFoto.setBackgroundColor(ContextCompat.getColor(this, R.color.color_hoja));
        }
        //SI NO HAY FOTO SE QUEDA LA PROVISIONAL
        Glide.with(this).load(producto.getImagenUrl())
                .placeholder(R.drawable.placeholder_producto)
                .error(R.drawable.placeholder_producto)
                .into(ivFoto);

        tvNombre.setText(producto.getNombre());
        tvDescripcion.setText(producto.getDescripcion());
        tvDescripcion.setVisibility(producto.getDescripcion().isEmpty() ? View.GONE : View.VISIBLE);

        if (producto.esVideojuego()) {
            tvPlataforma.setText(producto.getPlataforma());
            tvPlataforma.setVisibility(View.VISIBLE);
            tvEtiqueta1.setText(producto.getGenero());
            tvEtiqueta2.setText(getString(R.string.ficha_pegi, producto.getPegi()));
        } else {
            tvEtiqueta1.setText(producto.getEmpresa());
            tvEtiqueta2.setVisibility(View.GONE);
        }

        TabLayout.Tab tabComprar = tlModo.getTabAt(0);
        if (tabComprar != null) {
            tabComprar.setText(getString(R.string.ficha_comprar_precio, EUROS.format(producto.getPrecioVenta())));
        }
        TabLayout.Tab tabElegida = tlModo.getTabAt(alquilando ? 1 : 0);
        if (tabElegida != null) {
            tabElegida.select();
        }
        pintarModo();
    }

    //EL PIE Y LOS DIAS CAMBIAN SEGUN SI COMPRAMOS O ALQUILAMOS
    private void pintarModo() {
        if (producto == null) {
            return;
        }
        llDias.setVisibility(alquilando ? View.VISIBLE : View.GONE);

        for (int i = 0; i < tvDias.length; i++) {
            boolean elegido = DIAS[i] == diasElegidos;
            tvDias[i].setBackgroundTintList(ColorStateList.valueOf(ContextCompat.getColor(this,
                    elegido ? R.color.color_oscuro : R.color.color_hoja)));
            tvDias[i].setTextColor(ContextCompat.getColor(this, elegido ? R.color.color_fondo : R.color.color_texto));
        }

        if (alquilando) {
            tvPrecio.setText(EUROS.format(producto.getPrecioAlquilerDia() * diasElegidos));
            tvPrecioDetalle.setText(getResources().getQuantityString(R.plurals.ficha_dias, diasElegidos, diasElegidos));
            tvPrecioDetalle.setVisibility(View.VISIBLE);
            boolean hayCopias = producto.getCopiasDisponibles() > 0;
            btnFicha.setEnabled(hayCopias);
            btnFicha.setText(hayCopias ? R.string.ficha_alquilar : R.string.ficha_sin_copias);
        } else {
            tvPrecio.setText(EUROS.format(producto.getPrecioVenta()));
            tvPrecioDetalle.setVisibility(View.GONE);
            boolean hayStock = producto.getStock() > 0;
            btnFicha.setEnabled(hayStock);
            btnFicha.setText(hayStock ? R.string.ficha_anadir : R.string.ficha_agotado);
        }
    }

    private void anadirCesta() {
        boolean anadido = Cesta.anadir(producto);
        Toast.makeText(this, anadido ? R.string.ficha_anadido : R.string.ficha_sin_stock, Toast.LENGTH_SHORT).show();
    }

    //EL ALQUILER VA DIRECTO A LA API, NO PASA POR LA CESTA
    private void alquilar() {
        JSONObject cuerpo = new JSONObject();
        try {
            cuerpo.put("dias", diasElegidos);
            cuerpo.put("videojuegos", new JSONArray().put(producto.getId()));
        } catch (JSONException e) {
            return;
        }

        //DESACTIVAMOS EL BOTON PARA QUE NO SE MANDE DOS VECES
        btnFicha.setEnabled(false);

        JsonObjectRequest peticion = new JsonObjectRequest(Request.Method.POST, ApiClient.BASE_URL + "alquileres", cuerpo,
                new Response.Listener<JSONObject>() {
                    @Override
                    public void onResponse(JSONObject respuesta) {
                        Toast.makeText(FichaProductoActivity.this,
                                getResources().getQuantityString(R.plurals.ficha_alquilado, diasElegidos, diasElegidos),
                                Toast.LENGTH_LONG).show();
                        finish();
                    }
                },
                new Response.ErrorListener() {
                    @Override
                    public void onErrorResponse(VolleyError error) {
                        btnFicha.setEnabled(true);
                        Toast.makeText(FichaProductoActivity.this, ApiClient.mensajeDeError(error), Toast.LENGTH_LONG).show();
                    }
                }) {
            //EL TOKEN DE LA SESION VA EN LAS CABECERAS
            @Override
            public Map<String, String> getHeaders() throws AuthFailureError {
                return ApiClient.getInstance(FichaProductoActivity.this).getCabeceras();
            }
        };
        peticion.setTag(this);
        ApiClient.getInstance(this).getCola().add(peticion);
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        ApiClient.getInstance(this).getCola().cancelAll(this);
    }
}
