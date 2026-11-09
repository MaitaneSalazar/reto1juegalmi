package com.example.retoindividual_1.sesion;

import com.example.retoindividual_1.R;
import com.example.retoindividual_1.principal.MainActivity;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.util.Patterns;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageButton;
import android.widget.TextView;

import androidx.activity.EdgeToEdge;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;

import com.example.retoindividual_1.datos.Repositorio;
import com.example.retoindividual_1.network.SessionManager;

import org.json.JSONException;
import org.json.JSONObject;

import java.util.Locale;
import java.util.Random;

public class RegistroActivity extends AppCompatActivity {

    private Repositorio datos;

    private static final String LETRAS_DNI = "TRWAGMYFPDXBNJZSQVHLCKE";

    private EditText etNombre;
    private EditText etApellido1;
    private EditText etApellido2;
    private EditText etDni;
    private EditText etTelefono;
    private EditText etEmail;
    private EditText etPassword;
    private TextView tvError;
    private ImageButton btnDniAleatorio;
    private Button btnRegistrarme;
    private TextView tvTengoCuenta;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_registro);
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main), (v, insets) -> {
            //CON ime() EL TECLADO NO TAPA EL FORMULARIO
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars() | WindowInsetsCompat.Type.ime());
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
            return insets;
        });

        etNombre = findViewById(R.id.etRegistroNombre);
        etApellido1 = findViewById(R.id.etRegistroApellido1);
        etApellido2 = findViewById(R.id.etRegistroApellido2);
        etDni = findViewById(R.id.etRegistroDni);
        etTelefono = findViewById(R.id.etRegistroTelefono);
        etEmail = findViewById(R.id.etRegistroEmail);
        etPassword = findViewById(R.id.etRegistroPassword);
        tvError = findViewById(R.id.tvRegistroError);
        btnDniAleatorio = findViewById(R.id.btnRegistroDniAleatorio);
        btnRegistrarme = findViewById(R.id.btnRegistrarme);
        tvTengoCuenta = findViewById(R.id.tvRegistroTengoCuenta);

        //AL PULSAR EL DADO SE RELLENA EL DNI CON UNO NUEVO
        btnDniAleatorio.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                etDni.setText(dniAleatorio());
                etDni.setSelection(etDni.length());
            }
        });

        btnRegistrarme.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                registrar();
            }
        });

        //VOLVEMOS AL LOGIN, QUE SIGUE DEBAJO
        tvTengoCuenta.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                finish();
            }
        });
    }

    private void registrar() {
        String nombre = etNombre.getText().toString().trim();
        String apellido1 = etApellido1.getText().toString().trim();
        String dni = etDni.getText().toString().trim().toUpperCase();
        String telefono = etTelefono.getText().toString().trim();
        String email = etEmail.getText().toString().trim();
        String password = etPassword.getText().toString();

        //EL SEGUNDO APELLIDO NO ES OBLIGATORIO
        if (nombre.isEmpty() || apellido1.isEmpty() || dni.isEmpty()
                || telefono.isEmpty() || email.isEmpty() || password.isEmpty()) {
            mostrarError(R.string.error_registro_vacio);
        } else if (!dniValido(dni)) {
            mostrarError(R.string.error_dni);
        } else if (!telefono.matches("\\d{9}")) {
            mostrarError(R.string.error_telefono);
        } else if (!Patterns.EMAIL_ADDRESS.matcher(email).matches()) {
            mostrarError(R.string.error_email);
        } else if (password.length() < 4) {
            mostrarError(R.string.error_password);
        } else {
            tvError.setVisibility(View.GONE);
            enviarRegistro(nombre, apellido1, etApellido2.getText().toString().trim(), dni, telefono, email, password);
        }
    }

    //MANDAMOS LOS DATOS A LA API Y SI VA BIEN ENTRAMOS CON EL TOKEN QUE DEVUELVE
    private void enviarRegistro(String nombre, String apellido1, String apellido2, String dni,
                                String telefono, String email, String password) {
        JSONObject cuerpo = new JSONObject();
        try {
            cuerpo.put("nombre", nombre);
            cuerpo.put("apellido1", apellido1);
            cuerpo.put("apellido2", apellido2);
            cuerpo.put("dni", dni);
            cuerpo.put("telefono", telefono);
            cuerpo.put("email", email);
            cuerpo.put("password", password);
        } catch (JSONException e) {
            return;
        }

        //DESACTIVAMOS EL BOTON PARA QUE NO SE MANDE DOS VECES
        btnRegistrarme.setEnabled(false);

        datos().registro(cuerpo, new Repositorio.Resultado<JSONObject>() {
            @Override
            public void bien(JSONObject respuesta) {
                Log.d("REGISTRO", "RESPUESTA " + respuesta.toString());
                new SessionManager(RegistroActivity.this).guardarToken(respuesta.optString("token"));
                Intent intent = new Intent(RegistroActivity.this, MainActivity.class);
                intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
                startActivity(intent);
            }

            @Override
            public void mal(String mensaje) {
                btnRegistrarme.setEnabled(true);
                Log.e("REGISTRO", mensaje);
                tvError.setText(mensaje);
                tvError.setVisibility(View.VISIBLE);
            }
        });
    }

    //SACAMOS 8 NUMEROS AL AZAR Y LE PONEMOS SU LETRA PARA QUE SEA VALIDO
    private String dniAleatorio() {
        int numero = new Random().nextInt(100000000);
        return String.format(Locale.ROOT, "%08d", numero) + LETRAS_DNI.charAt(numero % 23);
    }

    //LA LETRA DEL DNI ES EL RESTO DE DIVIDIR EL NUMERO ENTRE 23
    private boolean dniValido(String dni) {
        if (!dni.matches("\\d{8}[A-Z]")) {
            return false;
        }
        int numero = Integer.parseInt(dni.substring(0, 8));
        return dni.charAt(8) == LETRAS_DNI.charAt(numero % 23);
    }

    private void mostrarError(int texto) {
        tvError.setText(texto);
        tvError.setVisibility(View.VISIBLE);
    }

    //CAPA DE DATOS, SE CREA LA PRIMERA VEZ QUE SE USA
    private Repositorio datos() {
        if (datos == null) {
            datos = new Repositorio(this, this);
        }
        return datos;
    }
}
