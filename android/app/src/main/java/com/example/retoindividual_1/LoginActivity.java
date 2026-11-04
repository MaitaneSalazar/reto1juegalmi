package com.example.retoindividual_1;

import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.util.Patterns;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;
import android.widget.Toast;

import androidx.activity.EdgeToEdge;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;

import com.android.volley.Request;
import com.android.volley.toolbox.JsonObjectRequest;
import com.example.retoindividual_1.network.ApiClient;

/*
 * =====================================================================================
 *  PANTALLA DE LOGIN = Login1 del mockup de JuegAlmi.
 *  Es la primera pantalla que se abre (LAUNCHER en el Manifest).
 *
 *  Entrar        -> entrar()  -> comprueba email y contrasena -> MainActivity
 *  Crear cuenta  -> RegistroActivity
 *  Si algo falla, se ensena la caja roja de error (tvLoginError) con el motivo.
 *
 *  De momento NO hay base de datos: cualquier email valido con 6+ caracteres entra.
 * =====================================================================================
 */

public class LoginActivity extends AppCompatActivity {

    private EditText etEmail;
    private EditText etPassword;
    private TextView tvError;
    private Button btnEntrar;
    private TextView tvCrearCuenta;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);
        setContentView(R.layout.activity_login);
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main), (v, insets) -> {
            // ime() = el teclado, para que no tape el formulario
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars() | WindowInsetsCompat.Type.ime());
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
            return insets;
        });

        etEmail = findViewById(R.id.etLoginEmail);
        etPassword = findViewById(R.id.etLoginPassword);
        tvError = findViewById(R.id.tvLoginError);
        btnEntrar = findViewById(R.id.btnLoginEntrar);
        tvCrearCuenta = findViewById(R.id.tvLoginCrearCuenta);

        // ENTRAR -> valida y abre la app
        btnEntrar.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                entrar(etEmail.getText().toString().trim(), etPassword.getText().toString());
            }
        });

        // CREAR CUENTA -> pantalla de registro
        tvCrearCuenta.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                startActivity(new Intent(LoginActivity.this, RegistroActivity.class));
            }
        });

        probarConexion();
    }

    private void entrar(String email, String password) {
        if (email.isEmpty() || password.isEmpty()) {
            mostrarError(R.string.error_vacio);
        } else if (!Patterns.EMAIL_ADDRESS.matcher(email).matches()) {
            mostrarError(R.string.error_email);
        } else if (password.length() < 6) {
            mostrarError(R.string.error_password);
        } else {
            tvError.setVisibility(View.GONE);
            Intent intent = new Intent(LoginActivity.this, MainActivity.class);
            startActivity(intent);
            finish();   // para que el boton atras no vuelva al login
        }
    }

    // Caja roja con el motivo del error
    private void mostrarError(int texto) {
        tvError.setText(texto);
        tvError.setVisibility(View.VISIBLE);
    }

    private void probarConexion() {
        String url = ApiClient.BASE_URL + "estado";

        JsonObjectRequest peticion = new JsonObjectRequest(
                Request.Method.GET, url, null,
                respuesta -> {
                    Log.d("API", "Conectado: " + respuesta);
                    Toast.makeText(this, "API: " + respuesta.optString("estado"), Toast.LENGTH_LONG).show();
                },
                error -> {
                    String mensaje = ApiClient.mensajeDeError(error);
                    Log.e("API", "Error: " + mensaje, error);
                    Toast.makeText(this, mensaje, Toast.LENGTH_LONG).show();
                });

        ApiClient.getInstance(this).getCola().add(peticion);
    }
}
