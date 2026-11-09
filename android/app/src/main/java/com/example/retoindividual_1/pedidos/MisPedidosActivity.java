package com.example.retoindividual_1.pedidos;

import com.example.retoindividual_1.R;
import com.example.retoindividual_1.principal.PaginaMenuActivity;
import android.content.DialogInterface;
import android.content.res.ColorStateList;
import android.os.Bundle;
import android.view.View;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;

import androidx.core.content.ContextCompat;
import androidx.recyclerview.widget.LinearLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.example.retoindividual_1.adaptadores.PedidoAdapter;
import com.example.retoindividual_1.datos.Repositorio;
import com.example.retoindividual_1.modelos.Pedido;
import com.example.retoindividual_1.utilidades.FormatosReparacion;
import com.google.android.material.dialog.MaterialAlertDialogBuilder;

import org.json.JSONObject;

import java.util.Arrays;
import java.util.List;

//MIS PEDIDOS (15 DEL MOCKUP): GET /pedidos, GET /pedidos/{id} PARA LAS FOTOS Y PUT /pedidos/{id}/cancelar
public class MisPedidosActivity extends PaginaMenuActivity {

    //LOS ESTADOS DE LA API EN ORDEN, IGUAL QUE ped_pasos
    private static final List<String> ESTADOS = Arrays.asList("pendiente", "pagado", "enviado", "entregado");

    private ProgressBar pbPedidos;
    private LinearLayout llAviso;
    private TextView tvAvisoTitulo;
    private TextView tvAvisoTexto;
    private Button btnReintentar;
    private LinearLayout llUltimo;
    private TextView tvUltimoNumero;
    private TextView tvUltimoFecha;
    private LinearLayout llUltimoPasos;
    private TextView tvUltimoCancelado;
    private LinearLayout llUltimoFotos;
    private TextView tvUltimoNombre;
    private TextView tvUltimoTotal;
    private Button btnUltimoCancelar;
    private TextView tvAnteriores;
    private RecyclerView rvAnteriores;
    private PedidoAdapter adaptador;

    @Override
    protected int getLayout() {
        return R.layout.activity_mis_pedidos;
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        pbPedidos = findViewById(R.id.pbPedidos);
        llAviso = findViewById(R.id.llPedidosAviso);
        tvAvisoTitulo = findViewById(R.id.tvPedidosAvisoTitulo);
        tvAvisoTexto = findViewById(R.id.tvPedidosAvisoTexto);
        btnReintentar = findViewById(R.id.btnPedidosReintentar);
        llUltimo = findViewById(R.id.llUltimo);
        tvUltimoNumero = findViewById(R.id.tvUltimoNumero);
        tvUltimoFecha = findViewById(R.id.tvUltimoFecha);
        llUltimoPasos = findViewById(R.id.llUltimoPasos);
        tvUltimoCancelado = findViewById(R.id.tvUltimoCancelado);
        llUltimoFotos = findViewById(R.id.llUltimoFotos);
        tvUltimoNombre = findViewById(R.id.tvUltimoNombre);
        tvUltimoTotal = findViewById(R.id.tvUltimoTotal);
        btnUltimoCancelar = findViewById(R.id.btnUltimoCancelar);
        tvAnteriores = findViewById(R.id.tvPedidosAnteriores);
        rvAnteriores = findViewById(R.id.rvPedidosAnteriores);

        rvAnteriores.setLayoutManager(new LinearLayoutManager(this));

        btnReintentar.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                cargarPedidos();
            }
        });

        cargarPedidos();
    }

    //LA CREAMOS AL ENTRAR, ANTES DE PEDIR NADA
    private Repositorio datos;

    private Repositorio datos() {
        if (datos == null) {
            datos = new Repositorio(this, this);
        }
        return datos;
    }

    //shortcut: SOLO LOS 50 ULTIMOS, SI ALGUIEN TIENE MAS HABRIA QUE PAGINAR
    private void cargarPedidos() {
        llAviso.setVisibility(View.GONE);
        pbPedidos.setVisibility(View.VISIBLE);

        datos().pedidos(50, new Repositorio.Resultado<List<Pedido>>() {
            @Override
            public void bien(List<Pedido> pedidos) {
                pbPedidos.setVisibility(View.GONE);
                pintarPedidos(pedidos);
            }

            @Override
            public void mal(String mensaje) {
                pbPedidos.setVisibility(View.GONE);
                mostrarAviso(getString(R.string.ped_error_titulo), mensaje, true);
            }
        });
    }

    //LA API LOS MANDA DEL MAS RECIENTE AL MAS ANTIGUO: EL PRIMERO VA EN GRANDE
    private void pintarPedidos(List<Pedido> pedidos) {
        if (pedidos.isEmpty()) {
            llUltimo.setVisibility(View.GONE);
            tvAnteriores.setVisibility(View.GONE);
            rvAnteriores.setAdapter(null);
            mostrarAviso(getString(R.string.ped_vacio_titulo), getString(R.string.ped_vacio_texto), false);
            return;
        }
        pintarUltimo(pedidos.get(0));

        List<Pedido> anteriores = pedidos.subList(1, pedidos.size());
        adaptador = new PedidoAdapter(anteriores, new PedidoAdapter.AlCancelar() {
            @Override
            public void cancelar(Pedido pedido) {
                preguntarCancelar(pedido);
            }
        });
        rvAnteriores.setAdapter(adaptador);
        rvAnteriores.scheduleLayoutAnimation();
        tvAnteriores.setVisibility(anteriores.isEmpty() ? View.GONE : View.VISIBLE);

        for (int i = 0; i < pedidos.size(); i++) {
            cargarFotos(pedidos.get(i), i);
        }
    }

    //EL LISTADO SOLO TRAE LA FOTO DEL PRIMER PRODUCTO, LAS DEMAS SALEN DEL DETALLE DE CADA PEDIDO
    private void cargarFotos(Pedido pedido, int posicion) {
        datos().fotosPedido(pedido, new Repositorio.Resultado<Pedido>() {
            @Override
            public void bien(Pedido conFotos) {
                if (posicion == 0) {
                    PedidoAdapter.pintarFotos(llUltimoFotos, conFotos);
                } else {
                    adaptador.notifyItemChanged(posicion - 1);
                }
            }

            @Override
            public void mal(String mensaje) {
                //SI FALLA SE QUEDA LA FOTO DEL PRIMER PRODUCTO
            }
        });
    }

    private void pintarUltimo(Pedido pedido) {
        tvUltimoNumero.setText(getString(R.string.ped_numero, pedido.getId()));
        tvUltimoFecha.setText(FormatosReparacion.fechaCorta(pedido.getFecha()));
        tvUltimoNombre.setText(PedidoAdapter.nombre(this, pedido));
        tvUltimoTotal.setText(FormatosReparacion.precio(pedido.getTotal()));
        PedidoAdapter.pintarFotos(llUltimoFotos, pedido);

        //CREAMOS LOS 4 PASOS, LOS HECHOS EN COLOR DE LA MARCA Y EL ACTUAL EN NEGRITA
        boolean cancelado = pedido.getEstado().equals("cancelado");
        int actual = ESTADOS.indexOf(pedido.getEstado());
        String[] pasos = getResources().getStringArray(R.array.ped_pasos);
        llUltimoPasos.removeAllViews();
        for (int i = 0; i < pasos.length; i++) {
            View paso = getLayoutInflater().inflate(R.layout.item_paso_pedido, llUltimoPasos, false);
            TextView tvPaso = paso.findViewById(R.id.tvPaso);
            tvPaso.setText(pasos[i]);
            tvPaso.setTextColor(ContextCompat.getColor(this, i == actual ? R.color.color_texto : R.color.color_texto_tenue));
            tvPaso.setTypeface(null, i == actual ? android.graphics.Typeface.BOLD : android.graphics.Typeface.NORMAL);
            paso.findViewById(R.id.vPaso).setBackgroundTintList(ColorStateList.valueOf(
                    ContextCompat.getColor(this, i <= actual ? R.color.color_marca : R.color.color_pozo)));
            llUltimoPasos.addView(paso);
        }
        llUltimoPasos.setVisibility(cancelado ? View.GONE : View.VISIBLE);
        tvUltimoCancelado.setVisibility(cancelado ? View.VISIBLE : View.GONE);

        btnUltimoCancelar.setVisibility(pedido.isSePuedeCancelar() ? View.VISIBLE : View.GONE);
        btnUltimoCancelar.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                preguntarCancelar(pedido);
            }
        });
        llUltimo.setVisibility(View.VISIBLE);
    }

    //SIN PEDIDOS O SIN CONEXION. SOLO SALE REINTENTAR SI HA FALLADO LA CONEXION
    private void mostrarAviso(String titulo, String texto, boolean reintentar) {
        tvAvisoTitulo.setText(titulo);
        tvAvisoTexto.setText(texto);
        btnReintentar.setVisibility(reintentar ? View.VISIBLE : View.GONE);
        llAviso.setVisibility(View.VISIBLE);
    }

    private void preguntarCancelar(Pedido pedido) {
        new MaterialAlertDialogBuilder(this)
                .setTitle(R.string.ped_cancelar_titulo)
                .setMessage(getString(R.string.ped_cancelar_texto, pedido.getId()))
                .setPositiveButton(R.string.ped_cancelar_si, new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface dialogo, int boton) {
                        cancelar(pedido);
                    }
                })
                .setNegativeButton(R.string.ped_volver, null)
                .show();
    }

    private void cancelar(Pedido pedido) {
        datos().cancelarPedido(pedido.getId(), new Repositorio.Resultado<JSONObject>() {
            @Override
            public void bien(JSONObject respuesta) {
                Toast.makeText(MisPedidosActivity.this, R.string.ped_cancelado_ok, Toast.LENGTH_SHORT).show();
                cargarPedidos();
            }

            @Override
            public void mal(String mensaje) {
                Toast.makeText(MisPedidosActivity.this, mensaje, Toast.LENGTH_LONG).show();
            }
        });
    }
}
