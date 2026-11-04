import { Injectable, inject } from '@angular/core';
import { Observable, map } from 'rxjs';
import { FUENTE_DATOS } from '../factories/fuente-datos.factory';
import { Producto, TipoProducto } from '../models/producto.model';

// Filtros del catálogo
export interface FiltroProductos {
  tipo?: TipoProducto;
  alquilable?: boolean;
  plataforma?: string;
  page?: number;
  limit?: number;
}

@Injectable({ providedIn: 'root' })
export class ProductoService {
  private fuente = inject(FUENTE_DATOS);

  // Catálogo (Tienda · Comprar)
  listar(filtros: FiltroProductos = {}): Observable<Producto[]> {
    return this.fuente.listar<Producto>('productos', { ...filtros });
  }

  // Solo videojuegos alquilables (Tienda · Alquilar)
  alquilables(plataforma?: string): Observable<Producto[]> {
    return this.listar({ alquilable: true, plataforma });
  }

  // Buscador: filtra por nombre o marca sin distinguir mayúsculas
  buscar(texto: string, filtros: FiltroProductos = {}): Observable<Producto[]> {
    const t = texto.trim().toLowerCase();
    return this.listar(filtros).pipe(
      map(lista => lista.filter(p => !t || p.nombre.toLowerCase().includes(t) || p.marca.toLowerCase().includes(t))),
    );
  }

  // Ficha de un producto
  obtener(id: number): Observable<Producto> {
    return this.fuente.obtener<Producto>('productos', id);
  }
}
