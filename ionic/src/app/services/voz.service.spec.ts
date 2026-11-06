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
});
