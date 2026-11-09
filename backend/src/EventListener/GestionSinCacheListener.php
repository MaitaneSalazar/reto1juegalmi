<?php

namespace App\EventListener;

use Symfony\Component\EventDispatcher\Attribute\AsEventListener;
use Symfony\Component\HttpKernel\Event\ResponseEvent;
use Symfony\Component\HttpKernel\KernelEvents;

/**
 * Las páginas de /gestion no se guardan en el navegador:
 * así, tras cerrar sesión, «Atrás» no enseña una copia vieja.
 */
#[AsEventListener(event: KernelEvents::RESPONSE)]
class GestionSinCacheListener
{
    public function __invoke(ResponseEvent $event): void
    {
        if (!$event->isMainRequest() || !str_starts_with($event->getRequest()->getPathInfo(), '/gestion')) {
            return;
        }

        $headers = $event->getResponse()->headers;
        $headers->set('Cache-Control', 'no-store, no-cache, must-revalidate, private');
        $headers->set('Pragma', 'no-cache');
        $headers->set('Expires', '0');
    }
}
