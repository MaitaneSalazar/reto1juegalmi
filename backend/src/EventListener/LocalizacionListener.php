<?php

namespace App\EventListener;

use App\Entity\Cliente;
use App\Entity\Localizacion;
use Doctrine\ORM\EntityManagerInterface;
use Psr\Log\LoggerInterface;
use Symfony\Bundle\SecurityBundle\Security;
use Symfony\Component\EventDispatcher\Attribute\AsEventListener;
use Symfony\Component\HttpKernel\Event\TerminateEvent;
use Symfony\Component\HttpKernel\KernelEvents;

/**
 * Requisito del reto: «saber la localización de la persona en el momento de cualquier consulta».
 * Las apps envían las cabeceras X-Lat y X-Lon en todas las llamadas; aquí se guardan en LOCALIZACION.
 * Se ejecuta cuando la respuesta ya se ha enviado, así que no retrasa a la app.
 */
#[AsEventListener(event: KernelEvents::TERMINATE)]
class LocalizacionListener
{
    public function __construct(
        private Security $security,
        private EntityManagerInterface $em,
        private LoggerInterface $logger,
    ) {
    }

    public function __invoke(TerminateEvent $event): void
    {
        $request = $event->getRequest();

        if (!$event->isMainRequest() || !str_starts_with($request->getPathInfo(), '/api')) {
            return;
        }

        $latitud = $request->headers->get('X-Lat');
        $longitud = $request->headers->get('X-Lon');
        if (!is_numeric($latitud) || !is_numeric($longitud)) {
            return;
        }

        $latitud = (float) $latitud;
        $longitud = (float) $longitud;
        if (abs($latitud) > 90 || abs($longitud) > 180) {
            return;
        }

        // En el E-R, LOCALIZACION pertenece siempre a un CLIENTE
        $cliente = $this->security->getUser();
        if (!$cliente instanceof Cliente) {
            return;
        }

        try {
            if (!$this->em->isOpen()) {
                return;
            }

            $this->em->persist((new Localizacion())
                ->setCliente($cliente)
                ->setLatitud($latitud)
                ->setLongitud($longitud));
            $this->em->flush();
        } catch (\Throwable $error) {
            $this->logger->warning('No se pudo guardar la localización: ' . $error->getMessage());
        }
    }
}
