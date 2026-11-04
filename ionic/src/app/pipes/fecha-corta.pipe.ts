import { Pipe, PipeTransform } from '@angular/core';

const formato = new Intl.DateTimeFormat('es-ES', { day: 'numeric', month: 'short' });

@Pipe({ name: 'fechaCorta' })
export class FechaCortaPipe implements PipeTransform {
  transform(valor: string | null | undefined): string {
    if (!valor) return '';
    return formato.format(new Date(valor.slice(0, 10) + 'T00:00:00')).replace('.', '');   // "3 nov"
  }
}
