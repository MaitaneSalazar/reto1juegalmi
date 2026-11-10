import { Injectable, computed, signal } from '@angular/core';
import { LineaCesta } from '../models/pedido.model';
import { Producto } from '../models/producto.model';

const CLAVE = 'juegalmi_cesta';   // clave en localStorage

@Injectable({ providedIn: 'root' })
export class CestaService {
  // Estado de la cesta (signal: la barra inferior y la pantalla Cesta se actualizan solas)
  readonly lineas = signal<LineaCesta[]>(this.leer());

  readonly unidades = computed(() => this.lineas().reduce((s, l) => s + l.cantidad, 0));               // badge
  readonly total = computed(() => +this.lineas().reduce((s, l) => s + this.precio(l) * l.cantidad, 0).toFixed(2));

  // Precio de una unidad: el de venta, o el del día por los días (igual que Cesta.Linea.getPrecio() en Android)
  precio(l: LineaCesta): number {
    return l.alquiler ? (l.producto.precio_alquiler_dia ?? 0) * (l.dias ?? 0) : l.producto.precio_venta;
  }

  // Comprando manda el stock; alquilando, las copias libres
  limite(p: Producto, alquiler: boolean): number {
    return alquiler ? (p.copias_disponibles ?? 0) : p.stock;
  }

  // Cuántas hay ya de ese producto en la cesta, en ese modo
  enCesta(id: number, alquiler = false): number {
    return this.lineas().filter(l => l.producto.id === id && !!l.alquiler === alquiler).reduce((s, l) => s + l.cantidad, 0);
  }

  // Añade (si ya está la misma línea, suma). false = se pasaría del stock / de las copias
  anadir(producto: Producto, cantidad = 1, alquiler = false, dias = 0): boolean {
    if (this.enCesta(producto.id, alquiler) + cantidad > this.limite(producto, alquiler)) return false;
    const misma = (l: LineaCesta) => l.producto.id === producto.id && !!l.alquiler === alquiler && (l.dias ?? 0) === (alquiler ? dias : 0);
    const lista = this.lineas();
    this.guardar(lista.some(misma)
      ? lista.map(l => misma(l) ? { ...l, cantidad: l.cantidad + cantidad } : l)
      : [...lista, { producto, cantidad, alquiler, dias: alquiler ? dias : 0 }]);
    return true;
  }

  // Botones − y + de la cesta (si llega a 0 se quita). false = se pasaría del límite
  cambiarCantidad(linea: LineaCesta, cambio: number): boolean {
    if (cambio > 0 && this.enCesta(linea.producto.id, !!linea.alquiler) + cambio > this.limite(linea.producto, !!linea.alquiler)) return false;
    this.guardar(this.lineas()
      .map(l => l === linea ? { ...l, cantidad: l.cantidad + cambio } : l)
      .filter(l => l.cantidad > 0));
    return true;
  }

  quitar(linea: LineaCesta): void {
    this.guardar(this.lineas().filter(l => l !== linea));
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
