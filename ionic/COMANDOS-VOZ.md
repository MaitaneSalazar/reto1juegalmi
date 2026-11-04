# Control por voz y acelerómetro (JuegAlmi · Ionic)

Pulsa el **micrófono** de la cabecera y di una orden en español:

| Di… | Hace |
|---|---|
| «inicio» | Pantalla de inicio |
| «tienda», «comprar» | Tienda en modo Comprar |
| «alquilar» | Tienda en modo Alquilar |
| «buscar *zelda*» | Busca ese producto en la Tienda |
| «taller», «pedir reparación» | Nueva reparación |
| «mis reparaciones» | Seguimiento de reparaciones |
| «cesta», «carrito» | Cesta |
| «dónde está la tienda», «horario» | Sobre nosotros |
| «cuenta», «perfil» | Cuenta |
| «mis pedidos» / «mis alquileres» | Historial |
| «datos personales», «dirección», «ajustes», «ayuda» | Subpáginas de Cuenta |
| «cerrar sesión» | Sale de la cuenta |

- En el móvil usa el reconocedor de voz del sistema (plugin `@capacitor-community/speech-recognition`).
- En el navegador usa la Web Speech API (Chrome, Edge, Safari; **Firefox no la tiene**).
- **Acelerómetro** (`@capacitor/motion`): agitar el móvil recarga la pantalla actual. La sesión y la cesta se conservan.
