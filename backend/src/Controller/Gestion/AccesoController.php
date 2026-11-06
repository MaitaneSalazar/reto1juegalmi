<?php

namespace App\Controller\Gestion;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Security\Http\Authentication\AuthenticationUtils;

/** Login y logout de la web de gestión (solo trabajadores: lo comprueba TrabajadorUserChecker) */
class AccesoController extends AbstractController
{
    #[Route('/gestion/acceso', name: 'gestion_acceso')]
    public function acceso(AuthenticationUtils $autenticacion): Response
    {
        if ($this->getUser()) {
            return $this->redirectToRoute('gestion_resumen');
        }

        return $this->render('gestion/acceso.html.twig', [
            'ultimo_email' => $autenticacion->getLastUsername(),
            'error' => $autenticacion->getLastAuthenticationError(),
        ]);
    }

    /** Symfony intercepta esta ruta y cierra la sesión: el método nunca llega a ejecutarse */
    #[Route('/gestion/salir', name: 'gestion_salir')]
    public function salir(): never
    {
        throw new \LogicException('La sesión la cierra el firewall.');
    }
}
