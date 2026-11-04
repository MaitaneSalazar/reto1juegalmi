import { describe, it, expect } from 'vitest';
import { EurosPipe } from './euros.pipe';

describe('EurosPipe', () => {
  const pipe = new EurosPipe();

  it('formatea en euros con coma decimal', () => {
    expect(pipe.transform(59.99)).toContain('59,99');
    expect(pipe.transform(59.99)).toContain('€');
  });

  it('devuelve texto vacío si no hay valor', () => {
    expect(pipe.transform(null)).toBe('');
    expect(pipe.transform(undefined)).toBe('');
  });
});
