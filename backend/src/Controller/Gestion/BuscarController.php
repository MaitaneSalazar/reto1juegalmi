<?php

namespace App\Controller\Gestion;

use App\Entity\Alquiler;
use App\Entity\Pedido;
use App\Entity\Producto;
use App\Entity\Reparacion;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

/** Buscador de la barra lateral: busca en todo a la vez */
class BuscarController extends AbstractController
{
    private const MAX = 8;

    #[Route('/gestion/buscar', name: 'gestion_buscar', methods: ['GET'])]
    public function index(Request $request, EntityManagerInterface $em): Response
    {
        $q = trim((string) $request->query->get('q', ''));
        $resultados = ['productos' => [], 'reparaciones' => [], 'alquileres' => [], 'pedidos' => []];

        if (mb_strlen($q) >= 2 || ctype_digit(ltrim($q, '#'))) {
            $texto = '%' . mb_strtolower($q) . '%';
            // «#0021» o «21» → busca también por número
            $numero = ctype_digit(ltrim($q, '#')) ? (int) ltrim($q, '#') : -1;
            $cliente = "LOWER(CONCAT(c.nombre, ' ', c.apellido1)) LIKE :q";

            $resultados['productos'] = $em->createQueryBuilder()->select('p')->from(Producto::class, 'p')
                ->where('LOWER(p.nombre) LIKE :q')->setParameter('q', $texto)
                ->orderBy('p.activo', 'DESC')->addOrderBy('p.nombre', 'ASC')
                ->setMaxResults(self::MAX)->getQuery()->getResult();

            foreach (['reparaciones' => Reparacion::class, 'alquileres' => Alquiler::class, 'pedidos' => Pedido::class] as $clave => $clase) {
                $qb = $em->createQueryBuilder()->select('x')->from($clase, 'x')->leftJoin($clase === Pedido::class ? 'x.domicilio' : 'x.' . $this->relacionCliente($em, $clase), $clase === Pedido::class ? 'd' : 'c')
                    ->where($cliente)->orWhere('x.id = :n');
                if ($clase === Pedido::class) {
                    $qb->leftJoin('d.cliente', 'c');
                }
                if ($clase === Reparacion::class) {
                    $qb->orWhere('LOWER(x.modelo) LIKE :q');
                }
                $resultados[$clave] = $qb->setParameter('q', $texto)->setParameter('n', $numero)
                    ->orderBy('x.id', 'DESC')->setMaxResults(self::MAX)->getQuery()->getResult();
            }
        }

        return $this->render('gestion/buscar/index.html.twig', [
            'q' => $q,
            'r' => $resultados,
            'total' => array_sum(array_map('count', $resultados)),
        ]);
    }

    /** Nombre de la relación con el cliente en cada entidad (en Pedido no se llama «cliente») */
    private function relacionCliente(EntityManagerInterface $em, string $clase): string
    {
        $relaciones = $em->getClassMetadata($clase)->getAssociationMappings();
        foreach ([\App\Entity\Cliente::class, \App\Entity\Usuario::class] as $destino) {
            foreach ($relaciones as $nombre => $relacion) {
                if (is_a($relacion['targetEntity'], $destino, true)) {
                    return $nombre;
                }
            }
        }
        return 'cliente';
    }
}
