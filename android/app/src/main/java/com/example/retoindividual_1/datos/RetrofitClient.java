package com.example.retoindividual_1.datos;

import android.content.Context;

import androidx.annotation.NonNull;

import com.example.retoindividual_1.BuildConfig;
import com.example.retoindividual_1.network.Localizador;
import com.example.retoindividual_1.network.SessionManager;

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
            SessionManager sesion = new SessionManager(context.getApplicationContext());
            Localizador localizador = Localizador.getInstance(context);

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
                            return cadena.proceed(peticion.build());
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
}
