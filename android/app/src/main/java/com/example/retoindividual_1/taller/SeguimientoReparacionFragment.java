package com.example.retoindividual_1.taller;

import com.example.retoindividual_1.R;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.content.ContextCompat;
import androidx.fragment.app.Fragment;

import com.bumptech.glide.Glide;
import com.example.retoindividual_1.datos.Repositorio;
import com.example.retoindividual_1.utilidades.FormatosReparacion;
import com.google.android.material.dialog.MaterialAlertDialogBuilder;

import org.json.JSONArray;
import org.json.JSONObject;
import androidx.swiperefreshlayout.widget.SwipeRefreshLayout;


// SEGUIMIENTO DE REPARACIÓN (09 del mockup): GET /api/reparaciones/{id}
public class SeguimientoReparacionFragment extends Fragment {

    private Repositorio datos;

    private static final String ARG_ID_REPARACION = "id_reparacion";

    private View svContenido;
    private SwipeRefreshLayout srlSeguimiento;
    private ProgressBar pbCargando;
    private LinearLayout llAviso;
    private TextView tvAvisoTexto;

    private TextView tvCabecera;
    private TextView tvEstado;
    private LinearLayout llBarraPasos;
    private TextView tvAveria;
    private TextView tvPresupuestoEntero;
    private TextView tvPresupuestoDecimales;
    private LinearLayout llPasos;
    private TextView tvTecnicoInicial;
    private TextView tvTecnicoNombre;
    private TextView tvTecnicoDepartamento;
    private View flLlamar;
    private View tvFotosTitulo;
    private LinearLayout llFotos;
    private View tvCancelar;

    public static SeguimientoReparacionFragment crear(int idReparacion) {
        SeguimientoReparacionFragment fragment = new SeguimientoReparacionFragment();
        Bundle args = new Bundle();
        args.putInt(ARG_ID_REPARACION, idReparacion);
        fragment.setArguments(args);
        return fragment;
    }

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        return inflater.inflate(R.layout.fragment_seguimiento_reparacion, container, false);
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        datos = new Repositorio(requireContext(), getViewLifecycleOwner());

        svContenido = view.findViewById(R.id.svSeguimiento);
        srlSeguimiento = view.findViewById(R.id.srlSeguimiento);
        srlSeguimiento.setColorSchemeResources(R.color.color_marca_intenso);
        srlSeguimiento.setOnRefreshListener(() -> cargar(true));
        pbCargando = view.findViewById(R.id.pbSeguimiento);
        llAviso = view.findViewById(R.id.llSeguimientoAviso);
        tvAvisoTexto = view.findViewById(R.id.tvSeguimientoAvisoTexto);
        tvCabecera = view.findViewById(R.id.tvSeguimientoCabecera);
        tvEstado = view.findViewById(R.id.tvSeguimientoEstado);
        llBarraPasos = view.findViewById(R.id.llSeguimientoBarraPasos);
        tvAveria = view.findViewById(R.id.tvSeguimientoAveria);
        tvPresupuestoEntero = view.findViewById(R.id.tvSeguimientoPresupuestoEntero);
        tvPresupuestoDecimales = view.findViewById(R.id.tvSeguimientoPresupuestoDecimales);
        llPasos = view.findViewById(R.id.llSeguimientoPasos);
        tvTecnicoInicial = view.findViewById(R.id.tvSeguimientoTecnicoInicial);
        tvTecnicoNombre = view.findViewById(R.id.tvSeguimientoTecnicoNombre);
        tvTecnicoDepartamento = view.findViewById(R.id.tvSeguimientoTecnicoDepartamento);
        flLlamar = view.findViewById(R.id.flSeguimientoLlamar);
        tvFotosTitulo = view.findViewById(R.id.tvSeguimientoFotosTitulo);
        llFotos = view.findViewById(R.id.llSeguimientoFotos);
        tvCancelar = view.findViewById(R.id.tvSeguimientoCancelar);

        view.findViewById(R.id.ivVolver).setOnClickListener(v -> getParentFragmentManager().popBackStack());
        view.findViewById(R.id.btnSeguimientoReintentar).setOnClickListener(v -> cargar());
        tvCancelar.setOnClickListener(v -> preguntarCancelar());

        cargar();
    }

    private int idReparacion() {
        return requireArguments().getInt(ARG_ID_REPARACION);
    }

    private void cargar() {
        cargar(false);
    }

    //DESLIZANDO YA SE VE LA RUEDA DE ARRIBA, ASI QUE NO SE ESCONDE EL CONTENIDO
    private void cargar(boolean deslizando) {
        if (!deslizando) {
            svContenido.setVisibility(View.GONE);
            llAviso.setVisibility(View.GONE);
            pbCargando.setVisibility(View.VISIBLE);
        }

        datos.reparacion(idReparacion(), new Repositorio.Resultado<JSONObject>() {
            @Override
            public void bien(JSONObject reparacion) {
                srlSeguimiento.setRefreshing(false);
                pbCargando.setVisibility(View.GONE);
                llAviso.setVisibility(View.GONE);
                pintar(reparacion);
                svContenido.setVisibility(View.VISIBLE);
            }

            @Override
            public void mal(String mensaje) {
                srlSeguimiento.setRefreshing(false);
                pbCargando.setVisibility(View.GONE);
                svContenido.setVisibility(View.GONE);
                tvAvisoTexto.setText(mensaje);
                llAviso.setVisibility(View.VISIBLE);
            }
        });
    }
    private void pintar(JSONObject reparacion) {
        String titulo = FormatosReparacion.titulo(requireContext(), reparacion.optString("tipo_dispositivo"),
                reparacion.optString("marca"), reparacion.optString("modelo"));
        tvCabecera.setText(getString(R.string.mis_rep_titulo, reparacion.optString("numero"), titulo));
        tvEstado.setText(reparacion.optString("estado_texto"));
        pintarBarraPasos(reparacion.optInt("paso"), reparacion.optInt("total_pasos", 5));

        tvAveria.setText(reparacion.optString("descripcion_averia"));
        pintarPresupuesto(reparacion.isNull("presupuesto") ? null : reparacion.optDouble("presupuesto"));
        pintarPasos(reparacion.optJSONArray("pasos"));
        pintarTecnico(reparacion.optJSONObject("trabajador"));
        pintarFotos(reparacion.optJSONArray("fotos"));

        tvCancelar.setVisibility(reparacion.optBoolean("se_puede_cancelar") ? View.VISIBLE : View.GONE);
    }

    private void pintarBarraPasos(int paso, int total) {
        llBarraPasos.removeAllViews();
        int margen = dp(3);
        for (int i = 1; i <= total; i++) {
            View segmento = new View(requireContext());
            LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.MATCH_PARENT, 1);
            lp.setMargins(margen, 0, margen, 0);
            segmento.setLayoutParams(lp);
            segmento.setBackgroundResource(R.drawable.bg_segmento_hero);
            segmento.setAlpha(i <= paso ? 1f : 0.25f);
            llBarraPasos.addView(segmento);
        }
    }

    private void pintarPresupuesto(Double presupuesto) {
        if (presupuesto == null) {
            tvPresupuestoEntero.setText(R.string.mis_rep_presupuesto_pendiente);
            tvPresupuestoEntero.setTextSize(20);
            tvPresupuestoDecimales.setVisibility(View.GONE);
            return;
        }
        String texto = FormatosReparacion.precio(presupuesto);
        int coma = texto.indexOf(',');
        tvPresupuestoEntero.setText(texto.substring(0, coma));
        tvPresupuestoEntero.setTextSize(36);
        tvPresupuestoDecimales.setText(texto.substring(coma));
        tvPresupuestoDecimales.setVisibility(View.VISIBLE);
    }

    private void pintarPasos(JSONArray pasos) {
        llPasos.removeAllViews();
        if (pasos == null) {
            return;
        }
        LayoutInflater inflater = LayoutInflater.from(requireContext());
        int colorHecho = ContextCompat.getColor(requireContext(), R.color.color_marca_texto);
        int colorPendiente = ContextCompat.getColor(requireContext(), R.color.color_borde_fuerte);

        for (int i = 0; i < pasos.length(); i++) {
            JSONObject paso = pasos.optJSONObject(i);
            boolean hecho = paso.optBoolean("hecho");
            boolean actual = paso.optBoolean("actual");
            boolean primero = i == 0;
            boolean ultimo = i == pasos.length() - 1;

            View fila = inflater.inflate(R.layout.item_paso_seguimiento, llPasos, false);

            // La línea que llega al punto es oscura si este paso está hecho;
            // la que sale de él, solo si además no es el actual
            View lineaArriba = fila.findViewById(R.id.vPasoLineaArriba);
            View lineaAbajo = fila.findViewById(R.id.vPasoLineaAbajo);
            lineaArriba.setVisibility(primero ? View.INVISIBLE : View.VISIBLE);
            lineaAbajo.setVisibility(ultimo ? View.INVISIBLE : View.VISIBLE);
            lineaArriba.setBackgroundColor(hecho ? colorHecho : colorPendiente);
            lineaAbajo.setBackgroundColor(hecho && !actual ? colorHecho : colorPendiente);

            fila.findViewById(R.id.vPasoPunto).setBackgroundResource(actual ? R.drawable.bg_punto_actual
                    : hecho ? R.drawable.bg_punto_hecho : R.drawable.bg_punto_pendiente);

            TextView tvNombre = fila.findViewById(R.id.tvPasoNombre);
            tvNombre.setText(paso.optString("texto"));
            tvNombre.setTextColor(ContextCompat.getColor(requireContext(),
                    hecho ? R.color.color_texto : R.color.color_texto_tenue));
            tvNombre.setTextSize(actual ? 17 : 16);

            TextView tvFecha = fila.findViewById(R.id.tvPasoFecha);
            tvFecha.setText(paso.isNull("fecha") ? "" : paso.optString("fecha"));

            TextView tvDescripcion = fila.findViewById(R.id.tvPasoDescripcion);
            boolean conDescripcion = actual && !paso.isNull("descripcion");
            tvDescripcion.setVisibility(conDescripcion ? View.VISIBLE : View.GONE);
            if (conDescripcion) {
                tvDescripcion.setText(paso.optString("descripcion"));
            }

            llPasos.addView(fila);
        }
    }

    private void pintarTecnico(JSONObject trabajador) {
        if (trabajador == null) {
            tvTecnicoInicial.setText("?");
            tvTecnicoNombre.setText(R.string.seg_sin_tecnico);
            tvTecnicoDepartamento.setText(R.string.seg_sin_tecnico_texto);
            flLlamar.setVisibility(View.GONE);
            return;
        }
        String nombre = trabajador.optString("nombre_completo");
        tvTecnicoInicial.setText(nombre.isEmpty() ? "?" : nombre.substring(0, 1));
        tvTecnicoNombre.setText(nombre);
        tvTecnicoDepartamento.setText(trabajador.optString("departamento"));

        String telefono = trabajador.isNull("telefono") ? "" : trabajador.optString("telefono");
        flLlamar.setVisibility(telefono.isEmpty() ? View.GONE : View.VISIBLE);
        // ACTION_DIAL abre el teclado del teléfono con el número: no necesita el permiso CALL_PHONE
        flLlamar.setOnClickListener(v ->
                startActivity(new Intent(Intent.ACTION_DIAL, Uri.parse("tel:" + telefono))));
    }

    private void pintarFotos(JSONArray fotos) {
        llFotos.removeAllViews();
        boolean hayFotos = fotos != null && fotos.length() > 0;
        tvFotosTitulo.setVisibility(hayFotos ? View.VISIBLE : View.GONE);
        if (!hayFotos) {
            return;
        }

        LinearLayout filaActual = null;
        for (int i = 0; i < fotos.length(); i++) {
            if (i % 2 == 0) {
                filaActual = new LinearLayout(requireContext());
                filaActual.setOrientation(LinearLayout.HORIZONTAL);
                LinearLayout.LayoutParams lpFila = new LinearLayout.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT, ViewGroup.LayoutParams.WRAP_CONTENT);
                lpFila.bottomMargin = dp(12);
                filaActual.setLayoutParams(lpFila);
                llFotos.addView(filaActual);
            }
            JSONObject foto = fotos.optJSONObject(i);
            String url = foto.isNull("miniatura_url") ? foto.optString("url") : foto.optString("miniatura_url");

            ImageView imagen = new ImageView(requireContext());
            LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(0, dp(140), 1);
            lp.setMarginEnd(i % 2 == 0 ? dp(6) : 0);
            lp.setMarginStart(i % 2 == 0 ? 0 : dp(6));
            imagen.setLayoutParams(lp);
            imagen.setScaleType(ImageView.ScaleType.CENTER_CROP);
            imagen.setBackgroundResource(R.drawable.bg_miniatura);
            imagen.setClipToOutline(true);
            imagen.setContentDescription(getString(R.string.foto_reparacion));
            Glide.with(this).load(url).into(imagen);
            filaActual.addView(imagen);
        }

        // Con un número impar de fotos, un hueco vacío para que la última no ocupe toda la fila
        if (fotos.length() % 2 == 1) {
            View hueco = new View(requireContext());
            LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(0, dp(140), 1);
            lp.setMarginStart(dp(6));
            hueco.setLayoutParams(lp);
            filaActual.addView(hueco);
        }
    }

    private void preguntarCancelar() {
        new MaterialAlertDialogBuilder(requireContext())
                .setTitle(R.string.seg_cancelar_titulo)
                .setMessage(R.string.seg_cancelar_texto)
                .setPositiveButton(R.string.seg_cancelar_si, (dialogo, boton) -> cancelar())
                .setNegativeButton(R.string.seg_cancelar_no, null)
                .show();
    }

    private void cancelar() {
        tvCancelar.setEnabled(false);
        datos.cancelarReparacion(idReparacion(), new Repositorio.Resultado<JSONObject>() {
            @Override
            public void bien(JSONObject respuesta) {
                Toast.makeText(requireContext(), R.string.seg_cancelada, Toast.LENGTH_SHORT).show();
                tvCancelar.setEnabled(true);
                cargar();
            }

            @Override
            public void mal(String mensaje) {
                tvCancelar.setEnabled(true);
                Toast.makeText(requireContext(), mensaje, Toast.LENGTH_LONG).show();
            }
        });
    }

    private int dp(int valor) {
        return Math.round(valor * getResources().getDisplayMetrics().density);
    }
}