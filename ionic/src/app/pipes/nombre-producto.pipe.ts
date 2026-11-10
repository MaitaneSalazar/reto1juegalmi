import { Pipe, PipeTransform } from '@angular/core';
import { nombrePlataforma } from '../models/producto.model';

// "Minecraft" + plataforma → "Minecraft · Xbox" (un juego viene una vez por cada plataforma)
export function nombreProducto(p: { nombre: string; plataforma?: string | null } | null | undefined): string {
  if (!p) return '';
  return p.plataforma ? `${p.nombre} · ${nombrePlataforma(p.plataforma)}` : p.nombre;
}

@Pipe({ name: 'nombreProducto' })
export class NombreProductoPipe implements PipeTransform {
  transform(p: { nombre: string; plataforma?: string | null } | null | undefined): string {
    return nombreProducto(p);
  }
}
