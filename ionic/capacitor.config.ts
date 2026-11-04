import type { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.juegalmi.app',
  appName: 'JuegAlmi',
  webDir: 'www',
  server: { androidScheme: 'http', cleartext: true },   // API por http en desarrollo (quitar con HTTPS)
};

export default config;
