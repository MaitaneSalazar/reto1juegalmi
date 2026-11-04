import { Pipe, PipeTransform } from '@angular/core';

// Formato de moneda español
const formato = new Intl.NumberFormat('es-ES', { style: 'currency', currency: 'EUR' });

@Pipe({ name: 'euros' })
export class EurosPipe implements PipeTransform {
  transform(valor: number | null | undefined): string {
    return valor === null || valor === undefined ? '' : formato.format(valor);
  }
}
