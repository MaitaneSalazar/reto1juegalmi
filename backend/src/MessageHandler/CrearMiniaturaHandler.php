<?php

namespace App\MessageHandler;

use App\Message\CrearMiniatura;
use Psr\Log\LoggerInterface;
use Symfony\Component\DependencyInjection\Attribute\Autowire;
use Symfony\Component\Messenger\Attribute\AsMessageHandler;

/**
 * Se ejecuta en el WORKER, un proceso distinto del servidor de la API.
 * Reduce la foto a 400 px de ancho como máximo para que los listados carguen rápido.
 */
#[AsMessageHandler]
final class CrearMiniaturaHandler
{
    private const ANCHO_MAXIMO = 400;

    public function __construct(
        #[Autowire('%kernel.project_dir%')] private string $directorioProyecto,
        private LoggerInterface $logger,
    ) {
    }

    public function __invoke(CrearMiniatura $mensaje): void
    {
        $origen = $this->directorioProyecto . '/public' . $mensaje->ruta;
        $destino = $this->directorioProyecto . '/public' . CrearMiniatura::rutaMiniatura($mensaje->ruta);

        if (!is_file($origen)) {
            $this->logger->warning('Miniatura: no existe la foto ' . $mensaje->ruta);

            return;
        }

        $imagen = imagecreatefromstring(file_get_contents($origen));
        if ($imagen === false) {
            $this->logger->warning('Miniatura: no se pudo leer la foto ' . $mensaje->ruta);

            return;
        }

        $ancho = imagesx($imagen);
        $alto = imagesy($imagen);
        $escala = min(1, self::ANCHO_MAXIMO / $ancho);
        $nuevoAncho = (int) round($ancho * $escala);
        $nuevoAlto = (int) round($alto * $escala);

        $miniatura = imagecreatetruecolor($nuevoAncho, $nuevoAlto);
        imagealphablending($miniatura, false);
        imagesavealpha($miniatura, true);       // conserva la transparencia de los PNG
        imagecopyresampled($miniatura, $imagen, 0, 0, 0, 0, $nuevoAncho, $nuevoAlto, $ancho, $alto);

        match (strtolower(pathinfo($origen, PATHINFO_EXTENSION))) {
            'png' => imagepng($miniatura, $destino, 6),
            'webp' => imagewebp($miniatura, $destino, 80),
            default => imagejpeg($miniatura, $destino, 80),
        };

        $this->logger->info(sprintf(
            'Miniatura creada por el proceso %d: %s (%d KB -> %d KB)',
            getmypid(),
            $mensaje->ruta,
            (int) (filesize($origen) / 1024),
            (int) (filesize($destino) / 1024),
        ));
    }
}
