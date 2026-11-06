#!/bin/bash
# =====================================================================
# PASO 19b · Etiqueta de PlayStation en azul
#   El color se elige por el nombre, como venga de la API: "PS5", "PS4", "PlayStation 5"... → azul
#   "Xbox..." → verde · "Switch" / "Nintendo..." → rojo
# Uso (desde la carpeta ionic/):   bash paso19b-playstation-azul.sh
# =====================================================================
set -e
if [ ! -f angular.json ] || [ ! -f src/app/components/plataformas/plataformas.component.ts ]; then
  echo "✘ Ejecútalo dentro de ionic/ y con el paso 19 aplicado"; exit 1
fi
tar czf ../ionic-src-antes-paso19b.tgz src PRUEBAS.md

mkdir -p $(dirname src/app/components/plataformas/plataformas.component.ts)
cat > src/app/components/plataformas/plataformas.component.ts <<'JUEGALMI_EOF'
import { Component, computed, input } from '@angular/core';
import { colorPlataforma, plataformasDe } from '../../models/producto.model';

// Píldoras de color con las plataformas de un juego: Xbox (verde), PS5 (azul), Switch (rojo)
@Component({
  selector: 'app-plataformas',
  template: `
    @for (pl of lista(); track pl) {
      <span class="pildora" [style.background]="color(pl)">{{ pl }}</span>
    }
  `,
  styles: [`
    :host { display: flex; flex-wrap: wrap; gap: 6px; }
    :host(.columna) { flex-direction: column; align-items: flex-end; gap: 4px; }   /* en las tarjetas, una debajo de otra */
    .pildora {
      padding: 4px 10px; border-radius: 999px;
      color: #ffffff; font-size: 11px; font-weight: 700; line-height: 1.2;
      box-shadow: 0 2px 6px rgba(0, 0, 0, .15);
    }
    :host(.grande) .pildora { padding: 6px 14px; font-size: 13px; box-shadow: none; }
  `],
})
export class PlataformasComponent {
  producto = input.required<{ plataforma?: string | null; plataformas?: string[] }>();
  lista = computed(() => plataformasDe(this.producto()));
  color(pl: string): string { return colorPlataforma(pl); }
}
JUEGALMI_EOF

mkdir -p $(dirname src/app/models/producto.model.spec.ts)
cat > src/app/models/producto.model.spec.ts <<'JUEGALMI_EOF'
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
JUEGALMI_EOF

mkdir -p $(dirname src/app/models/producto.model.ts)
cat > src/app/models/producto.model.ts <<'JUEGALMI_EOF'
// Producto tal como lo devuelve la API (tarjeta del listado + datos de la ficha)
export type TipoProducto = 'videojuego' | 'consola' | 'movil' | 'tablet';

export interface Producto {
  id: number;
  tipo: TipoProducto;
  nombre: string;
  empresa: string;               // Nintendo, Sony...
  precio_venta: number;
  stock: number;
  disponible: boolean;
  imagen_url: string | null;     // null → imagen provisional
  miniatura_url?: string | null; // ~400 px, para listados
  plataforma?: string;           // videojuegos
  precio_alquiler_dia?: number | null;
  alquilado?: boolean;           // listado de alquiler: no queda copia libre
  // Ficha (GET /api/productos/{id})
  descripcion?: string;
  genero?: string;
  pegi?: number;
  copias_alquiler?: number;
  copias_disponibles?: number;
  almacenamiento_gb?: number;
  color?: string;
  edicion?: string;
  pantalla_pulgadas?: number;
  ram_gb?: number;
  sistema_operativo?: string;
  bateria_mah?: number;
  conectividad?: string;
}

// Texto de cada tipo
export const NOMBRE_TIPO: Record<TipoProducto, string> = {
  videojuego: 'Videojuego',
  consola: 'Consola',
  movil: 'Móvil',
  tablet: 'Tablet',
};

// Color de la portada generada (cuando la API manda imagen_url: null)
export const COLOR_PLATAFORMA: Record<string, string> = {
  PS5: '#375e60', Xbox: '#5c616c', Switch: '#5ea0a2', Multi: '#8a8c84',
};
export const COLOR_PORTADA = '#1f2329';          // consolas, móviles, tablets y sin plataforma

// Plataformas en las que se juega: "Multi" = las tres (si algún día la API manda una lista, se usa tal cual)
export const PLATAFORMAS = ['PS5', 'Xbox', 'Switch'] as const;
export function plataformasDe(p: { plataforma?: string | null; plataformas?: string[] }): string[] {
  if (p.plataformas?.length) return p.plataformas;
  if (!p.plataforma) return [];
  return p.plataforma.trim().toLowerCase() === 'multi' ? [...PLATAFORMAS] : [p.plataforma.trim()];
}
// Xbox verde · PlayStation azul · Switch rojo. Se reconoce como venga escrito
// ("PS5", "PS4", "PlayStation 5", "ps5", "Nintendo Switch", "Xbox Series"...)
export function colorPlataforma(plataforma: string): string {
  const t = plataforma.toLowerCase();
  if (t.includes('xbox')) return '#107c10';                              // verde
  if (t.includes('ps') || t.includes('playstation')) return '#0070d1';   // azul
  if (t.includes('switch') || t.includes('nintendo')) return '#e60012';  // rojo
  return '#5c616c';                                                      // otra: gris
}

// Etiqueta de stock: «Quedan 2», «Última unidad», «Agotado» (en alquiler: «Última copia», «Alquilado»)
export interface EtiquetaStock { texto: string; tipo: 'aviso' | 'off'; }
export function etiquetaStock(n: number, alquiler = false): EtiquetaStock | null {
  if (n <= 0) return { texto: alquiler ? 'Alquilado' : 'Agotado', tipo: 'off' };
  if (n === 1) return { texto: alquiler ? 'Última copia' : 'Última unidad', tipo: 'aviso' };
  if (n === 2) return { texto: 'Quedan 2', tipo: 'aviso' };
  return null;                                   // 3 o más: sin etiqueta
}

// Un videojuego se puede alquilar si tiene precio por día
export function esAlquilable(p: Producto): boolean {
  return p.tipo === 'videojuego' && p.precio_alquiler_dia != null;
}
JUEGALMI_EOF

mkdir -p $(dirname PRUEBAS.md)
cat > PRUEBAS.md <<'JUEGALMI_EOF'
# Pruebas unitarias · JuegAlmi Ionic

Herramienta: **Vitest** con el builder oficial de Angular (`@angular/build:unit-test`) y **jsdom** como navegador simulado.

```bash
cd ionic
npx ng test --watch=false     # una pasada (para la documentación / CI)
npx ng test                   # modo vigilancia: repite al guardar
```

| Archivo | Qué se prueba | Casos |
|---|---|---|
| `validators/validadores.spec.ts` | DNI y NIE (letra correcta/incorrecta, formato, vacío) y teléfono (9 cifras, empieza por 6-9, espacios) | 11 |
| `services/cesta.service.spec.ts` | Cesta: vacía, añadir, sumar cantidad, quitar al llegar a 0, total, guardado en localStorage, vaciar, límite de stock | 7 |
| `models/producto.model.spec.ts` | Etiquetas de stock («Quedan 2», «Última unidad/copia», «Agotado/Alquilado») plataformas de cada juego («Multi» = las tres) y su color | 9 |
| `components/precio/precio.component.spec.ts` | Precio con céntimos pequeños: 59,99 €, 35,00 €, punto de miles, sufijo "/ día" | 4 |
| `services/voz.service.spec.ts` | Buscador por voz de la Tienda: texto a buscar, quitar «buscar» y signos, frase vacía, navegador sin voz | 5 |
| `pipes/euros.pipe.spec.ts` | Formato en euros y valor vacío | 2 |
| **Total** | | **38** |

Técnicas usadas:
- **TestBed** de Angular para crear servicios y componentes como en la app.
- **Dobles de prueba** (`vi.fn()`) para los avisos (`ToastController`): se comprueba que la app avisa sin mostrar nada en pantalla.
- `localStorage.clear()` antes de cada prueba para que no dependan unas de otras.

Resultado esperado: `Test Files 6 passed (6) · Tests 38 passed (38)`.

Pruebas manuales en dispositivo (no automatizables aquí): cámara, GPS, voz real y agitar el móvil → ver checklist de la defensa.
JUEGALMI_EOF

grep -rl "@ionic/angular/standalone" src | xargs -r sed -i "s#@ionic/angular/standalone#@ionic/angular#g"

echo ""
echo "✔ Paso 19b aplicado: PlayStation en azul, Xbox en verde y Switch en rojo (los escriba como los escriba la API)."
echo "  Prueba: npx ng test --watch=false   y   ionic serve"
