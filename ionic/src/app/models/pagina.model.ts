// Respuesta de los listados paginados de la API: ?page=1&limit=20
export interface Pagina<T> {
  datos: T[];
  paginacion: { pagina: number; por_pagina: number; total: number; paginas: number };
}

// Algunos listados podrían venir sin paginar: devuelve siempre el array
export function soloDatos<T>(r: T[] | Pagina<T>): T[] {
  return Array.isArray(r) ? r : r.datos;
}
