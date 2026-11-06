<?php

namespace App\Controller\Api;

use App\Service\RespuestaApi;
use App\Service\SubidaImagenes;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

#[Route('/api', format: 'json')]
class ImagenController extends AbstractController
{
    /** POST /api/imagenes — multipart: imagen + tipo (soporte, productos, tienda) */
    #[Route('/imagenes', name: 'api_imagenes_subir', methods: ['POST'])]
    public function subir(Request $request, SubidaImagenes $subida): JsonResponse
    {
        $tipo = (string) $request->request->get('tipo', 'soporte');

        try {
            $ruta = $subida->subir($request->files->get('imagen'), $tipo);
        } catch (\InvalidArgumentException $error) {
            $campo = in_array($tipo, SubidaImagenes::TIPOS, true) ? 'imagen' : 'tipo';

            return RespuestaApi::errorValidacion([$campo => $error->getMessage()]);
        }

        return $this->json([
            'ruta' => $ruta,
            'url' => $request->getSchemeAndHttpHost() . $ruta,
        ], Response::HTTP_CREATED);
    }
}
