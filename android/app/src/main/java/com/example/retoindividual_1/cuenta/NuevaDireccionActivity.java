package com.example.retoindividual_1.cuenta;

import com.example.retoindividual_1.R;
import com.example.retoindividual_1.principal.PaginaMenuActivity;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.view.View;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;

import com.example.retoindividual_1.modelos.Domicilio;
import com.example.retoindividual_1.datos.Repositorio;
import com.example.retoindividual_1.utilidades.ErroresApi;
import com.google.android.material.button.MaterialButton;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.LinkedHashMap;
import java.util.Map;

// NUEVA DIRECCIÓN (20 del mockup). Sin domicilio: POST /api/domicilios. Con domicilio: PUT /api/domicilios/{id}
public class NuevaDireccionActivity extends PaginaMenuActivity {

    private Repositorio datos;

    public static final String EXTRA_DOMICILIO = "domicilio";

    private final Map<String, EditText> campos = new LinkedHashMap<>();
    private TextView tvError;
    private MaterialButton btnGuardar;

    private int idDomicilio = -1;
    private JSONObject direccionOriginal;

    public static Intent crearIntent(Context context, Domicilio domicilioAEditar) {
        Intent intent = new Intent(context, NuevaDireccionActivity.class);
        if (domicilioAEditar != null) {
            intent.putExtra(EXTRA_DOMICILIO, domicilioAEditar.getJson());
        }
        return intent;
    }

    @Override
    protected int getLayout() {
        return R.layout.activity_nueva_direccion;
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        // Mismo orden que en pantalla: así el primer error marcado es el de más arriba
        campos.put("calle", findViewById(R.id.etDireccionCalle));
        campos.put("numero", findViewById(R.id.etDireccionNumero));
        campos.put("piso", findViewById(R.id.etDireccionPiso));
        campos.put("codigo_postal", findViewById(R.id.etDireccionCp));
        campos.put("ciudad", findViewById(R.id.etDireccionCiudad));
        campos.put("provincia", findViewById(R.id.etDireccionProvincia));
        tvError = findViewById(R.id.tvDireccionError);
        btnGuardar = findViewById(R.id.btnGuardarDireccion);

        String json = getIntent().getStringExtra(EXTRA_DOMICILIO);
        if (json != null) {
            try {
                JSONObject domicilio = new JSONObject(json);
                idDomicilio = domicilio.optInt("id", -1);
                direccionOriginal = domicilio.optJSONObject("direccion");
            } catch (JSONException e) {
                direccionOriginal = null;
            }
        }

        if (direccionOriginal != null) {
            ((TextView) findViewById(R.id.tvNuevaDireccionTitulo)).setText(R.string.dir_editar);
            // Al girar el móvil los EditText ya conservan lo escrito: solo se rellenan la primera vez
            if (savedInstanceState == null) {
                for (Map.Entry<String, EditText> campo : campos.entrySet()) {
                    campo.getValue().setText(valorOriginal(campo.getKey()));
                }
            }
        }

        btnGuardar.setOnClickListener(v -> guardar());
    }

    private boolean esEdicion() {
        return direccionOriginal != null && idDomicilio != -1;
    }

    private String valorOriginal(String clave) {
        return direccionOriginal == null || direccionOriginal.isNull(clave) ? "" : direccionOriginal.optString(clave);
    }

    private String texto(String clave) {
        return campos.get(clave).getText().toString().trim();
    }

    private void guardar() {
        for (EditText campo : campos.values()) {
            campo.setError(null);
        }
        tvError.setVisibility(View.GONE);

        for (Map.Entry<String, EditText> campo : campos.entrySet()) {
            boolean obligatorio = !campo.getKey().equals("piso");
            if (obligatorio && texto(campo.getKey()).isEmpty()) {
                marcarError(campo.getValue(), getString(R.string.editar_obligatorio));
                return;
            }
        }
        if (!texto("codigo_postal").matches("\\d{5}")) {
            marcarError(campos.get("codigo_postal"), getString(R.string.dir_error_cp));
            return;
        }

        JSONObject cuerpo = new JSONObject();
        try {
            for (String clave : campos.keySet()) {
                String valor = texto(clave);
                // Al editar solo se envía lo que cambia (lo pide la API). Un piso vacío se envía como null
                if (!esEdicion() || !valor.equals(valorOriginal(clave))) {
                    cuerpo.put(clave, valor.isEmpty() ? JSONObject.NULL : valor);
                }
            }
        } catch (JSONException e) {
            return;
        }

        if (esEdicion() && cuerpo.length() == 0) {
            Toast.makeText(this, R.string.editar_sin_cambios, Toast.LENGTH_SHORT).show();
            return;
        }

        enviar(cuerpo);
    }

    private void enviar(JSONObject cuerpo) {
        bloquear(true);
        Repositorio.Resultado<JSONObject> alGuardar = new Repositorio.Resultado<JSONObject>() {
            @Override
            public void bien(JSONObject respuesta) {
                Toast.makeText(NuevaDireccionActivity.this, R.string.dir_guardada, Toast.LENGTH_SHORT).show();
                finish();
            }

            @Override
            public void mal(String mensaje) {
                bloquear(false);
                tvError.setText(mensaje);
                tvError.setVisibility(View.VISIBLE);
            }

            @Override
            public void campos(JSONObject errores) {
                EditText primero = ErroresApi.marcarCampos(errores, campos);
                if (primero != null) {
                    primero.requestFocus();
                }
            }
        };
        if (esEdicion()) {
            datos().editarDomicilio(idDomicilio, cuerpo, alGuardar);
        } else {
            datos().crearDomicilio(cuerpo, alGuardar);
        }
    }

    private void marcarError(EditText campo, String mensaje) {
        campo.setError(mensaje);
        campo.requestFocus();
    }

    private void bloquear(boolean guardando) {
        btnGuardar.setEnabled(!guardando);
        btnGuardar.setText(guardando ? R.string.dir_guardando : R.string.dir_guardar);
    }

    //CAPA DE DATOS, SE CREA LA PRIMERA VEZ QUE SE USA
    private Repositorio datos() {
        if (datos == null) {
            datos = new Repositorio(this, this);
        }
        return datos;
    }
}
