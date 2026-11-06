<?php

namespace App\Controller\Api;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\Routing\Attribute\Route;

#[Route('/api', format: 'json')]
class EstadoController extends AbstractController
{
    #[Route('/estado', name: 'api_estado', methods: ['GET'])]
    public function estado(): JsonResponse
    {
        return $this->json([
            'estado' => 'ok',
            'aplicacion' => 'JuegAlmi API',
            'fecha' => (new \DateTimeImmutable())->format(DATE_ATOM),
        ]);
    }
}
