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
    if nuevos:
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
