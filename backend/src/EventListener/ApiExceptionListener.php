<?php

namespace App\EventListener;

use Symfony\Component\DependencyInjection\Attribute\Autowire;
use Symfony\Component\EventDispatcher\Attribute\AsEventListener;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpKernel\Event\ExceptionEvent;
use Symfony\Component\HttpKernel\Exception\HttpExceptionInterface;
use Symfony\Component\HttpKernel\KernelEvents;

#[AsEventListener(event: KernelEvents::EXCEPTION)]
class ApiExceptionListener
{
    private const MENSAJES = [
        400 => 'Petición incorrecta',
        401 => 'Tienes que iniciar sesión',
        403 => 'No tienes permiso para hacer esto',
        404 => 'Recurso no encontrado',
        405 => 'Método no permitido en esta ruta',
        409 => 'Conflicto con los datos existentes',
        422 => 'Los datos enviados no son válidos',
        500 => 'Error interno del servidor',
    ];

    public function __construct(
        #[Autowire('%kernel.debug%')] private bool $debug,
    ) {
    }

    public function __invoke(ExceptionEvent $event): void
    {
        // Solo actúa en las rutas de la API; la web de trabajadores tiene sus propias páginas de error
        if (!str_starts_with($event->getRequest()->getPathInfo(), '/api')) {
            return;
        }

        $error = $event->getThrowable();
        $codigo = $error instanceof HttpExceptionInterface ? $error->getStatusCode() : 500;
        $cabeceras = $error instanceof HttpExceptionInterface ? $error->getHeaders() : [];

        $datos = [
            'error' => true,
            'codigo' => $codigo,
            'mensaje' => self::MENSAJES[$codigo] ?? 'Error',
        ];

        // En desarrollo se añade el detalle técnico para depurar; en AWS (producción) no se muestra
        if ($this->debug) {
            $datos['detalle'] = $error->getMessage();
        }

        $event->setResponse(new JsonResponse($datos, $codigo, $cabeceras));
    }
}
