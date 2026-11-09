#!/bin/bash
# =====================================================================
# PASO 23 · API de Aketza en AWS con HTTPS
#   - apiUrl → https://symfony.44-219-6-54.sslip.io/api (desarrollo y APK)
#   - Fuera los permisos de http que hacían falta con la VM (cleartext / androidScheme http)
#   Solo funciona con el Learner Lab encendido. Los tokens antiguos no valen: volver a entrar.
# Uso (desde la carpeta ionic/):   bash paso23-api-https.sh
# =====================================================================
set -e
if [ ! -f angular.json ] || [ ! -f src/environments/environment.ts ]; then
  echo "✘ Ejecútalo dentro de la carpeta ionic/"; exit 1
fi
mkdir -p ~/Escritorio/copias-ionic
tar czf ~/Escritorio/copias-ionic/ionic-antes-paso23.tgz src/environments permisos-nativos.py capacitor.config.ts 2>/dev/null || true

cat > src/environments/environment.ts <<'JUEGALMI_EOF'
// Configuración en desarrollo (ionic serve)
export const environment = {
  production: false,
  apiUrl: 'https://symfony.44-219-6-54.sslip.io/api',   // API de Aketza en AWS con HTTPS (Learner Lab encendido)
};
JUEGALMI_EOF

cat > src/environments/environment.prod.ts <<'JUEGALMI_EOF'
// Configuración en producción (APK / docker)
export const environment = {
  production: true,
  apiUrl: 'https://symfony.44-219-6-54.sslip.io/api',   // API de Aketza en AWS con HTTPS (Learner Lab encendido)
};
JUEGALMI_EOF

cat > permisos-nativos.py <<'JUEGALMI_EOF'
# Añade los permisos de cámara, ubicación, micrófono/voz y movimiento a Android e iOS (si las carpetas existen)
import os

manifest = 'android/app/src/main/AndroidManifest.xml'
if os.path.exists(manifest):
    xml = open(manifest, encoding='utf-8').read()
    permisos = ['android.permission.CAMERA', 'android.permission.ACCESS_COARSE_LOCATION',
                'android.permission.ACCESS_FINE_LOCATION', 'android.permission.INTERNET',
                'android.permission.RECORD_AUDIO']
    nuevos = ''.join(f'    <uses-permission android:name="{p}" />\n' for p in permisos if p not in xml)
    if 'android.hardware.location.gps' not in xml:
        nuevos += '    <uses-feature android:name="android.hardware.location.gps" android:required="false" />\n'
    # Android 11+: hay que declarar que la app abre el reconocedor de voz de Google
    if 'android.speech.action.RECOGNIZE_SPEECH' not in xml:
        nuevos += ('    <queries>\n        <intent>\n'
                   '            <action android:name="android.speech.action.RECOGNIZE_SPEECH" />\n'
                   '        </intent>\n    </queries>\n')
    # La API ya va por HTTPS (AWS): fuera el permiso de http que hacía falta con la VM
    http = 'usesCleartextTraffic' in xml
    if http:
        xml = xml.replace('\n        android:usesCleartextTraffic="true"', '').replace(' android:usesCleartextTraffic="true"', '')
    if nuevos or http:
        xml = xml.replace('</manifest>', nuevos + '</manifest>')
        open(manifest, 'w', encoding='utf-8').write(xml)
    print('✔ Permisos de Android revisados')

plist = 'ios/App/App/Info.plist'
if os.path.exists(plist):
    txt = open(plist, encoding='utf-8').read()
    claves = {
        'NSCameraUsageDescription': 'JuegAlmi usa la cámara para fotografiar el dispositivo que quieres reparar.',
        'NSPhotoLibraryUsageDescription': 'JuegAlmi necesita acceder a tus fotos para adjuntarlas a la reparación.',
        'NSPhotoLibraryAddUsageDescription': 'JuegAlmi guarda en tu galería las fotos que haces para el taller.',
        'NSLocationWhenInUseUsageDescription': 'JuegAlmi usa tu ubicación para mostrar la distancia a la tienda y registrar tus consultas.',
        'NSMicrophoneUsageDescription': 'JuegAlmi usa el micrófono para que controles la app por voz.',
        'NSSpeechRecognitionUsageDescription': 'JuegAlmi convierte tu voz en órdenes como «tienda» o «buscar Zelda».',
        'NSMotionUsageDescription': 'JuegAlmi detecta cuando agitas el móvil para recargar la pantalla.',
    }
    nuevas = ''.join(f'\t<key>{k}</key>\n\t<string>{v}</string>\n' for k, v in claves.items() if k not in txt)
    if nuevas:
        pos = txt.rfind('</dict>')
        txt = txt[:pos] + nuevas + txt[pos:]
        open(plist, 'w', encoding='utf-8').write(txt)
    print('✔ Permisos de iOS revisados')
JUEGALMI_EOF

# capacitor.config.ts: ya no hace falta permitir http
python3 - <<'JUEGALMI_PY'
import os
f = 'capacitor.config.ts'
if os.path.exists(f):
    lineas = open(f, encoding='utf-8').read().split('\n')
    nuevas = [l for l in lineas if "androidScheme: 'http'" not in l]
    if len(nuevas) != len(lineas):
        open(f, 'w', encoding='utf-8').write('\n'.join(nuevas))
        print('✔ capacitor.config.ts: quitado el permiso de http')
JUEGALMI_PY
if [ -d android ]; then python3 permisos-nativos.py; fi

echo ""
echo "✔ Paso 23 aplicado: la app usa la API de AWS con HTTPS."
echo "  1) ionic serve → cierra sesión y vuelve a entrar con demo@juegalmi.es / 1234"
echo "  2) APK nueva: bash generar-apk.sh"
