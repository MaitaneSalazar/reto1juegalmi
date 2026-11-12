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
import android.widget.TextView;
import android.widget.Toast;

import androidx.activity.EdgeToEdge;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.graphics.Insets;
import androidx.core.view.ViewCompat;
import androidx.core.view.WindowInsetsCompat;

import com.example.retoindividual_1.datos.Repositorio;
import com.example.retoindividual_1.network.SessionManager;

import org.json.JSONException;
import org.json.JSONObject;

//PANTALLA DE LOGIN, SE ABRE DESPUES DE LA PANTALLA DE CARGA

public class LoginActivity extends AppCompatActivity {

    private Repositorio datos;

    private EditText etEmail;
    private EditText etPassword;
    private TextView tvError;
    private Button btnEntrar;
    private TextView tvCrearCuenta;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        EdgeToEdge.enable(this);
        //EL TOKEN DURA 7 DIAS: SI YA HAY SESION, SE SALTA EL LOGIN
        if (new SessionManager(this).haySesion()) {
            startActivity(new Intent(this, MainActivity.class));
            finish();
            return;
        }
        setContentView(R.layout.activity_login);
        ViewCompat.setOnApplyWindowInsetsListener(findViewById(R.id.main), (v, insets) -> {
            //CON ime() EL TECLADO NO TAPA EL FORMULARIO
            Insets systemBars = insets.getInsets(WindowInsetsCompat.Type.systemBars() | WindowInsetsCompat.Type.ime());
            v.setPadding(systemBars.left, systemBars.top, systemBars.right, systemBars.bottom);
            return insets;
        });

        etEmail = findViewById(R.id.etLoginEmail);
        etPassword = findViewById(R.id.etLoginPassword);
        tvError = findViewById(R.id.tvLoginError);
        btnEntrar = findViewById(R.id.btnLoginEntrar);
        tvCrearCuenta = findViewById(R.id.tvLoginCrearCuenta);

        //BOTON ENTRAR
        btnEntrar.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                entrar(etEmail.getText().toString().trim(), etPassword.getText().toString());
            }
        });

        //CREAR CUENTA ABRE EL REGISTRO
        tvCrearCuenta.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                startActivity(new Intent(LoginActivity.this, RegistroActivity.class));
            }
        });
    }

    private void entrar(String email, String password) {
        if (email.isEmpty() || password.isEmpty()) {
            mostrarError(R.string.error_vacio);
        } else if (!Patterns.EMAIL_ADDRESS.matcher(email).matches()) {
            mostrarError(R.string.error_email);
        } else if (password.length() < 3) {
            mostrarError(R.string.error_password);
        } else {
            tvError.setVisibility(View.GONE);
            //LE PREGUNTAMOS A LA API SI EL EMAIL Y LA CONTRASEÑA SON CORRECTOS
            JSONObject cuerpo = new JSONObject();
            try {
                cuerpo.put("email", email);
                cuerpo.put("password", password);
            } catch (JSONException e) {
                return;
            }
            //DESACTIVAMOS EL BOTON PARA QUE NO SE MANDE DOS VECES
            btnEntrar.setEnabled(false);
            datos().login(cuerpo, new Repositorio.Resultado<JSONObject>() {
                @Override
                public void bien(JSONObject respuesta) {
                    new SessionManager(LoginActivity.this).guardarToken(respuesta.optString("token"));
                    startActivity(new Intent(LoginActivity.this, MainActivity.class));
                    finish(); //PARA QUE ATRAS NO VUELVA AL LOGIN
                }

                @Override
                public void mal(String mensaje) {
                    btnEntrar.setEnabled(true);
                    mostrarError(mensaje);
                }
            });
        }
    }

    //CAJA ROJA CON EL ERROR
    private void mostrarError(int texto) {
        mostrarError(getString(texto));
    }

    private void mostrarError(String texto) {
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
