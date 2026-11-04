// Configuración en producción (ionic build --prod / APK)
export const environment = {
  production: true,
  apiUrl: 'https://CAMBIAR-POR-LA-URL-DE-AWS/api', // URL HTTPS de la API en AWS (iOS no permite HTTP)
  usarDatosEjemplo: true,                           // poner a false cuando la API esté lista
  retardoEjemploMs: 0,
};
