# Pruebas unitarias · JuegAlmi Ionic

Herramienta: **Vitest** con el builder oficial de Angular (`@angular/build:unit-test`) y **jsdom** como navegador simulado.

```bash
cd ionic
npx ng test --watch=false     # una pasada (para la documentación / CI)
npx ng test                   # modo vigilancia: repite al guardar
```

| Archivo | Qué se prueba | Casos |
|---|---|---|
| `validators/validadores.spec.ts` | DNI (letra correcta/incorrecta, formato, vacío) y teléfono (9 cifras, empieza por 6-9, espacios) | 9 |
| `services/cesta.service.spec.ts` | Cesta: vacía, añadir, sumar cantidad, quitar al llegar a 0, total, guardado en localStorage, vaciar | 6 |
| `components/precio/precio.component.spec.ts` | Precio con céntimos pequeños: 59,99 €, 35,00 €, punto de miles, sufijo "/ día" | 4 |
| `services/voz.service.spec.ts` | Control por voz: buscar, cesta, alquilar, mis alquileres, dónde está la tienda, cerrar sesión, frase desconocida | 7 |
| `pipes/euros.pipe.spec.ts` | Formato en euros y valor vacío | 2 |
| **Total** | | **28** |

Técnicas usadas:
- **TestBed** de Angular para crear servicios y componentes como en la app.
- **Dobles de prueba** (`vi.fn()`) para el `Router`, la sesión y los avisos: se comprueba *a dónde* navegaría la app sin cambiar de pantalla.
- `localStorage.clear()` antes de cada prueba para que no dependan unas de otras.

Resultado esperado: `Test Files 5 passed (5) · Tests 28 passed (28)`.

Pruebas manuales en dispositivo (no automatizables aquí): cámara, GPS, voz real y agitar el móvil → ver checklist de la defensa.
