import { describe, it, expect } from 'vitest';
import { colorPlataforma, etiquetaStock, plataformasDe } from './producto.model';

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
  it('«Multi» se juega en PS5, Xbox y Switch', () => {
    expect(plataformasDe({ plataforma: 'Multi' })).toEqual(['PS5', 'Xbox', 'Switch']);
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
    for (const pl of ['PS5', 'ps5', 'PS4', 'PlayStation 5']) expect(colorPlataforma(pl)).toBe('#0070d1');
  });

  it('Xbox en verde y Switch en rojo', () => {
    expect(colorPlataforma('Xbox Series X')).toBe('#107c10');
    expect(colorPlataforma('Nintendo Switch')).toBe('#e60012');
  });
});
