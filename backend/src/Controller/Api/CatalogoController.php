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

    /** GET /api/videojuegos/alquiler?plataforma=PS5&page=1 — pantalla 05 */
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
