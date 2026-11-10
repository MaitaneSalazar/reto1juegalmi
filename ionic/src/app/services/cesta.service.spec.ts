import { describe, it, expect, beforeEach } from 'vitest';
import { TestBed } from '@angular/core/testing';
import { CestaService } from './cesta.service';
import { Producto } from '../models/producto.model';

// Productos de prueba (solo los campos que usa la cesta)
const zelda = { id: 1, tipo: 'videojuego', nombre: 'Zelda', precio_venta: 59.99, stock: 2 } as Producto;
const ps5 = { id: 4, tipo: 'consola', nombre: 'PS5 Slim', precio_venta: 499.99, stock: 5 } as Producto;

describe('CestaService', () => {
  let cesta: CestaService;

  beforeEach(() => {
    localStorage.clear();                        // cada prueba empieza con la cesta vacía
    TestBed.configureTestingModule({});
    cesta = TestBed.inject(CestaService);
  });

  it('empieza vacía', () => {
    expect(cesta.lineas()).toEqual([]);
    expect(cesta.unidades()).toBe(0);
    expect(cesta.total()).toBe(0);
  });

  it('añade productos y calcula unidades y total', () => {
    cesta.anadir(zelda);
    cesta.anadir(ps5, 2);
    expect(cesta.unidades()).toBe(3);
    expect(cesta.total()).toBe(1059.97);        // 59,99 + 2 × 499,99
  });

  it('si el producto ya está, suma la cantidad en la misma línea', () => {
    cesta.anadir(zelda);
    cesta.anadir(zelda);
    expect(cesta.lineas().length).toBe(1);
    expect(cesta.lineas()[0].cantidad).toBe(2);
  });

  it('quita la línea cuando la cantidad llega a 0', () => {
    cesta.anadir(zelda);
    cesta.cambiarCantidad(cesta.lineas()[0], -1);
    expect(cesta.lineas()).toEqual([]);
  });

  it('guarda la cesta en localStorage (sobrevive al cerrar la app)', () => {
    cesta.anadir(ps5);
    const guardada = JSON.parse(localStorage.getItem('juegalmi_cesta') ?? '[]');
    expect(guardada[0].producto.id).toBe(4);
  });

  it('vaciar deja la cesta a 0', () => {
    cesta.anadir(zelda);
    cesta.vaciar();
    expect(cesta.unidades()).toBe(0);
  });
  it('no deja añadir más unidades que el stock', () => {
    expect(cesta.anadir(zelda, 2)).toBe(true);
    expect(cesta.anadir(zelda)).toBe(false);          // Zelda tiene stock 2
    expect(cesta.unidades()).toBe(2);
    expect(cesta.cambiarCantidad(cesta.lineas()[0], 1)).toBe(false);
  });

  it('alquiler: línea aparte con sus días y precio por días', () => {
    const juego = { ...zelda, precio_alquiler_dia: 1.5, copias_disponibles: 1 } as Producto;
    cesta.anadir(juego);
    expect(cesta.anadir(juego, 1, true, 3)).toBe(true);
    expect(cesta.lineas().length).toBe(2);
    expect(cesta.precio(cesta.lineas()[1])).toBe(4.5);
    expect(cesta.anadir(juego, 1, true, 5)).toBe(false);     // solo queda 1 copia libre
  });
});
