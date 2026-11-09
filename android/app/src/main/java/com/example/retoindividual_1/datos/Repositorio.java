package com.example.retoindividual_1.datos;

import android.content.Context;

import androidx.annotation.NonNull;
import androidx.lifecycle.DefaultLifecycleObserver;
import androidx.lifecycle.LifecycleOwner;

import com.example.retoindividual_1.R;
import com.example.retoindividual_1.modelos.Alquiler;
import com.example.retoindividual_1.modelos.Domicilio;
import com.example.retoindividual_1.modelos.FotoTienda;
import com.example.retoindividual_1.modelos.Pedido;
import com.example.retoindividual_1.modelos.Producto;
import com.example.retoindividual_1.modelos.Reparacion;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.io.File;
import java.util.ArrayList;
import java.util.List;

import okhttp3.MediaType;
import okhttp3.MultipartBody;
import okhttp3.RequestBody;
import okhttp3.ResponseBody;
import retrofit2.Call;
import retrofit2.Callback;
import retrofit2.Response;

//CAPA DE DATOS: LAS PANTALLAS PIDEN AQUI LO QUE NECESITAN Y RECIBEN MODELOS, NO JSON NI URLS.
//CADA PANTALLA CREA EL SUYO Y CUANDO SE CIERRA SE CANCELA SOLO LO QUE QUEDE EN CAMINO
public class Repositorio {

    //LO QUE RECIBE LA PANTALLA: LOS DATOS SI SALE BIEN O EL MENSAJE DE ERROR
    public interface Resultado<T> {
        void bien(T datos);

        void mal(String mensaje);

        //ERROR 422: LA API MANDA EN "campos" EL FALLO DE CADA CAMPO. SOLO LO USAN LOS FORMULARIOS
        default void campos(JSONObject campos) {
        }
    }

    //UNA PAGINA DE UN LISTADO Y CUANTAS PAGINAS HAY EN TOTAL
    public static class Pagina<T> {
        private final List<T> lista;
        private final int paginas;

        Pagina(List<T> lista, int paginas) {
            this.lista = lista;
            this.paginas = paginas;
        }

        public List<T> getLista() {
            return lista;
        }

        public int getPaginas() {
            return paginas;
        }
    }

    //PASA EL TEXTO DE LA RESPUESTA AL MODELO QUE TOCA
    private interface Lector<T> {
        T leer(String cuerpo) throws JSONException;
    }

    private final Context contexto;
    private final TiendaApi api;
    private final List<Call<String>> enCamino = new ArrayList<>();

    public Repositorio(Context context, LifecycleOwner dueno) {
        contexto = context.getApplicationContext();
        api = RetrofitClient.getApi(context);
        dueno.getLifecycle().addObserver(new DefaultLifecycleObserver() {
            @Override
            public void onDestroy(@NonNull LifecycleOwner owner) {
                for (Call<String> llamada : new ArrayList<>(enCamino)) {
                    llamada.cancel();
                }
                enCamino.clear();
            }
        });
    }

    //TIENDA

    //tipo O plataforma A null NO FILTRAN
    public Call<String> productos(String tipo, String plataforma, int pagina, int limite, Resultado<Pagina<Producto>> resultado) {
        return llamar(api.productos(tipo, plataforma, null, pagina, limite), LEER_PAGINA_PRODUCTOS, resultado);
    }

    public Call<String> alquilables(String plataforma, int pagina, int limite, Resultado<Pagina<Producto>> resultado) {
        return llamar(api.alquilables(plataforma, pagina, limite), LEER_PAGINA_PRODUCTOS, resultado);
    }

    public Call<String> buscar(String texto, int limite, Resultado<Pagina<Producto>> resultado) {
        return llamar(api.productos(null, null, texto, null, limite), LEER_PAGINA_PRODUCTOS, resultado);
    }

    public Call<String> producto(int id, Resultado<Producto> resultado) {
        return llamar(api.producto(id), new Lector<Producto>() {
            @Override
            public Producto leer(String cuerpo) throws JSONException {
                return new Producto(new JSONObject(cuerpo));
            }
        }, resultado);
    }

    //LAS PLATAFORMAS QUE SALEN EN COMPRAR VIDEOJUEGOS
    public Call<String> plataformasCompra(Resultado<List<String>> resultado) {
        return llamar(api.filtros(), new Lector<List<String>>() {
            @Override
            public List<String> leer(String cuerpo) throws JSONException {
                return textos(new JSONObject(cuerpo).optJSONArray("plataformas"));
            }
        }, resultado);
    }

    public Call<String> plataformasAlquiler(Resultado<List<String>> resultado) {
        return llamar(api.plataformasAlquiler(), new Lector<List<String>>() {
            @Override
            public List<String> leer(String cuerpo) throws JSONException {
                return textos(new JSONArray(cuerpo));
            }
        }, resultado);
    }

    //CESTA

    //LA API LAS MANDA EN UN ARRAY SIN PAGINAR, DE LA MAS NUEVA A LA MAS ANTIGUA
    public Call<String> domicilios(Resultado<List<Domicilio>> resultado) {
        return llamar(api.domicilios(), new Lector<List<Domicilio>>() {
            @Override
            public List<Domicilio> leer(String cuerpo) throws JSONException {
                JSONArray datos = new JSONArray(cuerpo);
                List<Domicilio> domicilios = new ArrayList<>();
                for (int i = 0; i < datos.length(); i++) {
                    domicilios.add(new Domicilio(datos.optJSONObject(i)));
                }
                return domicilios;
            }
        }, resultado);
    }

    public Call<String> crearPedido(JSONObject cuerpo, Resultado<JSONObject> resultado) {
        return llamar(api.crearPedido(cuerpo.toString()), LEER_OBJETO, resultado);
    }

    public Call<String> crearAlquiler(JSONObject cuerpo, Resultado<JSONObject> resultado) {
        return llamar(api.crearAlquiler(cuerpo.toString()), LEER_OBJETO, resultado);
    }

    //PEDIDOS

    public Call<String> pedidos(int limite, Resultado<List<Pedido>> resultado) {
        return llamar(api.pedidos(limite), new Lector<List<Pedido>>() {
            @Override
            public List<Pedido> leer(String cuerpo) throws JSONException {
                JSONArray datos = new JSONObject(cuerpo).optJSONArray("datos");
                List<Pedido> pedidos = new ArrayList<>();
                for (int i = 0; datos != null && i < datos.length(); i++) {
                    pedidos.add(new Pedido(datos.optJSONObject(i)));
                }
                return pedidos;
            }
        }, resultado);
    }

    //EL DETALLE TRAE TODAS LAS LINEAS, ASI EL PEDIDO SACA LAS FOTOS DE CADA PRODUCTO
    public Call<String> fotosPedido(Pedido pedido, Resultado<Pedido> resultado) {
        return llamar(api.pedido(pedido.getId()), new Lector<Pedido>() {
            @Override
            public Pedido leer(String cuerpo) throws JSONException {
                pedido.leerFotos(new JSONObject(cuerpo));
                return pedido;
            }
        }, resultado);
    }

    public Call<String> cancelarPedido(int id, Resultado<JSONObject> resultado) {
        return llamar(api.cancelarPedido(id), LEER_OBJETO, resultado);
    }

    //ALQUILERES

    public Call<String> alquileres(int limite, Resultado<List<Alquiler>> resultado) {
        return llamar(api.alquileres(limite), new Lector<List<Alquiler>>() {
            @Override
            public List<Alquiler> leer(String cuerpo) throws JSONException {
                JSONArray datos = new JSONObject(cuerpo).optJSONArray("datos");
                List<Alquiler> alquileres = new ArrayList<>();
                for (int i = 0; datos != null && i < datos.length(); i++) {
                    alquileres.add(new Alquiler(datos.optJSONObject(i)));
                }
                return alquileres;
            }
        }, resultado);
    }

    public Call<String> devolver(int id, Resultado<JSONObject> resultado) {
        return llamar(api.devolver(id), LEER_OBJETO, resultado);
    }

    //INICIO

    //DEL USUARIO SOLO SE USA EL NOMBRE
    public Call<String> nombreUsuario(Resultado<String> resultado) {
        return llamar(api.yo(), new Lector<String>() {
            @Override
            public String leer(String cuerpo) throws JSONException {
                return new JSONObject(cuerpo).optString("nombre");
            }
        }, resultado);
    }

    public Call<String> reparaciones(int limite, Resultado<List<Reparacion>> resultado) {
        return llamar(api.reparaciones(limite), new Lector<List<Reparacion>>() {
            @Override
            public List<Reparacion> leer(String cuerpo) throws JSONException {
                JSONArray datos = new JSONObject(cuerpo).optJSONArray("datos");
                List<Reparacion> reparaciones = new ArrayList<>();
                for (int i = 0; datos != null && i < datos.length(); i++) {
                    reparaciones.add(new Reparacion(datos.optJSONObject(i)));
                }
                return reparaciones;
            }
        }, resultado);
    }

    //SESION

    public Call<String> login(JSONObject cuerpo, Resultado<JSONObject> resultado) {
        return llamar(api.login(cuerpo.toString()), LEER_OBJETO, resultado);
    }

    public Call<String> registro(JSONObject cuerpo, Resultado<JSONObject> resultado) {
        return llamar(api.registro(cuerpo.toString()), LEER_OBJETO, resultado);
    }

    public Call<String> estado(Resultado<JSONObject> resultado) {
        return llamar(api.estado(), LEER_OBJETO, resultado);
    }

    //CUENTA

    //EL USUARIO ENTERO, PARA EL MENU Y LOS DATOS PERSONALES
    public Call<String> usuario(Resultado<JSONObject> resultado) {
        return llamar(api.yo(), LEER_OBJETO, resultado);
    }

    public Call<String> editarUsuario(JSONObject cambios, Resultado<JSONObject> resultado) {
        return llamar(api.editarYo(cambios.toString()), LEER_OBJETO, resultado);
    }

    public Call<String> subirFotoPerfil(File foto, Resultado<JSONObject> resultado) {
        return llamar(api.fotoPerfil(parteFoto(foto)), LEER_OBJETO, resultado);
    }

    public Call<String> crearDomicilio(JSONObject cuerpo, Resultado<JSONObject> resultado) {
        return llamar(api.crearDomicilio(cuerpo.toString()), LEER_OBJETO, resultado);
    }

    public Call<String> editarDomicilio(int id, JSONObject cuerpo, Resultado<JSONObject> resultado) {
        return llamar(api.editarDomicilio(id, cuerpo.toString()), LEER_OBJETO, resultado);
    }

    public Call<String> borrarDomicilio(int id, Resultado<JSONObject> resultado) {
        return llamar(api.borrarDomicilio(id), LEER_OBJETO, resultado);
    }

    //TALLER

    public Call<String> reparacion(int id, Resultado<JSONObject> resultado) {
        return llamar(api.reparacion(id), LEER_OBJETO, resultado);
    }

    public Call<String> crearReparacion(JSONObject cuerpo, Resultado<JSONObject> resultado) {
        return llamar(api.crearReparacion(cuerpo.toString()), LEER_OBJETO, resultado);
    }

    public Call<String> cancelarReparacion(int id, Resultado<JSONObject> resultado) {
        return llamar(api.cancelarReparacion(id), LEER_OBJETO, resultado);
    }

    public Call<String> subirFotoReparacion(int id, File foto, Resultado<JSONObject> resultado) {
        return llamar(api.fotoReparacion(id, parteFoto(foto)), LEER_OBJETO, resultado);
    }

    //SOBRE NOSOTROS

    public Call<String> tienda(Resultado<JSONObject> resultado) {
        return llamar(api.tienda(), LEER_OBJETO, resultado);
    }

    public Call<String> fotosTienda(Resultado<List<FotoTienda>> resultado) {
        return llamar(api.fotosTienda(), new Lector<List<FotoTienda>>() {
            @Override
            public List<FotoTienda> leer(String cuerpo) throws JSONException {
                JSONArray datos = new JSONArray(cuerpo);
                List<FotoTienda> fotos = new ArrayList<>();
                for (int i = 0; i < datos.length(); i++) {
                    fotos.add(new FotoTienda(datos.optJSONObject(i)));
                }
                return fotos;
            }
        }, resultado);
    }

    //LA FOTO VA EN multipart/form-data CON EL CAMPO "imagen", COMO LA ESPERA LA API
    private static MultipartBody.Part parteFoto(File foto) {
        return MultipartBody.Part.createFormData("imagen", foto.getName(),
                RequestBody.create(MediaType.parse("image/jpeg"), foto));
    }

    //LECTORES QUE SE REPITEN

    private static final Lector<Pagina<Producto>> LEER_PAGINA_PRODUCTOS = new Lector<Pagina<Producto>>() {
        @Override
        public Pagina<Producto> leer(String cuerpo) throws JSONException {
            JSONObject respuesta = new JSONObject(cuerpo);
            JSONArray datos = respuesta.optJSONArray("datos");
            List<Producto> productos = new ArrayList<>();
            for (int i = 0; datos != null && i < datos.length(); i++) {
                productos.add(new Producto(datos.optJSONObject(i)));
            }
            JSONObject paginacion = respuesta.optJSONObject("paginacion");
            return new Pagina<>(productos, paginacion != null ? paginacion.optInt("paginas", 1) : 1);
        }
    };

    //PARA LAS QUE SOLO HAY QUE SABER SI HAN SALIDO BIEN
    private static final Lector<JSONObject> LEER_OBJETO = new Lector<JSONObject>() {
        @Override
        public JSONObject leer(String cuerpo) throws JSONException {
            return cuerpo.trim().isEmpty() ? new JSONObject() : new JSONObject(cuerpo);
        }
    };

    private static List<String> textos(JSONArray lista) {
        List<String> textos = new ArrayList<>();
        for (int i = 0; lista != null && i < lista.length(); i++) {
            textos.add(lista.optString(i));
        }
        return textos;
    }

    //RETROFIT HACE LA PETICION EN SU HILO Y RESPONDE EN EL PRINCIPAL. SI SE HA CANCELADO NO SE AVISA A NADIE
    private <T> Call<String> llamar(Call<String> llamada, Lector<T> lector, Resultado<T> resultado) {
        enCamino.add(llamada);
        llamada.enqueue(new Callback<String>() {
            @Override
            public void onResponse(@NonNull Call<String> call, @NonNull Response<String> respuesta) {
                enCamino.remove(call);
                if (call.isCanceled()) {
                    return;
                }
                if (!respuesta.isSuccessful()) {
                    leerError(respuesta, resultado);
                    return;
                }
                T datos;
                try {
                    datos = lector.leer(respuesta.body() == null ? "" : respuesta.body());
                } catch (JSONException e) {
                    resultado.mal(contexto.getString(R.string.datos_respuesta_rara));
                    return;
                }
                resultado.bien(datos);
            }

            @Override
            public void onFailure(@NonNull Call<String> call, @NonNull Throwable error) {
                enCamino.remove(call);
                if (!call.isCanceled()) {
                    resultado.mal(contexto.getString(R.string.datos_sin_conexion));
                }
            }
        });
        return llamada;
    }

    //EL CAMPO "mensaje" DE LOS ERRORES DE LA API, SI NO VIENE SE ENSEÑA EL CODIGO. SI TRAE "campos" SE PASAN TAMBIEN
    private void leerError(Response<String> respuesta, Resultado<?> resultado) {
        String mensaje = "Error " + respuesta.code();
        try (ResponseBody cuerpo = respuesta.errorBody()) {
            if (cuerpo != null) {
                JSONObject error = new JSONObject(cuerpo.string());
                mensaje = error.optString("mensaje", mensaje);
                JSONObject campos = error.optJSONObject("campos");
                if (campos != null) {
                    resultado.campos(campos);
                }
            }
        } catch (Exception e) {
            //NO ES JSON
        }
        resultado.mal(mensaje);
    }
}
