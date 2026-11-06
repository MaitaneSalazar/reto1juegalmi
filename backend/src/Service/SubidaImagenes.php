<?php

namespace App\Service;

use App\Message\CrearMiniatura;
use Symfony\Component\DependencyInjection\Attribute\Autowire;
use Symfony\Component\HttpFoundation\File\UploadedFile;
use Symfony\Component\Messenger\MessageBusInterface;
use Symfony\Component\Validator\Constraints as Assert;
use Symfony\Component\Validator\Validator\ValidatorInterface;

/**
 * Comprueba y guarda una imagen en public/uploads/{tipo}/ y devuelve su ruta.
 * Después deja en la cola el aviso para que el worker haga la miniatura.
 */
class SubidaImagenes
{
    public const TIPOS = ['soporte', 'productos', 'tienda'];

    public function __construct(
        private ValidatorInterface $validator,
        private MessageBusInterface $bus,
        #[Autowire('%kernel.project_dir%')] private string $directorioProyecto,
    ) {
    }

    /** @throws \InvalidArgumentException con el mensaje para el usuario si la imagen no vale */
    public function subir(mixed $archivo, string $tipo): string
    {
        if (!in_array($tipo, self::TIPOS, true)) {
            throw new \InvalidArgumentException('Valores permitidos: ' . implode(', ', self::TIPOS));
        }
        if (!$archivo instanceof UploadedFile) {
            throw new \InvalidArgumentException('No se ha enviado ninguna imagen');
        }

        $errores = $this->validator->validate($archivo, new Assert\Image(
            maxSize: '10M',
            mimeTypes: ['image/jpeg', 'image/png', 'image/webp'],
            maxSizeMessage: 'La imagen no puede pesar más de 10 MB',
            mimeTypesMessage: 'La imagen tiene que ser JPG, PNG o WEBP',
        ));
        if (count($errores) > 0) {
            throw new \InvalidArgumentException($errores[0]->getMessage());
        }

        $nombre = bin2hex(random_bytes(16)) . '.' . $archivo->guessExtension();
        $archivo->move($this->directorioProyecto . '/public/uploads/' . $tipo, $nombre);
        $ruta = '/uploads/' . $tipo . '/' . $nombre;

        // Segundo proceso: el worker hará la miniatura sin hacer esperar a la app
        $this->bus->dispatch(new CrearMiniatura($ruta));

        return $ruta;
    }
}
