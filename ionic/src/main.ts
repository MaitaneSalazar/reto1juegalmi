import { bootstrapApplication } from '@angular/platform-browser';
import { RouteReuseStrategy, provideRouter, withPreloading, PreloadAllModules } from '@angular/router';
import { provideHttpClient, withInterceptors } from '@angular/common/http';
import { IonicRouteStrategy, provideIonicAngular } from '@ionic/angular';
import { defineCustomElements } from '@ionic/pwa-elements/loader';
import { routes } from './app/app.routes';
import { AppComponent } from './app/app.component';
import { apiInterceptor } from './app/interceptors/api.interceptor';

bootstrapApplication(AppComponent, {
  providers: [
    { provide: RouteReuseStrategy, useClass: IonicRouteStrategy },  // mantiene las páginas en memoria al navegar
    provideIonicAngular({ mode: 'md' }),                            // mismo aspecto en iOS y Android
    provideRouter(routes, withPreloading(PreloadAllModules)),       // rutas con precarga
    provideHttpClient(withInterceptors([apiInterceptor])),          // HTTP + token y GPS en cada petición
  ],
});

defineCustomElements(window);   // ventana de cámara web cuando la app corre en el navegador
