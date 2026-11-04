import { describe, it, expect, beforeEach, vi } from 'vitest';
import { TestBed } from '@angular/core/testing';
import { Router } from '@angular/router';
import { ToastController } from '@ionic/angular';
import { VozService } from './voz.service';
import { SesionService } from './sesion.service';

describe('VozService (órdenes de voz)', () => {
  let voz: VozService;
  // Dobles de prueba: comprobamos A DÓNDE navega sin cambiar de pantalla de verdad
  const router = { navigate: vi.fn(), navigateByUrl: vi.fn() };
  const sesion = { cerrar: vi.fn() };
  const toast = { create: vi.fn().mockResolvedValue({ present: vi.fn() }) };

  beforeEach(() => {
    vi.clearAllMocks();
    TestBed.configureTestingModule({
      providers: [
        { provide: Router, useValue: router },
        { provide: SesionService, useValue: sesion },
        { provide: ToastController, useValue: toast },
      ],
    });
    voz = TestBed.inject(VozService);
  });

  it('«Buscar Zelda» abre la Tienda buscando "zelda"', () => {
    expect(voz.ejecutar('Buscar Zelda')).toBe(true);
    expect(router.navigate).toHaveBeenCalledWith(['/tienda'], { queryParams: { modo: 'comprar', buscar: 'zelda' } });
  });

  it('«abre la cesta» va a la Cesta', () => {
    voz.ejecutar('abre la cesta');
    expect(router.navigateByUrl).toHaveBeenCalledWith('/cesta');
  });

  it('«quiero alquilar» abre la Tienda en modo Alquilar', () => {
    voz.ejecutar('quiero alquilar');
    expect(router.navigate).toHaveBeenCalledWith(['/tienda'], { queryParams: { modo: 'alquilar' } });
  });

  it('«mis alquileres» no se confunde con «alquilar»', () => {
    voz.ejecutar('mis alquileres');
    expect(router.navigateByUrl).toHaveBeenCalledWith('/cuenta/alquileres');
  });

  it('«¿Dónde está la tienda?» va a Sobre nosotros (ignora tildes y signos)', () => {
    voz.ejecutar('¿Dónde está la tienda?');
    expect(router.navigateByUrl).toHaveBeenCalledWith('/nosotros');
  });

  it('«cerrar sesión» cierra la sesión y vuelve al login', () => {
    voz.ejecutar('cerrar sesión');
    expect(sesion.cerrar).toHaveBeenCalled();
    expect(router.navigateByUrl).toHaveBeenCalledWith('/login', { replaceUrl: true });
  });

  it('una frase sin orden no navega y avisa al usuario', () => {
    expect(voz.ejecutar('hola qué tal')).toBe(false);
    expect(router.navigate).not.toHaveBeenCalled();
    expect(router.navigateByUrl).not.toHaveBeenCalled();
    expect(toast.create).toHaveBeenCalled();
  });
});
