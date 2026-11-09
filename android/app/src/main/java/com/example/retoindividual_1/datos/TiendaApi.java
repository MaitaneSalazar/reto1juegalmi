package com.example.retoindividual_1.datos;

import retrofit2.Call;
import retrofit2.http.GET;
import retrofit2.http.Query;

//LLAMADAS A LA API HECHAS CON RETROFIT. DEVUELVEN EL JSON EN TEXTO Y LO LEEN LOS MODELOS COMO CON VOLLEY
public interface TiendaApi {

    //GET productos?q=texto&limit=50
    @GET("productos")
    Call<String> buscar(@Query("q") String texto, @Query("limit") int limite);
}
