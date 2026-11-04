#!/bin/bash
# Genera JuegAlmi.apk (Android) desde la app Ionic.  Uso: bash generar-apk.sh
set -e
export ANDROID_HOME=${ANDROID_HOME:-$HOME/Android/Sdk}
if [ ! -d "$ANDROID_HOME" ]; then
  echo "✘ No se encuentra el SDK de Android en $ANDROID_HOME. Abre Android Studio una vez (asistente Standard) y repite."
  exit 1
fi

CAP=$(node -p "require('@capacitor/core/package.json').version")
npm install "@capacitor/android@$CAP"            # plataforma Android (misma versión que Capacitor)

npx ng build --configuration production           # 1. compilar la web
[ -d android ] || npx cap add android             # 2. crear el proyecto Android (solo la primera vez)
python3 permisos-nativos.py                       # 3. permisos de cámara y ubicación
npx cap sync android                              # 4. copiar la web y los plugins al proyecto Android

cd android && chmod +x gradlew && ./gradlew assembleDebug   # 5. compilar la APK
cp app/build/outputs/apk/debug/app-debug.apk ../JuegAlmi.apk
echo "✔ APK generada: $(cd .. && pwd)/JuegAlmi.apk"
