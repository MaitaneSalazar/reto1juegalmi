import { describe, it, expect, beforeEach, vi } from 'vitest';
import { TestBed } from '@angular/core/testing';
import { ToastController } from '@ionic/angular';
import { VozService } from './voz.service';

describe('VozService (buscador por voz de la Tienda)', () => {
  let voz: VozService;
  const toast = { create: vi.fn().mockResolvedValue({ present: vi.fn() }) };

  beforeEach(() => {
    vi.clearAllMocks();
    TestBed.configureTestingModule({ providers: [{ provide: ToastController, useValue: toast }] });
    voz = TestBed.inject(VozService);
  });

  it('«Zelda» busca "zelda"', () => {
    expect(voz.textoBusqueda('Zelda')).toBe('zelda');
  });

  it('quita la palabra «buscar» del principio', () => {
    expect(voz.textoBusqueda('Buscar PlayStation 5')).toBe('playstation 5');
    expect(voz.textoBusqueda('busca Elden Ring')).toBe('elden ring');
  });

  it('quita los signos de la frase', () => {
    expect(voz.textoBusqueda('¿Mario Kart?')).toBe('mario kart');
  });

  it('una frase vacía no busca nada', () => {
    expect(voz.textoBusqueda('   ')).toBe('');
  });

  it('en un navegador sin voz avisa y devuelve ""', async () => {
    const w = window as unknown as Record<string, unknown>;
    delete w['SpeechRecognition'];
    delete w['webkitSpeechRecognition'];
    expect(await voz.escuchar()).toBe('');
    expect(toast.create).toHaveBeenCalled();
    expect(voz.escuchando()).toBe(false);
  });

  it('«Ir a la cesta» abre la cesta', () => {
    expect(voz.orden('Ir a la cesta')?.ruta).toBe('/cesta');
  });

  it('«Abre mis pedidos» y «mis alquileres» (con o sin tildes)', () => {
    expect(voz.orden('Abre mis pedidos')?.ruta).toBe('/cuenta/pedidos');
    expect(voz.orden('Mis alquileres')?.ruta).toBe('/cuenta/alquileres');
    expect(voz.orden('¿Dónde estáis?')?.ruta).toBe('/nosotros');
  });

  it('«Quiero alquilar» pasa la Tienda a modo alquiler', () => {
    expect(voz.orden('Quiero alquilar')).toMatchObject({ ruta: '/tienda', query: { modo: 'alquilar' } });
  });

  it('un nombre de producto o «buscar …» no es una orden: se busca', () => {
    expect(voz.orden('Zelda')).toBeNull();
    expect(voz.orden('Buscar cesta de regalo')).toBeNull();
  });
});
