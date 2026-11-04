// Configuración en desarrollo (ionic serve)
export const environment = {
  production: false,
  apiUrl: 'http://localhost:8000/api',   // URL de la API de la app (cambiar cuando la pase Aketza)
  usarDatosEjemplo: true,                 // true = JSON de assets/data · false = API real
  retardoEjemploMs: 400,                  // espera simulada de red con los datos de ejemplo
};
