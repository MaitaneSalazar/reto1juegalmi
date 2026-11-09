package com.example.retoindividual_1.nosotros;

import com.example.retoindividual_1.R;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewGroup;
import android.widget.Button;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.fragment.app.Fragment;

import com.example.retoindividual_1.datos.Repositorio;

import org.json.JSONObject;
import org.osmdroid.config.Configuration;
import org.osmdroid.config.IConfigurationProvider;
import org.osmdroid.tileprovider.tilesource.OnlineTileSourceBase;
import org.osmdroid.util.MapTileIndex;
import org.osmdroid.util.GeoPoint;
import org.osmdroid.views.CustomZoomButtonsController;
import org.osmdroid.views.MapView;
import org.osmdroid.views.overlay.CopyrightOverlay;

import java.io.File;

//PESTAÑA UBICACION, LA DIRECCION, EL TELEFONO Y LAS COORDENADAS SALEN DE /tienda
public class UbicacionFragment extends Fragment {

    private Repositorio datos;

    //MIENTRAS LLEGAN LAS COORDENADAS DE LA API, EL MAPA ENSEÑA BILBAO
    private static final GeoPoint BILBAO = new GeoPoint(43.2630, -2.9350);
    private static final double ZOOM = 17.0;

    //MAPAS DE ESRI (WORLD STREET MAP): NO PIDEN CLAVE DE API NI BLOQUEAN APPS PEQUEÑAS.
    //OPENSTREETMAP DEVOLVIA "ACCESS BLOCKED" Y CARTO AHORA PIDE CLAVE
    private static final OnlineTileSourceBase ESRI_CALLES = new OnlineTileSourceBase("EsriCalles", 0, 19, 256, "",
            new String[]{"https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/"},
            "Tiles © Esri") {
        @Override
        public String getTileURLString(long indice) {
            //ESRI PIDE LAS COORDENADAS EN ORDEN ZOOM/Y/X (OPENSTREETMAP USA ZOOM/X/Y)
            return getBaseUrl() + MapTileIndex.getZoom(indice) + "/" + MapTileIndex.getY(indice) + "/" + MapTileIndex.getX(indice);
        }
    };
    private ProgressBar pbUbicacion;
    private TextView tvError;
    private LinearLayout llDatos;
    private TextView tvLinea1;
    private TextView tvLinea2;
    private TextView tvTelefono;
    private LinearLayout llTelefono;
    private Button btnComoLlegar;
    private MapView mvMapa;

    @Override
    public View onCreateView(@NonNull LayoutInflater inflater, @Nullable ViewGroup container, @Nullable Bundle savedInstanceState) {
        //TIENE QUE IR ANTES DE CREAR EL MAPA. LOS SERVIDORES DE MAPAS PIDEN QUE LA APP SE IDENTIFIQUE,
        //Y LAS TESELAS SE GUARDAN EN LA CACHE DE LA APP, ASI NO HACE FALTA PERMISO DE ALMACENAMIENTO
        IConfigurationProvider configuracion = Configuration.getInstance();
        configuracion.setUserAgentValue("JuegAlmi/1.0 (reto DAM, Centro ALMI)");
        File base = new File(requireContext().getCacheDir(), "osmdroid");
        configuracion.setOsmdroidBasePath(base);
        configuracion.setOsmdroidTileCache(new File(base, "teselas"));

        return inflater.inflate(R.layout.fragment_ubicacion, container, false);
    }

    @Override
    public void onViewCreated(@NonNull View view, @Nullable Bundle savedInstanceState) {
        super.onViewCreated(view, savedInstanceState);
        datos = new Repositorio(requireContext(), getViewLifecycleOwner());

        pbUbicacion = view.findViewById(R.id.pbUbicacion);
        tvError = view.findViewById(R.id.tvUbicacionError);
        llDatos = view.findViewById(R.id.llUbicacionDatos);
        tvLinea1 = view.findViewById(R.id.tvUbicacionLinea1);
        tvLinea2 = view.findViewById(R.id.tvUbicacionLinea2);
        tvTelefono = view.findViewById(R.id.tvUbicacionTelefono);
        llTelefono = view.findViewById(R.id.llUbicacionTelefono);
        btnComoLlegar = view.findViewById(R.id.btnComoLlegar);
        mvMapa = view.findViewById(R.id.mvUbicacion);

        configurarMapa();
        //TOCAR EL MAPA HACE LO MISMO QUE "COMO LLEGAR"
        view.findViewById(R.id.vUbicacionMapaToque).setOnClickListener(v -> btnComoLlegar.performClick());

        cargarTienda();
    }

    private void configurarMapa() {
        mvMapa.setTileSource(ESRI_CALLES);
        mvMapa.getZoomController().setVisibility(CustomZoomButtonsController.Visibility.NEVER);
        mvMapa.setMultiTouchControls(false);
        //LAS CONDICIONES DE ESRI OBLIGAN A ENSEÑAR "Tiles © Esri"mvMapa.getOverlays().add(new CopyrightOverlay(requireContext()));
        mvMapa.getController().setZoom(ZOOM);
        mvMapa.getController().setCenter(BILBAO);
    }

    //EL MAPA TIENE QUE SABER CUANDO SE VE Y CUANDO NO, PARA NO DESCARGAR TESELAS EN SEGUNDO PLANO
    @Override
    public void onResume() {
        super.onResume();
        mvMapa.onResume();
    }

    @Override
    public void onPause() {
        super.onPause();
        mvMapa.onPause();
    }

    @Override
    public void onDestroyView() {
        super.onDestroyView();
        mvMapa.onDetach();
    }

    private void cargarTienda() {
        datos.tienda(new Repositorio.Resultado<JSONObject>() {
            @Override
            public void bien(JSONObject tienda) {
                pbUbicacion.setVisibility(View.GONE);
                pintarTienda(tienda);
            }

            @Override
            public void mal(String mensaje) {
                pbUbicacion.setVisibility(View.GONE);
                tvError.setVisibility(View.VISIBLE);
            }
        });
    }

    private void pintarTienda(JSONObject tienda) {
        String telefono = tienda.optString("telefono");
        double latitud = tienda.optDouble("latitud");
        double longitud = tienda.optDouble("longitud");

        tvLinea1.setText(tienda.optString("direccion_linea1"));
        tvLinea2.setText(tienda.optString("direccion_linea2"));
        tvTelefono.setText(telefono);
        llDatos.setVisibility(View.VISIBLE);

        //EL PIN ESTA FIJO EN EL CENTRO DE LA TARJETA: CENTRANDO EL MAPA EN LA TIENDA, QUEDA ENCIMA
        if (!Double.isNaN(latitud) && !Double.isNaN(longitud)) {
            mvMapa.getController().setCenter(new GeoPoint(latitud, longitud));
        }

        //ACTION_DIAL SOLO ABRE EL MARCADOR CON EL NUMERO, NO NECESITA PERMISO DE LLAMADAS
        llTelefono.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                startActivity(new Intent(Intent.ACTION_DIAL, Uri.parse("tel:" + telefono)));
            }
        });

        //ABRE LA RUTA HASTA LA TIENDA EN GOOGLE MAPS, O EN EL NAVEGADOR SI NO ESTA INSTALADO
        btnComoLlegar.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                startActivity(new Intent(Intent.ACTION_VIEW,
                        Uri.parse("https://www.google.com/maps/dir/?api=1&destination=" + latitud + "," + longitud)));
            }
        });
    }
}