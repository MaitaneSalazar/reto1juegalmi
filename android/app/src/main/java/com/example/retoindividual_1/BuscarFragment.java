package com.example.retoindividual_1;

import android.app.Activity;
import android.content.ActivityNotFoundException;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.speech.RecognizerIntent;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.KeyEvent;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.view.inputmethod.EditorInfo;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.TextView;
import android.widget.Toast;

import androidx.activity.result.ActivityResult;
import androidx.activity.result.ActivityResultCallback;
import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;
import androidx.recyclerview.widget.GridLayoutManager;
import androidx.recyclerview.widget.RecyclerView;

import com.android.volley.Request;
import com.android.volley.Response;
import com.android.volley.VolleyError;
import com.android.volley.toolbox.JsonObjectRequest;
import com.example.retoindividual_1.adaptadores.ProductoAdapter;
import com.example.retoindividual_1.modelos.Producto;
import com.example.retoindividual_1.network.ApiClient;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;

//BUSCADOR DE LA TIENDA (LA LUPA), SE PUEDE ESCRIBIR O BUSCAR HABLANDO. USA /productos?q=
public class BuscarFragment extends Fragment {

    //ESPERAMOS UN POCO DESPUES DE CADA LETRA PARA NO HACER UNA PETICION POR TECLA
    private static final long ESPERA_MS = 350;

    private EditText etBuscar;
    private ImageView ivBorrar;
    private RecyclerView rvResultados;
    private ProgressBar pbBuscar;
    private LinearLayout llAviso;
    private TextView tvAvisoTitulo;
    private TextView tvAvisoTexto;

    private final Handler espera = new Handler(Looper.getMainLooper());
    private final Runnable buscarAhora = new Runnable() {
        @Override
        public void run() {
            buscar(etBuscar.getText().toString().trim());
        }
    };

    //LO QUE DEVUELVE EL RECONOCEDOR DE VOZ DE GOOGLE: LA FRASE MAS PROBABLE VA PRIMERO
    private final ActivityResultLauncher<Intent> voz = registerForActivityResult(
            new ActivityResultContracts.StartActivityForResult(), new ActivityResultCallback<ActivityResult>() {
                @Override
                public void onActivityResult(ActivityResult resultado) {
                    if (resultado.getResultCode() != Activity.RESULT_OK || resultado.getData() == null) {
                        return;
                    }
                    ArrayList<String> frases = resultado.getData().getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS);
                    if (frases != null && !frases.isEmpty()) {
                        etBuscar.setText(frases.get(0));
                        etBuscar.setSelection(etBuscar.length());
                    }
                }
            });

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        return inflater.inflate(R.layout.fragment_buscar, container, false);
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        etBuscar = view.findViewById(R.id.etBuscar);
        ivBorrar = view.findViewById(R.id.ivBuscarBorrar);
        rvResultados = view.findViewById(R.id.rvBuscar);
        pbBuscar = view.findViewById(R.id.pbBuscar);
        llAviso = view.findViewById(R.id.llBuscarAviso);
        tvAvisoTitulo = view.findViewById(R.id.tvBuscarAvisoTitulo);
        tvAvisoTexto = view.findViewById(R.id.tvBuscarAvisoTexto);

        rvResultados.setLayoutManager(new GridLayoutManager(getContext(), 2));

        //LA FLECHA VUELVE A LA TIENDA
        view.findViewById(R.id.ivVolver).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                getParentFragmentManager().popBackStack();
            }
        });

        //CADA VEZ QUE CAMBIA EL TEXTO SE VUELVE A BUSCAR, CON UN POCO DE ESPERA
        etBuscar.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence texto, int inicio, int cuantos, int despues) {
            }

            @Override
            public void onTextChanged(CharSequence texto, int inicio, int antes, int cuantos) {
            }

            @Override
            public void afterTextChanged(Editable texto) {
                ivBorrar.setVisibility(texto.length() > 0 ? View.VISIBLE : View.GONE);
                espera.removeCallbacks(buscarAhora);
                espera.postDelayed(buscarAhora, ESPERA_MS);
            }
        });

        //LA LUPA DEL TECLADO BUSCA YA, SIN ESPERAR
        etBuscar.setOnEditorActionListener(new TextView.OnEditorActionListener() {
            @Override
            public boolean onEditorAction(TextView v, int accion, KeyEvent evento) {
                if (accion == EditorInfo.IME_ACTION_SEARCH) {
                    espera.removeCallbacks(buscarAhora);
                    buscarAhora.run();
                    return true;
                }
                return false;
            }
        });

        ivBorrar.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                etBuscar.setText("");
            }
        });

        view.findViewById(R.id.ivBuscarVoz).setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                escuchar();
            }
        });

        etBuscar.requestFocus();
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        espera.removeCallbacks(buscarAhora);
        ApiClient.getInstance(requireContext()).getCola().cancelAll(this);
    }

    //ABRIMOS EL RECONOCEDOR DE VOZ DEL MOVIL EN ESPAÑOL. NO HACE FALTA PERMISO DE MICROFONO, LO PIDE EL
    private void escuchar() {
        Intent intent = new Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH);
        intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM);
        intent.putExtra(RecognizerIntent.EXTRA_LANGUAGE, "es-ES");
        intent.putExtra(RecognizerIntent.EXTRA_PROMPT, getString(R.string.buscar_habla));
        try {
            voz.launch(intent);
        } catch (ActivityNotFoundException e) {
            Toast.makeText(getContext(), R.string.buscar_sin_voz, Toast.LENGTH_SHORT).show();
        }
    }

    private void buscar(String texto) {
        //CANCELAMOS LA BUSQUEDA ANTERIOR PARA QUE NO LLEGUE DESPUES Y PISE ESTA
        ApiClient.getInstance(requireContext()).getCola().cancelAll(this);
        rvResultados.setAdapter(null);

        if (texto.isEmpty()) {
            pbBuscar.setVisibility(View.GONE);
            mostrarAviso(getString(R.string.buscar_inicio_titulo), getString(R.string.buscar_inicio_texto));
            return;
        }
        llAviso.setVisibility(View.GONE);
        pbBuscar.setVisibility(View.VISIBLE);

        JsonObjectRequest peticion = new JsonObjectRequest(Request.Method.GET,
                ApiClient.BASE_URL + "productos?limit=50&q=" + Uri.encode(texto), null,
                new Response.Listener<JSONObject>() {
                    @Override
                    public void onResponse(JSONObject respuesta) {
                        pbBuscar.setVisibility(View.GONE);
                        JSONArray datos = respuesta.optJSONArray("datos");
                        List<Producto> productos = new ArrayList<>();
                        for (int i = 0; datos != null && i < datos.length(); i++) {
                            productos.add(new Producto(datos.optJSONObject(i)));
                        }
                        if (productos.isEmpty()) {
                            mostrarAviso(getString(R.string.buscar_vacio_titulo), getString(R.string.buscar_vacio_texto, texto));
                        } else {
                            rvResultados.setAdapter(new ProductoAdapter(productos, false));
                        }
                    }
                },
                new Response.ErrorListener() {
                    @Override
                    public void onErrorResponse(VolleyError error) {
                        pbBuscar.setVisibility(View.GONE);
                        mostrarAviso(getString(R.string.buscar_error_titulo), ApiClient.mensajeDeError(error));
                    }
                });
        peticion.setTag(this);
        ApiClient.getInstance(requireContext()).getCola().add(peticion);
    }

    private void mostrarAviso(String titulo, String texto) {
        tvAvisoTitulo.setText(titulo);
        tvAvisoTexto.setText(texto);
        llAviso.setVisibility(View.VISIBLE);
    }
}
