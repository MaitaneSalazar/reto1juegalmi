# Pruebas unitarias · JuegAlmi Ionic

Herramienta: **Vitest** con el builder oficial de Angular (`@angular/build:unit-test`) y **jsdom** como navegador simulado.

```bash
cd ionic
npx ng test --watch=false     # una pasada (para la documentación / CI)
npx ng test                   # modo vigilancia: repite al guardar
```

| Archivo | Qué se prueba | Casos |
|---|---|---|
| `validators/validadores.spec.ts` | DNI y NIE (letra correcta/incorrecta, formato, vacío), teléfono (9 cifras, empieza por 6-9, espacios) y mensajes de error de Android | 12 |
| `services/cesta.service.spec.ts` | Cesta: vacía, añadir, sumar cantidad, quitar al llegar a 0, total, guardado en localStorage, vaciar, límite de stock | 7 |
| `models/producto.model.spec.ts` | Etiquetas de stock («Quedan 2», «Última unidad/copia», «Agotado/Alquilado») plataformas de cada juego y su color (PlayStation azul, Xbox verde, Switch rojo) y `avisoStock` (misma regla que Android) | 11 |
| `services/sesion.service.spec.ts` | Foto de perfil: `POST /api/yo/foto` con el campo «imagen» (HTTP simulado) | 1 |
| `components/precio/precio.component.spec.ts` | Precio con céntimos pequeños: 59,99 €, 35,00 €, punto de miles, sufijo "/ día" | 4 |
| `services/voz.service.spec.ts` | Voz de la Tienda: texto a buscar, órdenes («ir a la cesta», «mis pedidos», «quiero alquilar»), «buscar …» siempre busca, navegador sin voz | 9 |
| `pipes/euros.pipe.spec.ts` | Formato en euros y valor vacío | 2 |
| **Total** | | **46** |

Técnicas usadas:
- **TestBed** de Angular para crear servicios y componentes como en la app.
- **Dobles de prueba** (`vi.fn()`) para los avisos (`ToastController`): se comprueba que la app avisa sin mostrar nada en pantalla.
- `localStorage.clear()` antes de cada prueba para que no dependan unas de otras.

Resultado esperado: `Test Files 7 passed (7) · Tests 46 passed (46)`.

Pruebas manuales en dispositivo (no automatizables aquí): cámara, GPS, voz real y agitar el móvil → ver checklist de la defensa.
