package com.example.retoindividual_1;

import android.content.ActivityNotFoundException;
import android.content.Context;
import android.net.Uri;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.View;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;

import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.PickVisualMediaRequest;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.annotation.NonNull;
import androidx.core.content.FileProvider;

import com.android.volley.DefaultRetryPolicy;
import com.android.volley.Request;
import com.android.volley.VolleyError;
import com.android.volley.toolbox.JsonObjectRequest;
import com.bumptech.glide.Glide;
import com.example.retoindividual_1.network.ApiClient;
import com.example.retoindividual_1.network.SubidaFotoRequest;
import com.example.retoindividual_1.utilidades.ProcesadorFotos;
import com.google.android.material.button.MaterialButton;
import com.google.android.material.dialog.MaterialAlertDialogBuilder;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.File;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

// EDITAR DATOS PERSONALES (18 del mockup): GET /api/yo para rellenar y PUT /api/yo para guardar
public class EditarDatosActivity extends PaginaMenuActivity {

    // La guía dice que la foto se cambia en PUT /api/yo con el campo "foto_perfil" (multipart).
    // Confirmarlo con Aketza: si usa otro método o ruta, solo hay que cambiar estas tres líneas
    private static final int METODO_FOTO = Request.Method.PUT;
    private static final String RUTA_FOTO = "yo";
    private static final String CAMPO_FOTO = "foto_perfil";

    private static final int MIN_CONTRASENA = 6;
    private static final String ESTADO_ORIGINAL = "original";
    private static final String ESTADO_FOTO = "foto";
    private static final String ESTADO_URI_CAMARA = "uri_camara";

    private View svEditar;
    private ProgressBar pbCargando;
    private LinearLayout llAviso;
    private TextView tvAvisoTexto;
    private TextView tvIniciales;
    private ImageView ivFoto;
    private EditText etNombre;
    private EditText etApellido1;
    private EditText etApellido2;
    private EditText etTelefono;
    private TextView tvDni;
    private TextView tvEmail;
    private EditText etContrasenaActual;
    private EditText etContrasenaNueva;
    private TextView tvError;
    private MaterialButton btnGuardar;

    private final Map<String, EditText> camposApi = new HashMap<>();

    // Los datos tal como llegaron de la API: sirven para enviar solo lo que ha cambiado
    private JSONObject original;
    private File fotoNueva;
    private Uri uriCamara;

    private final ExecutorService hiloFotos = Executors.newSingleThreadExecutor();
    private final Handler hiloPrincipal = new Handler(Looper.getMainLooper());

    private final ActivityResultLauncher<Uri> lanzadorCamara =
            registerForActivityResult(new ActivityResultContracts.TakePicture(), hecha -> {
                if (Boolean.TRUE.equals(hecha) && uriCamara != null) {
                    procesarFoto(uriCamara, true);
                }
            });

    private final ActivityResultLauncher<PickVisualMediaRequest> lanzadorGaleria =
            registerForActivityResult(new ActivityResultContracts.PickVisualMedia(), uri -> {
                if (uri != null) {
                    procesarFoto(uri, false);
                }
            });

    @Override
    protected int getLayout() {
        return R.layout.activity_editar_datos;
    }

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        svEditar = findViewById(R.id.svEditar);
        pbCargando = findViewById(R.id.pbEditar);
        llAviso = findViewById(R.id.llEditarAviso);
        tvAvisoTexto = findViewById(R.id.tvEditarAvisoTexto);
        tvIniciales = findViewById(R.id.tvEditarIniciales);
        ivFoto = findViewById(R.id.ivEditarFoto);
        etNombre = findViewById(R.id.etEditarNombre);
        etApellido1 = findViewById(R.id.etEditarApellido1);
        etApellido2 = findViewById(R.id.etEditarApellido2);
        etTelefono = findViewById(R.id.etEditarTelefono);
        tvDni = findViewById(R.id.tvEditarDni);
        tvEmail = findViewById(R.id.tvEditarEmail);
        etContrasenaActual = findViewById(R.id.etEditarContrasenaActual);
        etContrasenaNueva = findViewById(R.id.etEditarContrasenaNueva);
        tvError = findViewById(R.id.tvEditarError);
        btnGuardar = findViewById(R.id.btnGuardarDatos);

        camposApi.put("nombre", etNombre);
        camposApi.put("apellido1", etApellido1);
        camposApi.put("apellido2", etApellido2);
        camposApi.put("telefono", etTelefono);
        camposApi.put("password_actual", etContrasenaActual);
        camposApi.put("password_nueva", etContrasenaNueva);

        ivFoto.setClipToOutline(true);
        findViewById(R.id.flEditarFoto).setOnClickListener(v -> elegirOrigenFoto());
        findViewById(R.id.tvEditarCambiarFoto).setOnClickListener(v -> elegirOrigenFoto());
        findViewById(R.id.btnEditarReintentar).setOnClickListener(v -> cargar());
        btnGuardar.setOnClickListener(v -> guardar());

        // Al girar el móvil no se vuelve a pedir a la API: así no se pierde lo que se ha escrito
        if (savedInstanceState != null && savedInstanceState.getString(ESTADO_ORIGINAL) != null) {
            try {
                original = new JSONObject(savedInstanceState.getString(ESTADO_ORIGINAL));
            } catch (JSONException e) {
                original = null;
            }
            String rutaFoto = savedInstanceState.getString(ESTADO_FOTO);
            fotoNueva = rutaFoto == null ? null : new File(rutaFoto);
            uriCamara = savedInstanceState.getParcelable(ESTADO_URI_CAMARA);
        }

        if (original == null) {
            cargar();
        } else {
            pintarNoEditables();
            pintarAvatar();
            svEditar.setVisibility(View.VISIBLE);
        }
    }

    @Override
    protected void onSaveInstanceState(@NonNull Bundle outState) {
        super.onSaveInstanceState(outState);
        outState.putString(ESTADO_ORIGINAL, original == null ? null : original.toString());
        outState.putString(ESTADO_FOTO, fotoNueva == null ? null : fotoNueva.getAbsolutePath());
        outState.putParcelable(ESTADO_URI_CAMARA, uriCamara);
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        ApiClient.getInstance(this).getCola().cancelAll(this);
        hiloFotos.shutdown();
    }

    private void cargar() {
        svEditar.setVisibility(View.GONE);
        llAviso.setVisibility(View.GONE);
        pbCargando.setVisibility(View.VISIBLE);

        ApiClient api = ApiClient.getInstance(this);
        JsonObjectRequest peticion = new JsonObjectRequest(Request.Method.GET, ApiClient.BASE_URL + "yo", null,
                respuesta -> {
                    pbCargando.setVisibility(View.GONE);
                    original = respuesta;
                    rellenarCampos();
                    pintarNoEditables();
                    pintarAvatar();
                    svEditar.setVisibility(View.VISIBLE);
                },
                error -> {
                    pbCargando.setVisibility(View.GONE);
                    tvAvisoTexto.setText(ApiClient.mensajeDeError(error));
                    llAviso.setVisibility(View.VISIBLE);
                }) {
            @Override
            public Map<String, String> getHeaders() {
                return api.getCabeceras();
            }
        };
        peticion.setTag(this);
        api.getCola().add(peticion);
    }

    private String valorOriginal(String campo) {
        return original.isNull(campo) ? "" : original.optString(campo);
    }

    private void rellenarCampos() {
        etNombre.setText(valorOriginal("nombre"));
        etApellido1.setText(valorOriginal("apellido1"));
        etApellido2.setText(valorOriginal("apellido2"));
        etTelefono.setText(valorOriginal("telefono"));
    }

    private void pintarNoEditables() {
        tvDni.setText(valorOriginal("dni"));
        tvEmail.setText(valorOriginal("email"));
    }

    private void pintarAvatar() {
        tvIniciales.setText(valorOriginal("iniciales"));
        String fotoActual = valorOriginal("foto_perfil");
        if (fotoNueva != null) {
            ivFoto.setVisibility(View.VISIBLE);
            Glide.with(this).load(fotoNueva).into(ivFoto);
        } else if (!fotoActual.isEmpty()) {
            ivFoto.setVisibility(View.VISIBLE);
            Glide.with(this).load(fotoActual).into(ivFoto);
        } else {
            ivFoto.setVisibility(View.GONE);
        }
    }

    private String texto(EditText campo) {
        return campo.getText().toString().trim();
    }

    // ============================ FOTO ============================

    private void elegirOrigenFoto() {
        String[] opciones = {getString(R.string.foto_hacer), getString(R.string.foto_galeria)};
        new MaterialAlertDialogBuilder(this)
                .setTitle(R.string.editar_cambiar_foto)
                .setItems(opciones, (dialogo, cual) -> {
                    if (cual == 0) {
                        hacerFoto();
                    } else {
                        lanzadorGaleria.launch(new PickVisualMediaRequest.Builder()
                                .setMediaType(ActivityResultContracts.PickVisualMedia.ImageOnly.INSTANCE)
                                .build());
                    }
                })
                .setNegativeButton(R.string.foto_cancelar, null)
                .show();
    }

    private void hacerFoto() {
        try {
            File carpeta = new File(getCacheDir(), "camara");
            if (!carpeta.exists() && !carpeta.mkdirs()) {
                throw new IOException("No se ha podido crear la carpeta de la cámara");
            }
            File archivo = File.createTempFile("camara_", ".jpg", carpeta);
            uriCamara = FileProvider.getUriForFile(this, getPackageName() + ".fileprovider", archivo);
            lanzadorCamara.launch(uriCamara);
        } catch (IOException | ActivityNotFoundException e) {
            mostrarError(getString(R.string.error_sin_camara));
        }
    }

    private void procesarFoto(Uri origen, boolean esDeCamara) {
        Context contexto = getApplicationContext();
        hiloFotos.execute(() -> {
            File preparada;
            try {
                preparada = ProcesadorFotos.preparar(contexto, origen);
            } catch (IOException e) {
                preparada = null;
            }
            if (esDeCamara) {
                contexto.getContentResolver().delete(origen, null, null);
            }
            File resultado = preparada;
            hiloPrincipal.post(() -> {
                if (isFinishing() || isDestroyed()) {
                    return;
                }
                if (resultado == null) {
                    mostrarError(getString(R.string.error_foto));
                    return;
                }
                if (fotoNueva != null) {
                    fotoNueva.delete();
                }
                fotoNueva = resultado;
                pintarAvatar();
            });
        });
    }

    // ============================ GUARDAR ============================

    private void guardar() {
        if (original == null) {
            return;
        }
        for (EditText campo : camposApi.values()) {
            campo.setError(null);
        }
        tvError.setVisibility(View.GONE);

        if (texto(etNombre).isEmpty()) {
            marcarError(etNombre, getString(R.string.editar_obligatorio));
            return;
        }
        if (texto(etApellido1).isEmpty()) {
            marcarError(etApellido1, getString(R.string.editar_obligatorio));
            return;
        }
        String contrasenaActual = etContrasenaActual.getText().toString();
        String contrasenaNueva = etContrasenaNueva.getText().toString();
        boolean cambiaContrasena = !contrasenaActual.isEmpty() || !contrasenaNueva.isEmpty();
        if (cambiaContrasena && contrasenaActual.isEmpty()) {
            marcarError(etContrasenaActual, getString(R.string.editar_error_contrasena_actual));
            return;
        }
        if (cambiaContrasena && contrasenaNueva.length() < MIN_CONTRASENA) {
            marcarError(etContrasenaNueva, getString(R.string.editar_error_contrasena_corta));
            return;
        }

        JSONObject cambios = new JSONObject();
        try {
            ponerSiCambia(cambios, "nombre", texto(etNombre));
            ponerSiCambia(cambios, "apellido1", texto(etApellido1));
            ponerSiCambia(cambios, "apellido2", texto(etApellido2));
            ponerSiCambia(cambios, "telefono", texto(etTelefono));
            if (cambiaContrasena) {
                cambios.put("password_actual", contrasenaActual);
                cambios.put("password_nueva", contrasenaNueva);
            }
        } catch (JSONException e) {
            return;
        }

        if (cambios.length() == 0 && fotoNueva == null) {
            Toast.makeText(this, R.string.editar_sin_cambios, Toast.LENGTH_SHORT).show();
            return;
        }

        bloquear(true);
        if (cambios.length() == 0) {
            subirFoto();
        } else {
            enviarCambios(cambios);
        }
    }

    // Un campo opcional vacío se envía como null, para que la API lo borre
    private void ponerSiCambia(JSONObject cambios, String campo, String valor) throws JSONException {
        if (!valor.equals(valorOriginal(campo))) {
            cambios.put(campo, valor.isEmpty() ? JSONObject.NULL : valor);
        }
    }

    private void enviarCambios(JSONObject cambios) {
        ApiClient api = ApiClient.getInstance(this);
        JsonObjectRequest peticion = new JsonObjectRequest(Request.Method.PUT, ApiClient.BASE_URL + "yo", cambios,
                respuesta -> {
                    // Si después falla la foto y se vuelve a pulsar Guardar, solo se reenvía la foto
                    original = respuesta;
                    etContrasenaActual.setText("");
                    etContrasenaNueva.setText("");
                    if (fotoNueva == null) {
                        terminar();
                    } else {
                        subirFoto();
                    }
                },
                error -> {
                    bloquear(false);
                    mostrarErroresApi(error);
                }) {
            @Override
            public Map<String, String> getHeaders() {
                return api.getCabeceras();
            }
        };
        // SIN reintentos: con el cambio de contraseña, repetir la petición daría error
        peticion.setRetryPolicy(new DefaultRetryPolicy(15000, 0, DefaultRetryPolicy.DEFAULT_BACKOFF_MULT));
        peticion.setTag(this);
        api.getCola().add(peticion);
    }

    private void subirFoto() {
        ApiClient api = ApiClient.getInstance(this);
        SubidaFotoRequest peticion = new SubidaFotoRequest(METODO_FOTO, ApiClient.BASE_URL + RUTA_FOTO, CAMPO_FOTO,
                fotoNueva, api.getCabeceras(),
                respuesta -> terminar(),
                error -> {
                    bloquear(false);
                    mostrarError(getString(R.string.editar_error_foto));
                });
        peticion.setTag(this);
        api.getCola().add(peticion);
    }

    private void terminar() {
        if (fotoNueva != null) {
            fotoNueva.delete();
            fotoNueva = null;
        }
        Toast.makeText(this, R.string.editar_guardado, Toast.LENGTH_SHORT).show();
        finish();
    }

    // Error 422: la API devuelve en "campos" el mensaje de cada campo mal escrito, y se marca en rojo
    private void mostrarErroresApi(VolleyError error) {
        mostrarError(ApiClient.mensajeDeError(error));
        if (error.networkResponse == null || error.networkResponse.data == null) {
            return;
        }
        try {
            JSONObject cuerpo = new JSONObject(new String(error.networkResponse.data, StandardCharsets.UTF_8));
            JSONObject campos = cuerpo.optJSONObject("campos");
            if (campos == null) {
                return;
            }
            EditText primero = null;
            Iterator<String> claves = campos.keys();
            while (claves.hasNext()) {
                String clave = claves.next();
                EditText campo = camposApi.get(clave);
                if (campo != null) {
                    campo.setError(campos.optString(clave));
                    if (primero == null) {
                        primero = campo;
                    }
                }
            }
            if (primero != null) {
                primero.requestFocus();
            }
        } catch (JSONException e) {
            // Si el cuerpo no es JSON, basta con el mensaje general
        }
    }

    private void marcarError(EditText campo, String mensaje) {
        campo.setError(mensaje);
        campo.requestFocus();
    }

    private void mostrarError(String mensaje) {
        tvError.setText(mensaje);
        tvError.setVisibility(View.VISIBLE);
    }

    private void bloquear(boolean guardando) {
        btnGuardar.setEnabled(!guardando);
        btnGuardar.setText(guardando ? R.string.editar_guardando : R.string.editar_guardar);
    }
}