import { AbstractControl, ValidationErrors, ValidatorFn } from '@angular/forms';

// DNI: 8 números + letra correcta (12345678Z)
export const dniValido: ValidatorFn = (c: AbstractControl): ValidationErrors | null => {
  const valor = String(c.value ?? '').trim().toUpperCase();
  if (!valor) return null;                                   // el "required" se comprueba aparte
  if (!/^\d{8}[A-Z]$/.test(valor)) return { dni: true };
  const letras = 'TRWAGMYFPDXBNJZSQVHLCKE';
  return letras[Number(valor.slice(0, 8)) % 23] === valor[8] ? null : { dni: true };
};

// Teléfono español: 9 cifras empezando por 6, 7, 8 o 9
export const telefonoValido: ValidatorFn = (c: AbstractControl): ValidationErrors | null => {
  const valor = String(c.value ?? '').replace(/\s/g, '');
  if (!valor) return null;
  return /^[6789]\d{8}$/.test(valor) ? null : { telefono: true };
};
