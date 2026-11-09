package com.example.retoindividual_1.cuenta;

import com.example.retoindividual_1.R;
import com.example.retoindividual_1.principal.PaginaMenuActivity;
import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.TextView;

import com.bumptech.glide.Glide;
import com.example.retoindividual_1.datos.Repositorio;
import com.example.retoindividual_1.utilidades.FormatosReparacion;

import org.json.JSONObject;


// DATOS PERSONALES (17 del mockup): GET /api/yo
public class DatosPersonalesActivity extends PaginaMenuActivity {

    private Repositorio datos;

    private View svDatos;
    private ProgressBar pbCargando;
    private LinearLayout llAviso;
    private TextView tvAvisoTexto;
    private TextView tvIniciales;
    private ImageView ivFoto;
    private TextView tvNombre;
    private TextView tvClienteDesde;
    private TextView tvNombreCompleto;
    private TextView tvDni;
    private TextView tvEmail;
    private TextView tvTelefono;

    @Override
    protected int getLayout() {
        return R.layout.activity_datos_personales;
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        svDatos = findViewById(R.id.svDatos);
        pbCargando = findViewById(R.id.pbDatos);
        llAviso = findViewById(R.id.llDatosAviso);
        tvAvisoTexto = findViewById(R.id.tvDatosAvisoTexto);
        tvIniciales = findViewById(R.id.tvDatosIniciales);
        ivFoto = findViewById(R.id.ivDatosFoto);
        tvNombre = findViewById(R.id.tvDatosNombre);
        tvClienteDesde = findViewById(R.id.tvDatosClienteDesde);
        tvNombreCompleto = findViewById(R.id.tvDatosNombreCompleto);
        tvDni = findViewById(R.id.tvDatosDni);
        tvEmail = findViewById(R.id.tvDatosEmail);
        tvTelefono = findViewById(R.id.tvDatosTelefono);

        ivFoto.setClipToOutline(true);

        findViewById(R.id.btnEditarDatos).setOnClickListener(v ->
                startActivity(new Intent(this, EditarDatosActivity.class)));
        findViewById(R.id.btnDatosReintentar).setOnClickListener(v -> cargar());
    }

    // En onResume y no en onCreate: así, al volver de "Editar datos", se ven los cambios
    @Override
    protected void onResume() {
        super.onResume();
        cargar();
    }

    private void cargar() {
        svDatos.setVisibility(View.GONE);
        llAviso.setVisibility(View.GONE);
        pbCargando.setVisibility(View.VISIBLE);

        datos().usuario(new Repositorio.Resultado<JSONObject>() {
            @Override
            public void bien(JSONObject usuario) {
                pbCargando.setVisibility(View.GONE);
                pintar(usuario);
                svDatos.setVisibility(View.VISIBLE);
            }

            @Override
            public void mal(String mensaje) {
                pbCargando.setVisibility(View.GONE);
                tvAvisoTexto.setText(mensaje);
                llAviso.setVisibility(View.VISIBLE);
            }
        });
    }

    private void pintar(JSONObject usuario) {
        tvIniciales.setText(usuario.optString("iniciales"));
        // foto_perfil es solo la ruta: la dirección completa viene en los campos *_url
        String foto = !usuario.isNull("foto_perfil_miniatura_url") ? usuario.optString("foto_perfil_miniatura_url")
                : !usuario.isNull("foto_perfil_url") ? usuario.optString("foto_perfil_url")
                : null;
        ivFoto.setVisibility(foto == null ? View.GONE : View.VISIBLE);
        if (foto != null) {
            Glide.with(this).load(foto).into(ivFoto);
        }

        tvNombre.setText(usuario.optString("nombre_completo"));

        String registro = usuario.isNull("fecha_registro") ? "" : usuario.optString("fecha_registro");
        tvClienteDesde.setVisibility(registro.length() < 10 ? View.GONE : View.VISIBLE);
        if (registro.length() >= 10) {
            String fecha = FormatosReparacion.fechaCorta(registro) + " de " + registro.substring(0, 4);
            tvClienteDesde.setText(getString(R.string.datos_cliente_desde, fecha));
        }

        String nombreCompleto = usuario.optString("nombre") + " " + usuario.optString("apellido1");
        if (!usuario.isNull("apellido2")) {
            nombreCompleto += " " + usuario.optString("apellido2");
        }
        tvNombreCompleto.setText(nombreCompleto.trim());
        tvDni.setText(usuario.optString("dni"));
        tvEmail.setText(usuario.optString("email"));
        tvTelefono.setText(usuario.isNull("telefono") || usuario.optString("telefono").isEmpty()
                ? getString(R.string.datos_sin_telefono) : usuario.optString("telefono"));
    }

    //CAPA DE DATOS, SE CREA LA PRIMERA VEZ QUE SE USA
    private Repositorio datos() {
        if (datos == null) {
            datos = new Repositorio(this, this);
        }
        return datos;
    }
}
