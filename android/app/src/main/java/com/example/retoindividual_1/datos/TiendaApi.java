package com.example.retoindividual_1.datos;

import retrofit2.Call;
import okhttp3.MultipartBody;
import retrofit2.http.Body;
import retrofit2.http.DELETE;
import retrofit2.http.GET;
import retrofit2.http.Headers;
import retrofit2.http.Multipart;
import retrofit2.http.POST;
import retrofit2.http.PUT;
import retrofit2.http.Part;
import retrofit2.http.Path;
import retrofit2.http.Query;

//TODAS LAS LLAMADAS A LA API HECHAS CON RETROFIT.
//DEVUELVEN EL JSON EN TEXTO Y LO CONVIERTE EN MODELOS EL Repositorio. LOS @Query A null NO SE MANDAN
public interface TiendaApi {

    //TIENDA
    @GET("productos")
    Call<String> productos(@Query("tipo") String tipo, @Query("plataforma") String plataforma,
                           @Query("q") String texto, @Query("page") Integer pagina, @Query("limit") int limite);

    @GET("productos/filtros")
    Call<String> filtros();

    @GET("productos/{id}")
    Call<String> producto(@Path("id") int id);

    @GET("videojuegos/alquiler")
    Call<String> alquilables(@Query("plataforma") String plataforma, @Query("page") int pagina, @Query("limit") int limite);

    @GET("videojuegos/plataformas")
    Call<String> plataformasAlquiler();

    //CESTA
    @GET("domicilios")
    Call<String> domicilios();

    @Headers("Content-Type: application/json")
    @POST("pedidos")
    Call<String> crearPedido(@Body String cuerpo);

    @Headers("Content-Type: application/json")
    @POST("alquileres")
    Call<String> crearAlquiler(@Body String cuerpo);

    //PEDIDOS
    @GET("pedidos")
    Call<String> pedidos(@Query("limit") int limite);

    @GET("pedidos/{id}")
    Call<String> pedido(@Path("id") int id);

    @PUT("pedidos/{id}/cancelar")
    Call<String> cancelarPedido(@Path("id") int id);

    //ALQUILERES
    @GET("alquileres")
    Call<String> alquileres(@Query("limit") int limite);

    @PUT("alquileres/{id}/devolver")
    Call<String> devolver(@Path("id") int id);

    //INICIO
    @GET("yo")
    Call<String> yo();

    @GET("reparaciones")
    Call<String> reparaciones(@Query("limit") int limite);

    //SESION
    @Headers("Content-Type: application/json")
    @POST("login")
    Call<String> login(@Body String cuerpo);

    @Headers("Content-Type: application/json")
    @POST("registro")
    Call<String> registro(@Body String cuerpo);

    @GET("estado")
    Call<String> estado();

    //CUENTA
    @Headers("Content-Type: application/json")
    @PUT("yo")
    Call<String> editarYo(@Body String cuerpo);

    //PHP NO LEE ARCHIVOS ENVIADOS CON PUT, POR ESO LA FOTO VA CON POST
    @Multipart
    @POST("yo/foto")
    Call<String> fotoPerfil(@Part MultipartBody.Part imagen);

    @Headers("Content-Type: application/json")
    @POST("domicilios")
    Call<String> crearDomicilio(@Body String cuerpo);

    @Headers("Content-Type: application/json")
    @PUT("domicilios/{id}")
    Call<String> editarDomicilio(@Path("id") int id, @Body String cuerpo);

    @DELETE("domicilios/{id}")
    Call<String> borrarDomicilio(@Path("id") int id);

    //TALLER
    @GET("reparaciones/{id}")
    Call<String> reparacion(@Path("id") int id);

    @Headers("Content-Type: application/json")
    @POST("reparaciones")
    Call<String> crearReparacion(@Body String cuerpo);

    @DELETE("reparaciones/{id}")
    Call<String> cancelarReparacion(@Path("id") int id);

    @Multipart
    @POST("reparaciones/{id}/fotos")
    Call<String> fotoReparacion(@Path("id") int id, @Part MultipartBody.Part imagen);

    //SOBRE NOSOTROS
    @GET("tienda")
    Call<String> tienda();

    @GET("tienda/fotos")
    Call<String> fotosTienda();
}
