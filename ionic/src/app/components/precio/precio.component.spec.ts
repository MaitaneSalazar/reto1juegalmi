import { describe, it, expect } from 'vitest';
import { TestBed } from '@angular/core/testing';
import { PrecioComponent } from './precio.component';

// Pinta el componente con un valor y devuelve el texto que ve el usuario
function pintar(valor: number, sufijo = ''): string {
  const fixture = TestBed.createComponent(PrecioComponent);
  fixture.componentRef.setInput('valor', valor);
  fixture.componentRef.setInput('sufijo', sufijo);
  fixture.detectChanges();
  return (fixture.nativeElement as HTMLElement).textContent?.replace(/\s+/g, ' ').trim() ?? '';
}

describe('PrecioComponent', () => {
  it('separa euros y céntimos: 59,99 €', () => {
    expect(pintar(59.99)).toBe('59,99 €');
  });

  it('rellena los céntimos: 35 → 35,00 €', () => {
    expect(pintar(35)).toBe('35,00 €');
  });

  it('pone punto de miles: 12345,6 → 12.345,60 €', () => {
    expect(pintar(12345.6)).toBe('12.345,60 €');
  });

  it('muestra el sufijo del alquiler', () => {
    expect(pintar(1.5, '/ día')).toBe('1,50 €/ día');
  });
});
