<?php

namespace App\Controller\Api;

use App\Entity\Alquiler;
use App\Entity\AlquilerVideojuego;
use App\Entity\Cliente;
use App\Entity\Usuario;
use App\Entity\Videojuego;
use App\Service\AlquilerPresenter;
use App\Service\RespuestaApi;
use Doctrine\DBAL\LockMode;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Security\Http\Attribute\CurrentUser;

#[Route('/api/alquileres', format: 'json')]
class AlquilerController extends AbstractController
{
    private const ESTADOS = ['activo', 'retrasado', 'devuelto'];
    private const MAX_DIAS = 30;

    public function __construct(
        private EntityManagerInterface $em,
        private AlquilerPresenter $presenter,
    ) {
    }

    /** GET /api/alquileres?estado=activo&page=1 — pantalla 10 (Cuenta) y «Mis alquileres» */
    #[Route('', name: 'api_alquileres', methods: ['GET'])]
    public function listar(#[CurrentUser] Usuario $usuario, Request $request): JsonResponse
    {
        if (!$usuario instanceof Cliente) {
            return RespuestaApi::error(403, 'Solo los clientes tienen alquileres');
        }

        $estado = $request->query->get('estado');
        if ($estado !== null && !in_array($estado, self::ESTADOS, true)) {
            return RespuestaApi::errorValidacion(['estado' => 'Valores permitidos: ' . implode(', ', self::ESTADOS)]);
        }

        $alquileres = $this->em->getRepository(Alquiler::class)->findBy(
            ['cliente' => $usuario],
            ['fechaInicio' => 'DESC', 'id' => 'DESC'],
        );

        // El estado se calcula (no está en la base de datos), así que se filtra aquí
        if ($estado !== null) {
            $alquileres = array_values(array_filter($alquileres, fn (Alquiler $a) => $a->getEstado() === $estado));
        }

        [$pagina, $porPagina] = RespuestaApi::paginacion($request);
        $pagina_actual = array_slice($alquileres, ($pagina - 1) * $porPagina, $porPagina);

        return RespuestaApi::listado(
            array_map([$this->presenter, 'presentar'], $pagina_actual),
            count($alquileres),
            $pagina,
            $porPagina,
        );
    }

    /** GET /api/alquileres/{id} */
    #[Route('/{id}', name: 'api_alquiler', requirements: ['id' => '\d+'], methods: ['GET'])]
    public function ver(#[CurrentUser] Usuario $usuario, int $id): JsonResponse
    {
        $alquiler = $this->alquilerDe($usuario, $id);
        if (!$alquiler) {
            return RespuestaApi::error(404, 'El alquiler no existe');
        }

        return $this->json($this->presenter->presentar($alquiler));
    }

    /** POST /api/alquileres — {dias, videojuegos: [ids]} — pantalla 06 */
    #[Route('', name: 'api_alquileres_crear', methods: ['POST'])]
    public function crear(#[CurrentUser] Usuario $usuario, Request $request): JsonResponse
    {
        if (!$usuario instanceof Cliente) {
            return RespuestaApi::error(403, 'Solo los clientes pueden alquilar');
        }

        $datos = RespuestaApi::leerJson($request);

        $dias = (int) ($datos['dias'] ?? 0);
        if ($dias < 1 || $dias > self::MAX_DIAS) {
            return RespuestaApi::errorValidacion(['dias' => 'Elige entre 1 y ' . self::MAX_DIAS . ' días']);
        }

        $ids = $datos['videojuegos'] ?? null;
        if (!is_array($ids) || $ids === []) {
            return RespuestaApi::errorValidacion(['videojuegos' => 'Elige al menos un videojuego']);
        }
        $ids = array_values(array_unique(array_map('intval', $ids)));

        $alquiler = (new Alquiler())
            ->setCliente($usuario)
            ->setFechaInicio(new \DateTimeImmutable('today'))
            ->setFechaFinPrevista(new \DateTimeImmutable("today +$dias days"));

        $this->em->beginTransaction();
        try {
            foreach ($ids as $id) {
                // Bloquea el videojuego: dos clientes no pueden llevarse a la vez la última copia
                $juego = $this->em->find(Videojuego::class, $id, LockMode::PESSIMISTIC_WRITE);

                if (!$juego || !$juego->isActivo() || $juego->getCopiasAlquiler() === 0) {
                    $this->em->rollback();

                    return RespuestaApi::errorValidacion(['videojuegos' => "El videojuego $id no se puede alquilar"]);
                }

                if ($this->copiasAlquiladas($juego) >= $juego->getCopiasAlquiler()) {
                    $this->em->rollback();

                    return RespuestaApi::error(409, 'No quedan copias libres de ' . $juego->getNombre());
                }

                $alquiler->addLinea((new AlquilerVideojuego())->setVideojuego($juego));
            }

            $this->em->persist($alquiler);
            $this->em->flush();
            $this->em->commit();
        } catch (\Throwable $error) {
            $this->em->rollback();
            throw $error;
        }

        return $this->json($this->presenter->presentar($alquiler), Response::HTTP_CREATED);
    }

    /** PUT /api/alquileres/{id}/devolver — botón «Devolver». Opcional: {videojuegos: [ids]} */
    #[Route('/{id}/devolver', name: 'api_alquiler_devolver', requirements: ['id' => '\d+'], methods: ['PUT'])]
    public function devolver(#[CurrentUser] Usuario $usuario, int $id, Request $request): JsonResponse
    {
        $alquiler = $this->alquilerDe($usuario, $id);
        if (!$alquiler) {
            return RespuestaApi::error(404, 'El alquiler no existe');
        }

        $datos = RespuestaApi::leerJson($request);
        $soloEstos = isset($datos['videojuegos']) && is_array($datos['videojuegos'])
            ? array_map('intval', $datos['videojuegos'])
            : null;

        $devueltos = 0;
        $hoy = new \DateTimeImmutable('today');
        foreach ($alquiler->getLineas() as $linea) {
            if ($linea->getFechaDevolucion() !== null) {
                continue;
            }
            if ($soloEstos !== null && !in_array($linea->getVideojuego()->getId(), $soloEstos, true)) {
                continue;
            }
            $linea->setFechaDevolucion($hoy);
            $devueltos++;
        }

        if ($devueltos === 0) {
            return RespuestaApi::error(409, 'No hay juegos pendientes de devolver en este alquiler');
        }

        $this->em->flush();

        return $this->json($this->presenter->presentar($alquiler));
    }

    private function alquilerDe(Usuario $usuario, int $id): ?Alquiler
    {
        $alquiler = $this->em->find(Alquiler::class, $id);

        return $alquiler && $alquiler->getCliente() === $usuario ? $alquiler : null;
    }

    private function copiasAlquiladas(Videojuego $juego): int
    {
        return (int) $this->em->createQuery(
            'SELECT COUNT(l.id) FROM ' . AlquilerVideojuego::class . ' l
             WHERE l.videojuego = :juego AND l.fechaDevolucion IS NULL'
        )->setParameter('juego', $juego)->getSingleScalarResult();
    }
}
