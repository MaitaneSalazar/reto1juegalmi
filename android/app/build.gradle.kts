plugins {
    alias(libs.plugins.android.application)
}

android {
    namespace = "com.example.retoindividual_1"
    compileSdk {
        version = release(37)
    }

    defaultConfig {
        applicationId = "com.example.retoindividual_1"
        minSdk = 24
        targetSdk = 37
        versionCode = 1
        versionName = "1.0"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
    }

    buildFeatures {
        buildConfig = true
    }

    buildTypes {
        debug {
            // API local en la VM de Ubuntu (cambia la IP por la de tu VM)
            buildConfigField("String", "API_URL", "\"http://192.168.2.74:8000/api/\"")
        }
        release {
            optimization {
                enable = false
            }
            // API en AWS (se cambiará cuando tengáis el dominio)
            buildConfigField("String", "API_URL", "\"https://api.vuestrodominio.com/api/\"")
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
}

dependencies {
    implementation(libs.activity.ktx)
    implementation(libs.appcompat)
    implementation(libs.material)
    implementation(libs.activity)
    implementation(libs.constraintlayout)
    implementation("com.android.volley:volley:1.2.1")
    implementation("org.osmdroid:osmdroid-android:6.1.20")
    implementation("com.google.android.gms:play-services-location:21.3.0")
    implementation(libs.glide) //PARA CARGAR LAS IMAGENES POR URL
    implementation(libs.retrofit) //SEGUNDA LIBRERIA DE RED, LA USA EL BUSCADOR
    implementation(libs.retrofit.scalars)
    testImplementation(libs.junit)
    androidTestImplementation(libs.ext.junit)
    androidTestImplementation(libs.espresso.core)
}