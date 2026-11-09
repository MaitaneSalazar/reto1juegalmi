# Control por voz y acelerómetro (JuegAlmi · Ionic)

## Micrófono (en la Tienda, junto a la lupa)
Pulsa el micrófono y habla. Si lo que dices es una **orden**, la app cambia de pantalla; si no, **busca** ese texto en la Tienda.

### Órdenes (con o sin «ir a», «abre», tildes…)
| Di… | Abre |
|---|---|
| «Ir a la cesta», «carrito» | Cesta |
| «Mis pedidos» | Mis pedidos |
| «Mis alquileres» | Mis alquileres |
| «Mis reparaciones» | Taller › Mis reparaciones |
| «Taller», «quiero reparar» | Taller (nueva reparación) |
| «Quiero alquilar» / «Comprar» | Tienda en modo Alquilar / Comprar |
| «Dónde estáis», «horario», «nosotros» | Sobre nosotros |
| «Mis datos», «perfil» | Datos personales |
| «Direcciones» | Direcciones |
| «Inicio» | Inicio |

### Búsqueda
| Di… | Busca |
|---|---|
| «Zelda» | zelda |
| «Buscar PlayStation 5» | playstation 5 («buscar …» siempre busca, nunca es una orden) |

- Al reconocer una orden sale el aviso «🎤 Abriendo …». Mientras escucha, el micrófono se pone turquesa y late; a los 8 s sin oír nada se cierra.
- Móvil: reconocedor del sistema (plugin `@capacitor-community/speech-recognition`). Navegador: Web Speech API (Chrome, Edge, Safari; **Firefox no la tiene**).

## Acelerómetro
- `@capacitor/motion`: agitar el móvil recarga la pantalla actual. La sesión y la cesta se conservan.
