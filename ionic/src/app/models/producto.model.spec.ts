import { describe, it, expect } from 'vitest';
import { Producto, avisoStock, colorPlataforma, etiquetaStock, plataformasDe } from './producto.model';

describe('Etiqueta de stock', () => {
  it('3 o más: sin etiqueta', () => {
    expect(etiquetaStock(3)).toBeNull();
  });

  it('2: «Quedan 2» en rojo', () => {
    expect(etiquetaStock(2)).toEqual({ texto: 'Quedan 2', tipo: 'aviso' });
  });

  it('1: «Última unidad» (en alquiler, «Última copia»)', () => {
    expect(etiquetaStock(1)?.texto).toBe('Última unidad');
    expect(etiquetaStock(1, true)?.texto).toBe('Última copia');
  });

  it('0: «Agotado» (en alquiler, «Alquilado»)', () => {
    expect(etiquetaStock(0)).toEqual({ texto: 'Agotado', tipo: 'off' });
    expect(etiquetaStock(0, true)?.texto).toBe('Alquilado');
  });
});

describe('Plataformas de un juego', () => {
  it('«Multi» (antiguo) se juega en las tres', () => {
    expect(plataformasDe({ plataforma: 'Multi' })).toEqual(['PlayStation', 'Xbox', 'Switch']);
  });

  it('una sola plataforma', () => {
    expect(plataformasDe({ plataforma: 'Xbox' })).toEqual(['Xbox']);
  });

  it('si la API manda una lista (p. ej. dos plataformas) se usa tal cual', () => {
    expect(plataformasDe({ plataforma: 'Multi', plataformas: ['PS5', 'Xbox'] })).toEqual(['PS5', 'Xbox']);
  });
});

describe('Color de cada plataforma', () => {
  it('PlayStation en azul, la escriba como la escriba', () => {
    for (const pl of ['PlayStation', 'PS5', 'ps5', 'PlayStation 5']) expect(colorPlataforma(pl)).toBe('#0070d1');
  });

  it('Xbox en verde y Switch en rojo', () => {
    expect(colorPlataforma('Xbox Series X')).toBe('#107c10');
    expect(colorPlataforma('Nintendo Switch')).toBe('#e60012');
  });
});

describe('avisoStock (la misma regla que Android)', () => {
  const p = (stock: number, extra = {}) => ({ id: 1, tipo: 'videojuego', nombre: 'Zelda', stock, disponible: true, ...extra }) as unknown as Producto;

  it('comprar: Agotado si no hay stock o no está disponible', () => {
    expect(avisoStock(p(0), false)).toEqual({ texto: 'Agotado', agotado: true });
    expect(avisoStock(p(5, { disponible: false }), false)?.agotado).toBe(true);
  });

  it('alquilar: usa las copias libres', () => {
    expect(avisoStock(p(9, { copias_disponibles: 1 }), true)).toEqual({ texto: 'Última copia', agotado: false });
    expect(avisoStock(p(9, { copias_disponibles: 0 }), true)?.texto).toBe('Alquilado');
  });

  it('alquilar: sin stock tampoco se alquila aunque haya copias', () => {
    expect(avisoStock(p(0, { copias_disponibles: 3 }), true)).toEqual({ texto: 'Agotado', agotado: true });
  });
});
