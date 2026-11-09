<?php

namespace App\Controller\Gestion;

use App\Entity\Trabajador;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

/** Ayuda: guía corta de cada pantalla */
class AyudaController extends AbstractController
{
    #[Route('/gestion/ayuda', name: 'gestion_ayuda', methods: ['GET'])]
    public function index(EntityManagerInterface $em): Response
    {
        return $this->render('gestion/ayuda/index.html.twig', [
            'admins' => $em->getRepository(Trabajador::class)->findBy(['esAdmin' => true, 'activo' => true], ['nombre' => 'ASC']),
        ]);
    }
}
