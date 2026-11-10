package com.example.retoindividual_1.taller;

import com.example.retoindividual_1.utilidades.Exito;
import com.example.retoindividual_1.R;
import android.content.ActivityNotFoundException;
import android.content.Context;
import android.net.Uri;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.PickVisualMediaRequest;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.content.FileProvider;
import androidx.fragment.app.Fragment;

import com.bumptech.glide.Glide;
import com.example.retoindividual_1.datos.Repositorio;
import com.example.retoindividual_1.utilidades.ProcesadorFotos;
import com.google.android.material.button.MaterialButton;
import com.google.android.material.chip.Chip;
import com.google.android.material.chip.ChipGroup;
import com.google.android.material.dialog.MaterialAlertDialogBuilder;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.File;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;


public class NuevaReparacionFragment extends Fragment {

    private Repositorio datos;

    private static final int MIN_CARACTERES_DESCRIPCION = 10;
    private static final int MAX_FOTOS = 5;
    private static final int TIEMPO_MAXIMO_MS = 15000;

    private static final String ESTADO_TIPO = "tipo_dispositivo";
    private static final String ESTADO_FOTOS = "fotos";
    private static final String ESTADO_URI_CAMARA = "uri_camara";

    private final List<View> opcionesDispositivo = new ArrayList<>();
    private String tipoDispositivo;
    private final ArrayList<File> fotos = new ArrayList<>();
    private Uri uriCamara;
    private final ExecutorService hiloFotos = Executors.newSingleThreadExecutor();
    private final Handler hiloPrincipal = new Handler(Looper.getMainLooper());

    private EditText etMarca;
    private EditText etModelo;
    private EditText etDescripcion;
    private ChipGroup cgComponente;
    private View vPaso1;
    private View vPaso2;
    private View vPaso3;
    private LinearLayout llFotos;
    private View llAnadirFoto;
    private TextView tvError;
    private MaterialButton btnEnviar;

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
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        return inflater.inflate(R.layout.fragment_nueva_reparacion, container, false);
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        //CON EL FRAGMENT Y NO CON LA VISTA: LA SUBIDA DE FOTOS SIGUE AUNQUE SE CAMBIE DE PESTAÑA
        if (datos == null) {
            datos = new Repositorio(requireContext(), this);
        }

        etMarca = view.findViewById(R.id.etReparacionMarca);
        etModelo = view.findViewById(R.id.etReparacionModelo);
        etDescripcion = view.findViewById(R.id.etReparacionDescripcion);
        cgComponente = view.findViewById(R.id.cgComponente);
        vPaso1 = view.findViewById(R.id.vPaso1);
        vPaso2 = view.findViewById(R.id.vPaso2);
        vPaso3 = view.findViewById(R.id.vPaso3);
        llFotos = view.findViewById(R.id.llFotos);
        llAnadirFoto = view.findViewById(R.id.llAnadirFoto);
        tvError = view.findViewById(R.id.tvReparacionError);
        btnEnviar = view.findViewById(R.id.btnEnviarReparacion);

        if (savedInstanceState != null) {
            tipoDispositivo = savedInstanceState.getString(ESTADO_TIPO);
            uriCamara = savedInstanceState.getParcelable(ESTADO_URI_CAMARA);
            ArrayList<String> rutas = savedInstanceState.getStringArrayList(ESTADO_FOTOS);
            if (rutas != null && fotos.isEmpty()) {
                for (String ruta : rutas) {
                    fotos.add(new File(ruta));
                }
            }
        }

        opcionesDispositivo.clear();
        recogerOpciones(view.findViewById(R.id.llFilaDispositivos1));
        recogerOpciones(view.findViewById(R.id.llFilaDispositivos2));
        for (View opcion : opcionesDispositivo) {
            opcion.setOnClickListener(this::elegirDispositivo);
        }
        marcarDispositivo();

        TextWatcher alEscribir = new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {
            }

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {
            }

            @Override
            public void afterTextChanged(Editable s) {
                actualizarProgreso();
            }
        };
        etMarca.addTextChangedListener(alEscribir);
        etModelo.addTextChangedListener(alEscribir);
        etDescripcion.addTextChangedListener(alEscribir);
        cgComponente.setOnCheckedStateChangeListener((grupo, ids) -> actualizarProgreso());

        llAnadirFoto.setOnClickListener(v -> elegirOrigenFoto());
        btnEnviar.setOnClickListener(v -> enviar());

        pintarFotos();
        actualizarProgreso();
    }

    @Override
    public void onSaveInstanceState(@NonNull Bundle outState) {
        super.onSaveInstanceState(outState);
        outState.putString(ESTADO_TIPO, tipoDispositivo);
        outState.putParcelable(ESTADO_URI_CAMARA, uriCamara);
        ArrayList<String> rutas = new ArrayList<>();
        for (File foto : fotos) {
            rutas.add(foto.getAbsolutePath());
        }
        outState.putStringArrayList(ESTADO_FOTOS, rutas);
    }

    @Override
    public void onDestroy() {
        super.onDestroy();
        hiloFotos.shutdown();
    }

    private void recogerOpciones(ViewGroup fila) {
        for (int i = 0; i < fila.getChildCount(); i++) {
            opcionesDispositivo.add(fila.getChildAt(i));
        }
    }

    private void elegirDispositivo(View elegida) {
        tipoDispositivo = (String) elegida.getTag();
        marcarDispositivo();
        actualizarProgreso();
    }

    private void marcarDispositivo() {
        for (View opcion : opcionesDispositivo) {
            opcion.setSelected(opcion.getTag().equals(tipoDispositivo));
        }
    }

    private boolean componenteElegido() {
        return cgComponente.getCheckedChipId() != View.NO_ID;
    }

    @Nullable
    private String getComponenteParaApi() {
        int id = cgComponente.getCheckedChipId();
        if (id == View.NO_ID) {
            return null;
        }
        Chip chip = cgComponente.findViewById(id);
        if ("NO_LO_SE".equals(chip.getTag())) {
            return null;
        }
        return chip.getText().toString();
    }

    private String texto(EditText campo) {
        return campo.getText().toString().trim();
    }


    private boolean dispositivoCompleto() {
        return tipoDispositivo != null;
    }

    private boolean marcaModeloCompletos() {
        return !texto(etMarca).isEmpty() && !texto(etModelo).isEmpty();
    }

    private boolean averiaCompleta() {
        return componenteElegido() && texto(etDescripcion).length() >= MIN_CARACTERES_DESCRIPCION;
    }

    private void actualizarProgreso() {
        marcarPaso(vPaso1, dispositivoCompleto());
        marcarPaso(vPaso2, marcaModeloCompletos());
        marcarPaso(vPaso3, averiaCompleta());
    }

    private void marcarPaso(View paso, boolean completo) {
        paso.setBackgroundResource(completo ? R.drawable.bg_pildora_marca : R.drawable.bg_pildora_pozo);
    }

    private void elegirOrigenFoto() {
        if (fotos.size() >= MAX_FOTOS) {
            mostrarError(getString(R.string.error_max_fotos));
            return;
        }
        String[] opciones = {getString(R.string.foto_hacer), getString(R.string.foto_galeria)};
        new MaterialAlertDialogBuilder(requireContext())
                .setTitle(R.string.foto_titulo_dialogo)
                .setItems(opciones, (dialogo, cual) -> {
                    if (cual == 0) {
                        hacerFoto();
                    } else {
                        elegirDeGaleria();
                    }
                })
                .setNegativeButton(R.string.foto_cancelar, null)
                .show();
    }

    private void hacerFoto() {
        try {
            File carpeta = new File(requireContext().getCacheDir(), "camara");
            if (!carpeta.exists() && !carpeta.mkdirs()) {
                throw new IOException("No se ha podido crear la carpeta de la cámara");
            }
            File archivo = File.createTempFile("camara_", ".jpg", carpeta);
            uriCamara = FileProvider.getUriForFile(requireContext(),
                    requireContext().getPackageName() + ".fileprovider", archivo);
            lanzadorCamara.launch(uriCamara);
        } catch (IOException | ActivityNotFoundException e) {
            mostrarError(getString(R.string.error_sin_camara));
        }
    }

    private void elegirDeGaleria() {
        lanzadorGaleria.launch(new PickVisualMediaRequest.Builder()
                .setMediaType(ActivityResultContracts.PickVisualMedia.ImageOnly.INSTANCE)
                .build());
    }

    private void procesarFoto(Uri origen, boolean esDeCamara) {
        Context contexto = requireContext().getApplicationContext();
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
                if (!isAdded()) {
                    return;
                }
                if (resultado == null) {
                    mostrarError(getString(R.string.error_foto));
                    return;
                }
                fotos.add(resultado);
                pintarFotos();
            });
        });
    }

    private void pintarFotos() {
        llFotos.removeViews(0, llFotos.getChildCount() - 1);

        float densidad = getResources().getDisplayMetrics().density;
        int tamano = Math.round(80 * densidad);
        int margen = Math.round(8 * densidad);

        for (File foto : fotos) {
            ImageView miniatura = new ImageView(requireContext());
            LinearLayout.LayoutParams lp = new LinearLayout.LayoutParams(tamano, tamano);
            lp.setMarginEnd(margen);
            miniatura.setLayoutParams(lp);
            miniatura.setScaleType(ImageView.ScaleType.CENTER_CROP);
            miniatura.setBackgroundResource(R.drawable.bg_miniatura);
            miniatura.setClipToOutline(true);
            miniatura.setContentDescription(getString(R.string.foto_reparacion));
            miniatura.setOnClickListener(v -> preguntarQuitar(foto));
            Glide.with(this).load(foto).into(miniatura);
            llFotos.addView(miniatura, llFotos.getChildCount() - 1);
        }

        llAnadirFoto.setVisibility(fotos.size() >= MAX_FOTOS ? View.GONE : View.VISIBLE);
    }

    private void preguntarQuitar(File foto) {
        new MaterialAlertDialogBuilder(requireContext())
                .setTitle(R.string.foto_quitar_titulo)
                .setPositiveButton(R.string.foto_quitar, (dialogo, boton) -> {
                    fotos.remove(foto);
                    foto.delete();
                    pintarFotos();
                })
                .setNegativeButton(R.string.foto_cancelar, null)
                .show();
    }
    private void enviar() {
        if (!dispositivoCompleto()) {
            mostrarError(getString(R.string.error_reparacion_dispositivo));
            return;
        }
        if (!marcaModeloCompletos()) {
            mostrarError(getString(R.string.error_reparacion_marca));
            return;
        }
        if (!componenteElegido()) {
            mostrarError(getString(R.string.error_reparacion_componente));
            return;
        }
        if (texto(etDescripcion).length() < MIN_CARACTERES_DESCRIPCION) {
            mostrarError(getString(R.string.error_reparacion_descripcion));
            return;
        }
        tvError.setVisibility(View.GONE);

        JSONObject cuerpo = new JSONObject();
        try {
            cuerpo.put("tipo_dispositivo", tipoDispositivo);
            cuerpo.put("marca", texto(etMarca));
            cuerpo.put("modelo", texto(etModelo));
            String componente = getComponenteParaApi();
            if (componente != null) {
                cuerpo.put("componente", componente);
            }
            cuerpo.put("descripcion_averia", texto(etDescripcion));
        } catch (JSONException e) {
            return;
        }

        bloquearBoton(true);

        datos.crearReparacion(cuerpo, new Repositorio.Resultado<JSONObject>() {
            @Override
            public void bien(JSONObject respuesta) {
                if (!isAdded()) {
                    return;
                }
                int idReparacion = respuesta.optInt("id", -1);
                if (fotos.isEmpty() || idReparacion == -1) {
                    terminar(0);
                } else {
                    subirFoto(idReparacion, 0, 0);
                }
            }

            @Override
            public void mal(String mensaje) {
                if (!isAdded()) {
                    return;
                }
                bloquearBoton(false);
                mostrarError(mensaje);
            }
        });
    }

    private void subirFoto(int idReparacion, int indice, int fallos) {
        if (indice >= fotos.size()) {
            terminar(fallos);
            return;
        }
        datos.subirFotoReparacion(idReparacion, fotos.get(indice), new Repositorio.Resultado<JSONObject>() {
            @Override
            public void bien(JSONObject respuesta) {
                if (isAdded()) {
                    subirFoto(idReparacion, indice + 1, fallos);
                }
            }

            @Override
            public void mal(String mensaje) {
                if (isAdded()) {
                    subirFoto(idReparacion, indice + 1, fallos + 1);
                }
            }
        });
    }

    private void terminar(int fotosFallidas) {
        String texto = fotosFallidas == 0
                ? getString(R.string.reparacion_enviada)
                : getString(R.string.reparacion_enviada_fotos_fallidas, fotosFallidas);
        for (File foto : fotos) {
            foto.delete();
        }
        fotos.clear();

        //CUANDO TERMINA LA ANIMACION SE PASA A "MIS REPARACIONES"
        Exito.mostrar(requireActivity(), texto, () -> {
            if (isAdded() && getParentFragment() instanceof TallerFragment) {
                ((TallerFragment) getParentFragment()).mostrar(true);
            }
        });
    }

    private void bloquearBoton(boolean enviando) {
        btnEnviar.setEnabled(!enviando);
        btnEnviar.setText(enviando ? R.string.reparacion_enviando : R.string.enviar_solicitud);
    }

    private void mostrarError(String mensaje) {
        tvError.setText(mensaje);
        tvError.setVisibility(View.VISIBLE);
    }
}