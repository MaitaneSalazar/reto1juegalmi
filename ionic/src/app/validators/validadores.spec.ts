import { describe, it, expect } from 'vitest';
import { FormControl } from '@angular/forms';
import { dniValido, telefonoValido } from './validadores';

// Ayuda: ejecuta un validador sobre un valor y devuelve el error (o null si es válido)
const validar = (validador: typeof dniValido, valor: string) => validador(new FormControl(valor));

describe('Validador de DNI', () => {
  it('acepta un DNI con la letra correcta', () => {
    expect(validar(dniValido, '12345678Z')).toBeNull();
  });

  it('acepta minúsculas y espacios alrededor', () => {
    expect(validar(dniValido, ' 12345678z ')).toBeNull();
  });

  it('rechaza un DNI con la letra equivocada', () => {
    expect(validar(dniValido, '12345678A')).toEqual({ dni: true });
  });

  it('rechaza un DNI con menos de 8 números', () => {
    expect(validar(dniValido, '1234567Z')).toEqual({ dni: true });
  });

  it('no da error si está vacío (eso lo comprueba "required")', () => {
    expect(validar(dniValido, '')).toBeNull();
  });
});

describe('Validador de teléfono', () => {
  it('acepta un móvil de 9 cifras', () => {
    expect(validar(telefonoValido, '600111222')).toBeNull();
  });

  it('acepta un fijo y espacios entre cifras', () => {
    expect(validar(telefonoValido, '944 000 102')).toBeNull();
  });

  it('rechaza menos de 9 cifras', () => {
    expect(validar(telefonoValido, '60011122')).toEqual({ telefono: true });
  });

  it('rechaza si no empieza por 6, 7, 8 o 9', () => {
    expect(validar(telefonoValido, '500111222')).toEqual({ telefono: true });
  });
});
