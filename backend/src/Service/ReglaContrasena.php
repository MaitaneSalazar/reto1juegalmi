<?php

namespace App\Service;

/** Regla única de contraseñas: la usan la API (registro y cambio) y la web (trabajadores y ajustes) */
final class ReglaContrasena
{
    public const MENSAJE = 'La contraseña tiene que tener al menos 6 caracteres, una mayúscula y una minúscula.';
    public const PATRON = '/(?=.*\p{Ll})(?=.*\p{Lu})/u';

    public static function valida(string $contrasena): bool
    {
        return mb_strlen($contrasena) >= 6 && preg_match(self::PATRON, $contrasena) === 1;
    }
}
