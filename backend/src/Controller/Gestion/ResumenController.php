<?php

namespace App\Controller\Gestion;

use App\Entity\Alquiler;
use App\Entity\Pedido;
use App\Entity\Producto;
use App\Entity\Reparacion;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

/** Pantalla 02 del mockup: el resumen del día */
class ResumenController extends AbstractController
{
    /** A partir de cuántas unidades se avisa de stock bajo */
    public const STOCK_BAJO = 2;

    #[Route('/gestion', name: 'gestion_resumen')]
    public function resumen(EntityManagerInterface $em): Response
    {
        // Reparaciones por estado (las entregadas, solo las de los últimos 7 días)
        $porEstado = array_fill_keys(['recibida', 'diagnostico', 'en_reparacion', 'lista_para_recoger', 'entregada'], 0);
        $listas = [];
        $haceUnaSemana = new \DateTimeImmutable('-7 days');
        foreach ($em->getRepository(Reparacion::class)->findBy([], ['id' => 'DESC']) as $reparacion) {
            $estado = $reparacion->getEstadoActual();
            if ($estado === 'entregada') {
                if ($reparacion->getHistorial()->last()?->getFechaHora() >= $haceUnaSemana) {
                    $porEstado['entregada']++;
                }
                continue;
            }
            if (isset($porEstado[$estado])) {
                $porEstado[$estado]++;
            }
            if ($estado === 'lista_para_recoger') {
                $listas[] = $reparacion;
            }
        }

        // Alquileres: activos (sin devolver) y vencidos, el más antiguo primero
        $alquileres = array_filter($em->getRepository(Alquiler::class)->findAll(), fn (Alquiler $a) => $a->getEstado() !== 'devuelto');
        $vencidos = array_values(array_filter($alquileres, fn (Alquiler $a) => $a->getEstado() === 'retrasado'));
        usort($vencidos, fn (Alquiler $a, Alquiler $b) => $a->getFechaFinPrevista() <=> $b->getFechaFinPrevista());

        return $this->render('gestion/resumen.html.twig', [
            'por_estado' => $porEstado,
            'en_curso' => $porEstado['recibida'] + $porEstado['diagnostico'] + $porEstado['en_reparacion'] + $porEstado['lista_para_recoger'],
            'listas' => $listas,
            'alquileres_activos' => count($alquileres),
            'vencidos' => $vencidos,
            'pendientes' => $em->getRepository(Pedido::class)->findBy(['estado' => 'pendiente'], ['fecha' => 'ASC']),
            'stock_bajo' => $em->getRepository(Producto::class)->createQueryBuilder('p')
                ->where('p.activo = true')->andWhere('p.stock <= :minimo')->setParameter('minimo', self::STOCK_BAJO)
                ->orderBy('p.stock', 'ASC')->addOrderBy('p.nombre', 'ASC')
                ->getQuery()->getResult(),
        ]);
    }
}
