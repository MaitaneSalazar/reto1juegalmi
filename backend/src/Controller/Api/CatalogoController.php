<?php

namespace App\Controller\Api;

use App\Entity\AlquilerVideojuego;
use App\Entity\Consola;
use App\Entity\Movil;
use App\Entity\Producto;
use App\Entity\Tablet;
use App\Entity\Videojuego;
use App\Service\ProductoPresenter;
use App\Service\RespuestaApi;
use Doctrine\ORM\EntityManagerInterface;
use Doctrine\ORM\Tools\Pagination\Paginator;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\Routing\Attribute\Route;

#[Route('/api', format: 'json')]
class CatalogoController extends AbstractController
{
    private const TIPOS = [
        'videojuego' => Videojuego::class,
        'consola' => Consola::class,
        'movil' => Movil::class,
        'tablet' => Tablet::class,
    ];

    public function __construct(
        private EntityManagerInterface $em,
        private ProductoPresenter $presenter,
    ) {
    }

    /** GET /api/productos?tipo=movil&q=galaxy&page=1&limit=20 — pantalla 04 */
    #[Route('/productos', name: 'api_productos', methods: ['GET'])]
    public function productos(Request $request): JsonResponse
    {
        [$pagina, $porPagina] = RespuestaApi::paginacion($request);

        $qb = $this->em->createQueryBuilder()
            ->select('p', 'e')
            ->from(Producto::class, 'p')
            ->leftJoin('p.empresa', 'e')
            ->where('p.activo = true')
            ->orderBy('p.nombre', 'ASC');

        $tipo = $request->query->get('tipo');
        if ($tipo !== null && $tipo !== '' && $tipo !== 'todo') {
            if (!isset(self::TIPOS[$tipo])) {
                return RespuestaApi::errorValidacion(['tipo' => 'Valores permitidos: ' . implode(', ', array_keys(self::TIPOS))]);
            }
            $qb->andWhere('p INSTANCE OF ' . self::TIPOS[$tipo]);
        }

        $busqueda = trim((string) $request->query->get('q', ''));
        if ($busqueda !== '') {
            $qb->andWhere('LOWER(p.nombre) LIKE :q')->setParameter('q', '%' . mb_strtolower($busqueda) . '%');
        }

        // ?plataforma=PlayStation → solo los videojuegos de esa plataforma (como en /videojuegos/alquiler)
        $plataforma = trim((string) $request->query->get('plataforma', ''));
        if ($plataforma !== '' && mb_strtolower($plataforma) !== 'todas') {
            $qb->andWhere('p.id IN (SELECT vp.id FROM ' . Videojuego::class . ' vp WHERE LOWER(vp.plataforma) = :plataforma)')
                ->setParameter('plataforma', mb_strtolower($plataforma));
        }


        // ?empresa=Nintendo → solo los productos de esa empresa
        $empresa = trim((string) $request->query->get('empresa', ''));
        if ($empresa !== '' && mb_strtolower($empresa) !== 'todas') {
            $qb->andWhere('LOWER(e.nombre) = :empresa')->setParameter('empresa', mb_strtolower($empresa));
        }

        // ?pegi=12 → solo los videojuegos con ese PEGI
        $pegi = trim((string) $request->query->get('pegi', ''));
        if ($pegi !== '' && mb_strtolower($pegi) !== 'todos') {
            if (!in_array((int) $pegi, Videojuego::PEGI, true)) {
                return RespuestaApi::errorValidacion(['pegi' => 'Valores permitidos: ' . implode(', ', Videojuego::PEGI)]);
            }
            $qb->andWhere('p.id IN (SELECT vg.id FROM ' . Videojuego::class . ' vg WHERE vg.pegi = :pegi)')
                ->setParameter('pegi', (int) $pegi);
        }

        $qb->setFirstResult(($pagina - 1) * $porPagina)->setMaxResults($porPagina);
        $paginador = new Paginator($qb);

        $datos = [];
        foreach ($paginador as $producto) {
            $datos[] = $this->presenter->resumen($producto);
        }

        return RespuestaApi::listado($datos, count($paginador), $pagina, $porPagina);
    }

    /** GET /api/productos/{id} — pantalla 06 (ficha) */
    #[Route('/productos/{id}', name: 'api_producto', requirements: ['id' => '\d+'], methods: ['GET'])]
    public function producto(int $id): JsonResponse
    {
        $producto = $this->em->find(Producto::class, $id);
        if (!$producto || !$producto->isActivo()) {
            return RespuestaApi::error(404, 'El producto no existe');
        }

        $datos = $this->presenter->detalle($producto);

        if ($producto instanceof Videojuego) {
            $alquilados = $this->alquilados([$producto->getId()]);
            $datos['copias_disponibles'] = max(0, $producto->getCopiasAlquiler() - ($alquilados[$producto->getId()] ?? 0));
        }

        return $this->json($datos);
    }

    /** GET /api/videojuegos/alquiler?plataforma=PlayStation&page=1 — pantalla 05 */
    #[Route('/videojuegos/alquiler', name: 'api_videojuegos_alquiler', methods: ['GET'])]
    public function alquiler(Request $request): JsonResponse
    {
        [$pagina, $porPagina] = RespuestaApi::paginacion($request);

        $qb = $this->em->createQueryBuilder()
            ->select('v', 'e')
            ->from(Videojuego::class, 'v')
            ->leftJoin('v.empresa', 'e')
            ->where('v.activo = true')
            ->andWhere('v.copiasAlquiler > 0')
            ->orderBy('v.nombre', 'ASC');

        $plataforma = trim((string) $request->query->get('plataforma', ''));
        if ($plataforma !== '' && mb_strtolower($plataforma) !== 'todas') {
            $qb->andWhere('LOWER(v.plataforma) = :plataforma')->setParameter('plataforma', mb_strtolower($plataforma));
        }


        $empresa = trim((string) $request->query->get('empresa', ''));
        if ($empresa !== '' && mb_strtolower($empresa) !== 'todas') {
            $qb->andWhere('LOWER(e.nombre) = :empresa')->setParameter('empresa', mb_strtolower($empresa));
        }

        $pegi = trim((string) $request->query->get('pegi', ''));
        if ($pegi !== '' && mb_strtolower($pegi) !== 'todos') {
            if (!in_array((int) $pegi, Videojuego::PEGI, true)) {
                return RespuestaApi::errorValidacion(['pegi' => 'Valores permitidos: ' . implode(', ', Videojuego::PEGI)]);
            }
            $qb->andWhere('v.pegi = :pegi')->setParameter('pegi', (int) $pegi);
        }

        $qb->setFirstResult(($pagina - 1) * $porPagina)->setMaxResults($porPagina);
        $paginador = new Paginator($qb);
        $juegos = iterator_to_array($paginador);

        // Copias alquiladas ahora mismo de los juegos de esta página (una sola consulta)
        $alquilados = $this->alquilados(array_map(fn (Videojuego $v) => $v->getId(), $juegos));

        $datos = [];
        foreach ($juegos as $juego) {
            $disponibles = max(0, $juego->getCopiasAlquiler() - ($alquilados[$juego->getId()] ?? 0));
            $datos[] = $this->presenter->resumen($juego) + [
                'copias_alquiler' => $juego->getCopiasAlquiler(),
                'copias_disponibles' => $disponibles,
                'alquilado' => $disponibles === 0,
            ];
        }

        return RespuestaApi::listado($datos, count($paginador), $pagina, $porPagina);
    }

    /** GET /api/productos/filtros — opciones de los desplegables de filtro de las pantallas 04 y 05 */
    #[Route('/productos/filtros', name: 'api_productos_filtros', methods: ['GET'])]
    public function filtros(): JsonResponse
    {
        $empresas = $this->em->createQueryBuilder()
            ->select('DISTINCT e.nombre')->from(Producto::class, 'p')->join('p.empresa', 'e')
            ->where('p.activo = true')->orderBy('e.nombre', 'ASC')
            ->getQuery()->getSingleColumnResult();

        $plataformas = $this->em->createQueryBuilder()
            ->select('DISTINCT v.plataforma')->from(Videojuego::class, 'v')
            ->where('v.activo = true')->orderBy('v.plataforma', 'ASC')
            ->getQuery()->getSingleColumnResult();

        return $this->json([
            'tipos' => array_keys(self::TIPOS),
            'plataformas' => $plataformas,
            'empresas' => $empresas,
            'pegi' => Videojuego::PEGI,
        ]);
    }

    /** GET /api/videojuegos/plataformas — botones de filtro de la pantalla 05 */
    #[Route('/videojuegos/plataformas', name: 'api_videojuegos_plataformas', methods: ['GET'])]
    public function plataformas(): JsonResponse
    {
        $filas = $this->em->createQuery(
            'SELECT DISTINCT v.plataforma FROM ' . Videojuego::class . ' v WHERE v.activo = true ORDER BY v.plataforma ASC'
        )->getSingleColumnResult();

        return $this->json($filas);
    }

    /** @return array<int, int> id del videojuego => copias alquiladas sin devolver */
    private function alquilados(array $ids): array
    {
        if ($ids === []) {
            return [];
        }

        $filas = $this->em->createQuery(
            'SELECT IDENTITY(l.videojuego) AS id, COUNT(l.id) AS total FROM ' . AlquilerVideojuego::class . ' l
             WHERE l.fechaDevolucion IS NULL AND l.videojuego IN (:ids)
             GROUP BY l.videojuego'
        )->setParameter('ids', $ids)->getArrayResult();

        $resultado = [];
        foreach ($filas as $fila) {
            $resultado[(int) $fila['id']] = (int) $fila['total'];
        }

        return $resultado;
    }
}
