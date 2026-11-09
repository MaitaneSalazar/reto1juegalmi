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

import com.android.volley.Request;
import com.android.volley.Response;
import com.android.volley.VolleyError;
import com.android.volley.toolbox.JsonObjectRequest;
import com.bumptech.glide.Glide;
import com.example.retoindividual_1.modelos.Cesta;
import com.example.retoindividual_1.modelos.Plataforma;
import com.example.retoindividual_1.modelos.Producto;
import com.example.retoindividual_1.network.ApiClient;
import com.example.retoindividual_1.utilidades.Animaciones;
import com.google.android.material.tabs.TabLayout;

import org.json.JSONObject;

import java.text.NumberFormat;
import java.util.Locale;

//FICHA DE UN PRODUCTO, SE PIDE A LA API POR SU ID
public class FichaProductoActivity extends PaginaMenuActivity {

    public static final String EXTRA_ID_PRODUCTO = "id_producto";
    public static final String EXTRA_SE_ALQUILA = "se_alquila";
    public static final String EXTRA_EMPEZAR_ALQUILANDO = "empezar_alquilando";

    private static final NumberFormat EUROS = NumberFormat.getCurrencyInstance(Locale.forLanguageTag("es-ES"));
    private static final int[] DIAS = {1, 3, 5, 7};

    private ImageView ivFoto;
    private LinearLayout llEtiquetas;
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
    private TextView tvCantidad;

    private Producto producto;
    private boolean alquilando;
    private int diasElegidos = 3;
    private int cantidad = 1;

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
        llEtiquetas = findViewById(R.id.llFichaEtiquetas);
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
        tvCantidad = findViewById(R.id.tvFichaCantidad);

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

        //MENOS Y MAS, NUNCA BAJA DE 1 NI PASA DE LO QUE QUEDA
        findViewById(R.id.ivFichaMenos).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (cantidad > 1) {
                    cantidad--;
                    pintarModo();
                }
            }
        });
        findViewById(R.id.ivFichaMas).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                if (producto == null) {
                    return;
                }
                if (cantidad < quedan()) {
                    cantidad++;
                    pintarModo();
                } else {
                    Toast.makeText(FichaProductoActivity.this, R.string.ficha_sin_stock, Toast.LENGTH_SHORT).show();
                }
            }
        });

        //COMPRANDO O ALQUILANDO, TODO VA A LA CESTA
        btnFicha.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                anadirCesta();
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
        //LOS DATOS Y EL PIE ENTRAN SUBIENDO CUANDO LLEGA EL PRODUCTO
        Animaciones.aparecer(llDatos);
        Animaciones.aparecer(llPie);

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
            //LAS PLATAFORMAS VAN DELANTE DEL RESTO DE ETIQUETAS, CADA UNA CON SU COLOR
            for (int i = 0; i < producto.getPlataformas().size(); i++) {
                llEtiquetas.addView(Plataforma.crearEtiqueta(this, producto.getPlataformas().get(i), false), i);
            }
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

        //AL CAMBIAR DE MODO PUEDE QUE QUEDEN MENOS, LA CANTIDAD SE AJUSTA
        int quedan = quedan();
        cantidad = Math.max(1, Math.min(cantidad, quedan));
        tvCantidad.setText(String.valueOf(cantidad));

        double unidad = alquilando ? producto.getPrecioAlquilerDia() * diasElegidos : producto.getPrecioVenta();
        tvPrecio.setText(EUROS.format(unidad * cantidad));
        String detalle = alquilando ? getResources().getQuantityString(R.plurals.ficha_dias, diasElegidos, diasElegidos) : "";
        if (cantidad > 1) {
            detalle = getString(R.string.ficha_por_unidades, cantidad, EUROS.format(unidad)) + (detalle.isEmpty() ? "" : " · " + detalle);
        }
        tvPrecioDetalle.setText(detalle);
        tvPrecioDetalle.setVisibility(detalle.isEmpty() ? View.GONE : View.VISIBLE);

        btnFicha.setEnabled(quedan > 0);
        if (quedan > 0) {
            btnFicha.setText(R.string.ficha_anadir);
        } else if (Cesta.Linea.limite(producto, alquilando) > 0) {
            btnFicha.setText(R.string.ficha_todo_en_cesta);
        } else {
            btnFicha.setText(alquilando ? R.string.ficha_sin_copias : R.string.ficha_agotado);
        }
    }

    //LAS QUE SE PUEDEN AÑADIR TODAVIA: EL STOCK (O LAS COPIAS) MENOS LAS QUE YA ESTAN EN LA CESTA
    private int quedan() {
        return Cesta.Linea.limite(producto, alquilando) - Cesta.enCesta(producto, alquilando);
    }

    private void anadirCesta() {
        boolean anadido = Cesta.anadir(producto, cantidad, alquilando, diasElegidos);
        Toast.makeText(this, anadido ? R.string.ficha_anadido : R.string.ficha_sin_stock, Toast.LENGTH_SHORT).show();
        if (anadido) {
            Animaciones.latido(btnFicha);
        }
        cantidad = 1;
        pintarModo();
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        ApiClient.getInstance(this).getCola().cancelAll(this);
    }
}
