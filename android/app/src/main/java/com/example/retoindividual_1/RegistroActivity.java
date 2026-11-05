package com.example.retoindividual_1;

import android.content.Intent;
import android.os.Bundle;
import android.util.Patterns;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.TextView;

import androidx.activity.EdgeToEdge;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;

public class RegistroActivity extends AppCompatActivity {

    private static final String LETRAS_DNI = "TRWAGMYFPDXBNJZSQVHLCKE";

    private EditText etNombre;
    private EditText etApellido1;
    private EditText etApellido2;
    private EditText etDni;
    private EditText etTelefono;
    private EditText etEmail;
    private EditText etPassword;
    private TextView tvError;
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
        btnRegistrarme = findViewById(R.id.btnRegistrarme);
        tvTengoCuenta = findViewById(R.id.tvRegistroTengoCuenta);

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
            //DE MOMENTO SE ENTRA DIRECTAMENTE, FALTA CONECTARLO CON LA API
            Intent intent = new Intent(RegistroActivity.this, MainActivity.class);
            intent.setFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
            startActivity(intent);
        }
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
}
