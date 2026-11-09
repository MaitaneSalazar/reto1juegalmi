package com.example.retoindividual_1.datos;

import android.content.Context;

import androidx.annotation.NonNull;

import com.example.retoindividual_1.network.ApiClient;
import com.example.retoindividual_1.network.Localizador;
import com.example.retoindividual_1.network.SessionManager;

import org.json.JSONObject;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;

import okhttp3.Interceptor;
import okhttp3.OkHttpClient;
import okhttp3.Request;
import okhttp3.Response;
import okhttp3.ResponseBody;
import retrofit2.Retrofit;
import retrofit2.converter.scalars.ScalarsConverterFactory;

//RETROFIT CONTRA LA MISMA API QUE VOLLEY. UNA SOLA INSTANCIA PARA TODA LA APP
public class RetrofitClient {

    private static TiendaApi api;

    public static synchronized TiendaApi getApi(Context context) {
        if (api == null) {
            SessionManager sesion = new SessionManager(context.getApplicationContext());
            Localizador localizador = Localizador.getInstance(context);

            //IGUAL QUE EN VOLLEY: CADA PETICION LLEVA EL TOKEN Y LA UBICACION (X-Lat, X-Lon)
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
                    .build();

            api = new Retrofit.Builder()
                    .baseUrl(ApiClient.BASE_URL)
                    .client(cliente)
                    .addConverterFactory(ScalarsConverterFactory.create())
                    .build()
                    .create(TiendaApi.class);
        }
        return api;
    }

    //EL CAMPO "mensaje" DE LOS ERRORES DE LA API, COMO ApiClient.mensajeDeError PERO PARA RETROFIT
    public static String mensajeDeError(retrofit2.Response<?> respuesta) {
        try (ResponseBody cuerpo = respuesta.errorBody()) {
            if (cuerpo != null) {
                return new JSONObject(cuerpo.string()).optString("mensaje", "Error " + respuesta.code());
            }
        } catch (Exception e) {
            //SI NO ES JSON SE ENSEÑA SOLO EL CODIGO
        }
        return "Error " + respuesta.code();
    }
}
