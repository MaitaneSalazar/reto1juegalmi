import { Injectable, computed, signal } from '@angular/core';
import { LineaCesta } from '../models/pedido.model';
import { Producto } from '../models/producto.model';

const CLAVE = 'juegalmi_cesta';   // clave en localStorage

@Injectable({ providedIn: 'root' })
export class CestaService {
  // Estado de la cesta (signal: la barra inferior y la pantalla Cesta se actualizan solas)
  readonly lineas = signal<LineaCesta[]>(this.leer());

  readonly unidades = computed(() => this.lineas().reduce((s, l) => s + l.cantidad, 0));               // badge
  readonly total = computed(() => +this.lineas().reduce((s, l) => s + l.producto.precio_venta * l.cantidad, 0).toFixed(2));

  // Añade un producto (si ya está, suma cantidad)
  anadir(producto: Producto, cantidad = 1): void {
    const lista = this.lineas();
    const existe = lista.find(l => l.producto.id === producto.id);
    this.guardar(existe
      ? lista.map(l => l.producto.id === producto.id ? { ...l, cantidad: l.cantidad + cantidad } : l)
      : [...lista, { producto, cantidad }]);
  }

  // Botones − y + de la cesta (si llega a 0 se quita)
  cambiarCantidad(productoId: number, cambio: number): void {
    this.guardar(this.lineas()
      .map(l => l.producto.id === productoId ? { ...l, cantidad: l.cantidad + cambio } : l)
      .filter(l => l.cantidad > 0));
  }

  quitar(productoId: number): void {
    this.guardar(this.lineas().filter(l => l.producto.id !== productoId));
  }

  vaciar(): void {
    this.guardar([]);
  }

  // Actualiza el signal y lo guarda en localStorage (la cesta sobrevive al cerrar la app)
  private guardar(lista: LineaCesta[]): void {
    this.lineas.set(lista);
    try { localStorage.setItem(CLAVE, JSON.stringify(lista)); } catch { /* sin almacenamiento */ }
  }

  private leer(): LineaCesta[] {
    try { return JSON.parse(localStorage.getItem(CLAVE) ?? '[]'); } catch { return []; }
  }
}
