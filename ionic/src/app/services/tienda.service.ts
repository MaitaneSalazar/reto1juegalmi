import { Injectable, inject } from '@angular/core';
import { Observable, shareReplay } from 'rxjs';
import { FUENTE_DATOS } from '../factories/fuente-datos.factory';
import { Tienda } from '../models/tienda.model';

@Injectable({ providedIn: 'root' })
export class TiendaService {
  private fuente = inject(FUENTE_DATOS);

  // Se pide una vez y se reutiliza en las 3 pestañas de Nosotros
  private tienda$ = this.fuente.obtener<Tienda>('tienda').pipe(shareReplay(1));

  obtener(): Observable<Tienda> {
    return this.tienda$;
  }
}
