# JuegAlmi · App híbrida (Ionic) — Proceso de build

App híbrida con **Ionic 9 + Angular + Capacitor**. Un único código genera la app de **iOS**, la de **Android** (APK) y una **PWA**.

## 1. Configuración de la API
Archivo `src/environments/environment.ts` (desarrollo) y `environment.prod.ts` (APK / iOS / Docker):
- `apiUrl`: URL de la API de la app (en producción **HTTPS**, obligatorio en iOS).
- `usarDatosEjemplo`: `true` = datos de `src/assets/data/*.json`; `false` = API real.

Todas las peticiones a la API pasan por `interceptors/api.interceptor.ts`, que añade:
- `Authorization: Bearer <token JWT>` (si hay sesión).
- `X-Lat` y `X-Lon` con la ubicación del usuario (en cualquier consulta, también sin sesión).
Si la API responde **401**, se cierra la sesión y se vuelve al login.

## 2. Desarrollo
```bash
npm install
ionic serve            # http://localhost:8100  (F12 → vista de iPhone)
```

## 3. APK de Android
Requisitos: Java 21 y SDK de Android (Android Studio).
```bash
bash generar-apk.sh    # genera JuegAlmi.apk
```
Pasos que hace: `ng build` → `npx cap add android` (1.ª vez) → permisos → `npx cap sync android` → `./gradlew assembleDebug`.
Instalación: copiar `JuegAlmi.apk` al móvil y abrirla (permitir "orígenes desconocidos"), o `adb install JuegAlmi.apk`.

## 4. iOS
**Compilar para iPhone exige un Mac con Xcode** (limitación de Apple).
```bash
npm install @capacitor/ios
npx ng build --configuration production
npx cap add ios        # 1.ª vez (se puede hacer en Linux; crea la carpeta ios/)
python3 permisos-nativos.py
npx cap sync ios
npx cap open ios       # en el Mac: abre Xcode
```
En Xcode: *Signing & Capabilities* → elegir equipo (Apple ID gratuito) → seleccionar el iPhone → ▶ Run.

Permisos que se añaden a `ios/App/App/Info.plist`: cámara, galería y ubicación (`NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSPhotoLibraryAddUsageDescription`, `NSLocationWhenInUseUsageDescription`). Sin ellos iOS cierra la app al usar la cámara o el GPS.

La API debe permitir el origen `capacitor://localhost` en CORS.

**Sin Mac (alternativa para la demo):** la PWA en el iPhone (apartado 5) o el navegador con vista de iPhone.

## 5. PWA / Docker
```bash
docker build -t juegalmi-ionic .
docker run -p 8080:80 juegalmi-ionic     # http://localhost:8080
```
En el iPhone (Safari) → Compartir → **Añadir a pantalla de inicio**: se abre como una app a pantalla completa.

## 6. Decisiones (anexo de cambios)
- **Windows Phone** está descontinuado: el objetivo de la híbrida es **iOS** (y PWA).
- **Modo `md`** forzado: misma apariencia Material en iOS y Android (idéntica a la app nativa).
- **Mapa con Leaflet + OpenStreetMap** en lugar de Google Maps: sin API key ni facturación.
- **Factory (`useFactory`)** `FUENTE_DATOS`: misma app con datos de ejemplo o con la API real.
- **Almacenamiento**: sesión, cesta y preferencias en localStorage; borrador del registro en sessionStorage.
- **Imagen provisional** mientras cargan las fotos o si fallan.
- **Animaciones**: transiciones de Ionic, entrada en cascada de listas, rebote del contador de la cesta (`AnimationController`), respuesta táctil; se desactivan si el sistema pide reducir movimiento.
