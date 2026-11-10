package com.example.retoindividual_1.datos;

import android.content.Context;
import android.content.Intent;
import android.os.Handler;
import android.os.Looper;
import android.widget.Toast;

import androidx.annotation.NonNull;

import com.example.retoindividual_1.BuildConfig;
import com.example.retoindividual_1.R;
import com.example.retoindividual_1.network.Localizador;
import com.example.retoindividual_1.network.SessionManager;
import com.example.retoindividual_1.sesion.LoginActivity;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.TimeUnit;

import okhttp3.Interceptor;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;
import retrofit2.Retrofit;
import retrofit2.converter.scalars.ScalarsConverterFactory;

//RETROFIT CONTRA LA API. UNA SOLA INSTANCIA PARA TODA LA APP
public class RetrofitClient {

    private static TiendaApi api;

    public static synchronized TiendaApi getApi(Context context) {
        if (api == null) {
            Context contexto = context.getApplicationContext();
            SessionManager sesion = new SessionManager(contexto);
            Localizador localizador = Localizador.getInstance(context);
            Handler hiloPrincipal = new Handler(Looper.getMainLooper());

            //CADA PETICION LLEVA EL TOKEN Y LA UBICACION (X-Lat, X-Lon)
            OkHttpClient cliente = new OkHttpClient.Builder()
                    .addInterceptor(new Interceptor() {
                        @NonNull
                        @Override
                        public Response intercept(@NonNull Chain cadena) throws IOException {
                            Request.Builder peticion = cadena.request().newBuilder();
                            Map<String, String> cabeceras = new HashMap<>();
                            localizador.anadirCabeceras(cabeceras);
                            String token = sesion.getToken();
                            if (token != null) {
                                cabeceras.put("Authorization", "Bearer " + token);
                            }
                            for (Map.Entry<String, String> cabecera : cabeceras.entrySet()) {
                                peticion.header(cabecera.getKey(), cabecera.getValue());
                            }
                            Response respuesta = cadena.proceed(peticion.build());

                            //401 = EL TOKEN HA CADUCADO O YA NO VALE. EN EL LOGIN, 401 ES SOLO "CONTRASEÑA INCORRECTA"
                            boolean esLogin = cadena.request().url().encodedPath().endsWith("login");
                            if (respuesta.code() == 401 && !esLogin) {
                                //AQUI ESTAMOS EN UN HILO DE RED: ABRIR UNA PANTALLA TIENE QUE IR AL HILO PRINCIPAL
                                hiloPrincipal.post(() -> sesionCaducada(contexto));
                            }
                            return respuesta;
                        }
                    })
                    //LAS FOTOS TARDAN EN SUBIR, LE DAMOS 30 SEGUNDOS
                    .writeTimeout(30, TimeUnit.SECONDS)
                    .readTimeout(30, TimeUnit.SECONDS)
                    .build();

            api = new Retrofit.Builder()
                    .baseUrl(BuildConfig.API_URL)
                    .client(cliente)
                    .addConverterFactory(ScalarsConverterFactory.create())
                    .build()
                    .create(TiendaApi.class);
        }
        return api;
    }

    //BORRA LA SESION (Y LA CESTA) Y VUELVE AL LOGIN, COMO PIDE LA GUIA DE LA API
    private static void sesionCaducada(Context contexto) {
        SessionManager sesion = new SessionManager(contexto);
        if (!sesion.haySesion()) {
            return; //SI FALLAN VARIAS PETICIONES A LA VEZ, SOLO ACTUA LA PRIMERA
        }
        sesion.cerrarSesion();
        Toast.makeText(contexto, R.string.sesion_caducada, Toast.LENGTH_LONG).show();
        Intent intent = new Intent(contexto, LoginActivity.class);
        intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
        contexto.startActivity(intent);
    }
}