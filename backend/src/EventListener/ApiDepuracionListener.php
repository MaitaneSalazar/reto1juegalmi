<?php

namespace App\EventListener;

use Symfony\Component\DependencyInjection\Attribute\Autowire;
use Symfony\Component\EventDispatcher\Attribute\AsEventListener;
use Symfony\Component\HttpKernel\Event\ResponseEvent;

/**
 * Solo en desarrollo: cuando la API responde con un error (4xx/5xx), escribe en el log
 * del servidor qué se ha enviado y qué se ha respondido. Las contraseñas salen tapadas.
 * Sirve para ver por qué falla una llamada de las apps sin tener que mirar el móvil.
 */
#[AsEventListener(event: 'kernel.response', priority: -100)]
class ApiDepuracionListener
{
    private const CAMPOS_SECRETOS = ['password', 'password_actual', 'password_nueva'];

    public function __construct(#[Autowire('%kernel.debug%')] private bool $debug)
    {
    }

    public function __invoke(ResponseEvent $event): void
    {
        $peticion = $event->getRequest();
        $respuesta = $event->getResponse();

        if (!$this->debug || !$event->isMainRequest()
            || !str_starts_with($peticion->getPathInfo(), '/api')
            || $respuesta->getStatusCode() < 400) {
            return;
        }

        $cuerpo = json_decode($peticion->getContent(), true);
        if (is_array($cuerpo)) {
            foreach (self::CAMPOS_SECRETOS as $campo) {
                if (isset($cuerpo[$campo])) {
                    $cuerpo[$campo] = '***';
                }
            }
            $enviado = json_encode($cuerpo, JSON_UNESCAPED_UNICODE);
        } else {
            $enviado = $peticion->getContent() === '' ? '(vacío)' : '(no es JSON) ' . substr($peticion->getContent(), 0, 300);
        }

        error_log(sprintf(
            '[API %d] %s %s | Content-Type: %s | Enviado: %s | Respuesta: %s',
            $respuesta->getStatusCode(),
            $peticion->getMethod(),
            $peticion->getPathInfo(),
            $peticion->headers->get('Content-Type', '-'),
            $enviado,
            substr((string) $respuesta->getContent(), 0, 500),
        ));
    }
}
