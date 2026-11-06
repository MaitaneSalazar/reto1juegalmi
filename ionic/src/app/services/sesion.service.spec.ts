import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { TestBed } from '@angular/core/testing';
import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { SesionService } from './sesion.service';
import { environment } from '../../environments/environment';

describe('SesionService · foto de perfil', () => {
  let sesion: SesionService;
  let http: HttpTestingController;

  beforeEach(() => {
    localStorage.clear();
    TestBed.configureTestingModule({ providers: [provideHttpClient(), provideHttpClientTesting()] });
    sesion = TestBed.inject(SesionService);
    http = TestBed.inject(HttpTestingController);
  });

  afterEach(() => http.verify());   // no queda ninguna petición sin comprobar

  it('sube la foto por POST /api/yo/foto con el campo «imagen»', () => {
    sesion.subirFoto(new Blob(['x'], { type: 'image/jpeg' }), 'perfil.jpg').subscribe();
    const pet = http.expectOne(`${environment.apiUrl}/yo/foto`);
    expect(pet.request.method).toBe('POST');
    expect((pet.request.body as FormData).get('imagen')).toBeInstanceOf(Blob);
    pet.flush({ id: 2, tipo: 'cliente', nombre: 'Ane', apellido1: 'Etxeberria', dni: '12345678Z', email: 'demo@juegalmi.es',
                foto_perfil_url: 'http://192.168.2.74:8000/uploads/perfil/2.jpg' });
  });
});
