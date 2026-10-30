<?php

namespace App\Controller\Api;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\File\UploadedFile;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Validator\Constraints as Assert;
use Symfony\Component\Validator\Validator\ValidatorInterface;

#[Route('/api', format: 'json')]
class ImagenController extends AbstractController
{
    private const TIPOS = ['soporte', 'productos', 'tienda'];

    #[Route('/imagenes', name: 'api_imagenes_subir', methods: ['POST'])]
    public function subir(Request $request, ValidatorInterface $validator): JsonResponse
    {
        $tipo = $request->request->get('tipo', 'soporte');
        if (!in_array($tipo, self::TIPOS, true)) {
            return $this->error('tipo', 'Valores permitidos: ' . implode(', ', self::TIPOS));
        }

        $archivo = $request->files->get('imagen');
        if (!$archivo instanceof UploadedFile) {
            return $this->error('imagen', 'No se ha enviado ninguna imagen');
        }

        $errores = $validator->validate($archivo, new Assert\Image(
            maxSize: '10M',
            mimeTypes: ['image/jpeg', 'image/png', 'image/webp'],
            maxSizeMessage: 'La imagen no puede pesar más de 10 MB',
            mimeTypesMessage: 'La imagen tiene que ser JPG, PNG o WEBP',
        ));
        if (count($errores) > 0) {
            return $this->error('imagen', $errores[0]->getMessage());
        }

        // Nombre aleatorio para que dos fotos nunca se sobrescriban
        $nombre = bin2hex(random_bytes(16)) . '.' . $archivo->guessExtension();
        $archivo->move($this->getParameter('kernel.project_dir') . '/public/uploads/' . $tipo, $nombre);

        $ruta = '/uploads/' . $tipo . '/' . $nombre;

        return $this->json([
            'ruta' => $ruta,
            'url' => $request->getSchemeAndHttpHost() . $ruta,
        ], Response::HTTP_CREATED);
    }

    private function error(string $campo, string $mensaje): JsonResponse
    {
        return $this->json([
            'error' => true,
            'codigo' => 422,
            'mensaje' => 'Los datos enviados no son válidos',
            'campos' => [$campo => $mensaje],
        ], Response::HTTP_UNPROCESSABLE_ENTITY);
    }
}
