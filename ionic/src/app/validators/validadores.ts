import { AbstractControl, ValidationErrors, ValidatorFn } from '@angular/forms';

const LETRAS = 'TRWAGMYFPDXBNJZSQVHLCKE';

// DNI (12345678Z) o NIE (X1234567L) con la letra correcta, como pide la API
export const dniValido: ValidatorFn = (c: AbstractControl): ValidationErrors | null => {
  const valor = String(c.value ?? '').trim().toUpperCase();
  if (!valor) return null;                                   // el "required" se comprueba aparte
  if (!/^[XYZ\d]\d{7}[A-Z]$/.test(valor)) return { dni: true };
  const numero = valor.slice(0, 8).replace('X', '0').replace('Y', '1').replace('Z', '2');   // NIE → número
  return LETRAS[Number(numero) % 23] === valor[8] ? null : { dni: true };
};

// Teléfono español: 9 cifras empezando por 6, 7, 8 o 9
export const telefonoValido: ValidatorFn = (c: AbstractControl): ValidationErrors | null => {
  const valor = String(c.value ?? '').replace(/\s/g, '');
  if (!valor) return null;
  return /^[6789]\d{8}$/.test(valor) ? null : { telefono: true };
};
