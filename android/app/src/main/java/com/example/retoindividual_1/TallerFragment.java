package com.example.retoindividual_1;

import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;

/*
 * =====================================================================================
 *  TALLER (08 y 14 del mockup). Tiene dos SUB-PESTAÑAS:
 *   - Nueva reparación  -> NuevaReparacionFragment
 *   - Mis reparaciones  -> MisReparacionesFragment
 *
 *  Cada sub-pestaña es un Fragment HIJO que se carga en flTaller. Por eso se usa
 *  getChildFragmentManager() (el de este Fragment) y no el de la Activity.
 * =====================================================================================
 */
public class TallerFragment extends Fragment {

    private static final String ARG_MIS_REPARACIONES = "mis_reparaciones";
    private static final String ESTADO_SUBPESTANA = "subpestana";

    private TextView tvSubNueva;
    private TextView tvSubMis;
    private boolean enMisReparaciones = false;

    // Crea el Taller abriendo directamente una sub-pestaña.
    // Lo usa el menú lateral para ir a "Mis reparaciones"
    public static TallerFragment crear(boolean misReparaciones) {
        TallerFragment fragment = new TallerFragment();
        Bundle args = new Bundle();
        args.putBoolean(ARG_MIS_REPARACIONES, misReparaciones);
        fragment.setArguments(args);
        return fragment;
    }

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        return inflater.inflate(R.layout.fragment_taller, container, false);
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);

        tvSubNueva = view.findViewById(R.id.tvSubNueva);
        tvSubMis = view.findViewById(R.id.tvSubMis);
        tvSubNueva.setOnClickListener(v -> mostrar(false));
        tvSubMis.setOnClickListener(v -> mostrar(true));

        // Al girar el móvil se recupera qué sub-pestaña estaba abierta
        if (savedInstanceState != null) {
            enMisReparaciones = savedInstanceState.getBoolean(ESTADO_SUBPESTANA, false);
        }

        if (getChildFragmentManager().findFragmentById(R.id.flTaller) == null) {
            // Primera vez: se abre la que pidan los argumentos (por defecto, Nueva reparación)
            boolean inicial = getArguments() != null && getArguments().getBoolean(ARG_MIS_REPARACIONES, false);
            mostrar(inicial);
        } else {
            // Ya había una sub-pestaña (al girar o al volver del seguimiento): Android la
            // recupera sola, solo hay que marcarla
            marcar();
        }
    }

    @Override
    public void onSaveInstanceState(@NonNull Bundle outState) {
        super.onSaveInstanceState(outState);
        outState.putBoolean(ESTADO_SUBPESTANA, enMisReparaciones);
    }

    // Abre una sub-pestaña. Es pública porque NuevaReparacionFragment la usa
    // para pasar a "Mis reparaciones" después de enviar una solicitud
    public void mostrar(boolean misReparaciones) {
        boolean yaAbierta = misReparaciones == enMisReparaciones
                && getChildFragmentManager().findFragmentById(R.id.flTaller) != null;
        if (yaAbierta) {
            return;   // así no se borra lo que el usuario ya ha escrito en el formulario
        }
        enMisReparaciones = misReparaciones;
        Fragment hijo = misReparaciones ? new MisReparacionesFragment() : new NuevaReparacionFragment();
        getChildFragmentManager().beginTransaction().replace(R.id.flTaller, hijo).commit();
        marcar();
    }

    // setSelected activa los selectores de bg_segmento y texto_segmento
    private void marcar() {
        tvSubNueva.setSelected(!enMisReparaciones);
        tvSubMis.setSelected(enMisReparaciones);
    }
}