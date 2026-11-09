<?php

namespace App\EventListener;

use Symfony\Component\DependencyInjection\Attribute\Autowire;
use Symfony\Component\EventDispatcher\Attribute\AsEventListener;
use Symfony\Component\HttpFoundation\RedirectResponse;
use Symfony\Component\HttpKernel\Event\RequestEvent;
use Symfony\Component\HttpKernel\Event\ResponseEvent;
use Symfony\Component\HttpKernel\KernelEvents;

/**
 * HTTPS integrado en Symfony (solo en producción):
 *  - si una petición llega por http, se redirige a https;
 *  - las respuestas seguras llevan HSTS para que el navegador use siempre https.
 * El proxy (Nginx Proxy Manager) pone el certificado; Symfony sabe que la petición
 * es https gracias a SYMFONY_TRUSTED_PROXIES. Las llamadas a localhost no se tocan.
 */
class HttpsListener
{
    private const SIN_REDIRIGIR = ['localhost', '127.0.0.1'];

    public function __construct(#[Autowire('%kernel.environment%')] private string $entorno)
    {
    }

    #[AsEventListener(event: KernelEvents::REQUEST, priority: 300)]
    public function exigirHttps(RequestEvent $event): void
    {
        $request = $event->getRequest();
        if ($this->entorno !== 'prod' || !$event->isMainRequest() || $request->isSecure()
            || in_array($request->getHost(), self::SIN_REDIRIGIR, true)) {
            return;
        }

        // 308 mantiene el método (un POST sigue siendo POST al repetirse por https)
        $codigo = $request->isMethodSafe() ? 301 : 308;
        $event->setResponse(new RedirectResponse('https://' . $request->getHttpHost() . $request->getRequestUri(), $codigo));
    }

    #[AsEventListener(event: KernelEvents::RESPONSE)]
    public function anadirHsts(ResponseEvent $event): void
    {
        if ($this->entorno === 'prod' && $event->isMainRequest() && $event->getRequest()->isSecure()) {
            $event->getResponse()->headers->set('Strict-Transport-Security', 'max-age=31536000');
        }
    }
}
