<?php

namespace App\Service;

use Symfony\Component\DependencyInjection\Attribute\Autowire;
use Symfony\Component\HttpFoundation\File\UploadedFile;
use Symfony\Component\Validator\Constraints as Assert;
use Symfony\Component\Validator\Validator\ValidatorInterface;

/**
 * Comprueba y guarda una imagen en public/uploads/{tipo}/ y devuelve su ruta.
 */
class SubidaImagenes
{
    public const TIPOS = ['soporte', 'productos', 'tienda'];

    public function __construct(
        private ValidatorInterface $validator,
        #[Autowire('%kernel.project_dir%')] private string $directorioProyecto,
    ) {
    }

    /** @throws \InvalidArgumentException con el mensaje para el usuario si la imagen no vale */
    public function subir(mixed $archivo, string $tipo): string
    {
        if (!in_array($tipo, self::TIPOS, true)) {
            throw new \InvalidArgumentException('Tipo de imagen no válido');
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

        return '/uploads/' . $tipo . '/' . $nombre;
    }
}
