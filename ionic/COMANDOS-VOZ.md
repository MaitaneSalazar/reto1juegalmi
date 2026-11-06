# Buscador por voz y acelerómetro (JuegAlmi · Ionic)

## Buscador por voz (solo en la Tienda)
En **Tienda** pulsa el **micrófono** (junto a la lupa) y di lo que buscas:

| Di… | Busca |
|---|---|
| «Zelda» | zelda |
| «Buscar PlayStation 5» | playstation 5 (se quita la palabra «buscar») |
| «¿Elden Ring?» | elden ring (se quitan los signos) |

- Lo dicho se escribe en el buscador y se piden los productos a la API (`GET /api/productos?q=...`). En modo Alquilar filtra los juegos de alquiler.
- Mientras escucha, el micrófono se pone turquesa y late. Si no oye nada en 8 segundos, se cierra solo.
- En el móvil usa el reconocedor de voz del sistema (plugin `@capacitor-community/speech-recognition`, ventana «¿Qué buscas?»).
- En el navegador usa la Web Speech API (Chrome, Edge, Safari; **Firefox no la tiene**).

## Acelerómetro
- `@capacitor/motion`: agitar el móvil recarga la pantalla actual. La sesión y la cesta se conservan.
