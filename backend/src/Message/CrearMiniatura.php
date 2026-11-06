<?php

namespace App\Message;

/**
 * Aviso que deja la API en la cola cuando se sube una foto:
 * «hay que hacer la miniatura de esta imagen». Lo procesa el worker.
 */
final class CrearMiniatura
{
    public function __construct(public readonly string $ruta)
    {
    }

    /** /uploads/soporte/abc.png -> /uploads/soporte/abc_mini.png */
    public static function rutaMiniatura(string $ruta): string
    {
        $info = pathinfo($ruta);

        return $info['dirname'] . '/' . $info['filename'] . '_mini.' . ($info['extension'] ?? 'jpg');
    }
}
