<?php

namespace App\Controller\Api;

use App\Entity\Cliente;
use App\Entity\FotoReparacion;
use App\Entity\Reparacion;
use App\Entity\Usuario;
use App\Service\ReparacionPresenter;
use App\Service\RespuestaApi;
use App\Service\SubidaImagenes;
use Doctrine\ORM\EntityManagerInterface;
use Doctrine\ORM\Tools\Pagination\Paginator;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Security\Http\Attribute\CurrentUser;
use Symfony\Component\Validator\Validator\ValidatorInterface;

#[Route('/api/reparaciones', format: 'json')]
class ReparacionController extends AbstractController
{
    private const MAX_FOTOS = 5;

    public function __construct(
        private EntityManagerInterface $em,
        private ReparacionPresenter $presenter,
    ) {
    }

    /** GET /api/reparaciones?page=1 — «Mis reparaciones» y tarjeta de Inicio */
    #[Route('', name: 'api_reparaciones', methods: ['GET'])]
    public function listar(#[CurrentUser] Usuario $usuario, Request $request): JsonResponse
    {
        if (!$usuario instanceof Cliente) {
            return RespuestaApi::error(403, 'Solo los clientes tienen reparaciones');
        }

        [$pagina, $porPagina] = RespuestaApi::paginacion($request);

        $qb = $this->em->createQueryBuilder()
            ->select('r', 'h')
            ->from(Reparacion::class, 'r')
            ->leftJoin('r.historial', 'h')
            ->where('r.cliente = :cliente')
            ->setParameter('cliente', $usuario)
            ->orderBy('r.id', 'DESC')
            ->setFirstResult(($pagina - 1) * $porPagina)
            ->setMaxResults($porPagina);

        $paginador = new Paginator($qb);
        $datos = [];
        foreach ($paginador as $reparacion) {
            $datos[] = $this->presenter->resumen($reparacion);
        }

        return RespuestaApi::listado($datos, count($paginador), $pagina, $porPagina);
    }

    /** GET /api/reparaciones/{id} — pantalla 09 */
    #[Route('/{id}', name: 'api_reparacion', requirements: ['id' => '\d+'], methods: ['GET'])]
    public function ver(#[CurrentUser] Usuario $usuario, int $id): JsonResponse
    {
        $reparacion = $this->reparacionDe($usuario, $id);
        if (!$reparacion) {
            return RespuestaApi::error(404, 'La reparación no existe');
        }

        return $this->json($this->presenter->detalle($reparacion));
    }

    /** POST /api/reparaciones — pantalla 08 */
    #[Route('', name: 'api_reparaciones_crear', methods: ['POST'])]
    public function crear(#[CurrentUser] Usuario $usuario, Request $request, ValidatorInterface $validator): JsonResponse
    {
        if (!$usuario instanceof Cliente) {
            return RespuestaApi::error(403, 'Solo los clientes pueden pedir reparaciones');
        }

        $datos = RespuestaApi::leerJson($request);
        $texto = fn (string $campo): string => trim((string) ($datos[$campo] ?? ''));

        $reparacion = (new Reparacion())
            ->setCliente($usuario)
            ->setTipoDispositivo($texto('tipo_dispositivo'))
            ->setMarca($texto('marca'))
            ->setModelo($texto('modelo'))
            ->setComponente($texto('componente') ?: null)
            ->setDescripcionAveria($texto('descripcion_averia'));

        $campos = RespuestaApi::camposConError($validator->validate($reparacion));
        if ($campos !== []) {
            return RespuestaApi::errorValidacion($campos);
        }

        $this->em->persist($reparacion);
        $this->em->flush();

        return $this->json($this->presenter->detalle($reparacion), Response::HTTP_CREATED);
    }

    /** POST /api/reparaciones/{id}/fotos — formulario multipart con el campo «imagen» */
    #[Route('/{id}/fotos', name: 'api_reparacion_fotos', requirements: ['id' => '\d+'], methods: ['POST'])]
    public function subirFoto(#[CurrentUser] Usuario $usuario, int $id, Request $request, SubidaImagenes $subida): JsonResponse
    {
        $reparacion = $this->reparacionDe($usuario, $id);
        if (!$reparacion) {
            return RespuestaApi::error(404, 'La reparación no existe');
        }

        if ($reparacion->getFotos()->count() >= self::MAX_FOTOS) {
            return RespuestaApi::error(409, 'Cada reparación admite como máximo ' . self::MAX_FOTOS . ' fotos');
        }

        try {
            $ruta = $subida->subir($request->files->get('imagen'), 'soporte');
        } catch (\InvalidArgumentException $error) {
            return RespuestaApi::errorValidacion(['imagen' => $error->getMessage()]);
        }

        $reparacion->addFoto((new FotoReparacion())->setRuta($ruta));
        $this->em->flush();

        return $this->json($this->presenter->detalle($reparacion), Response::HTTP_CREATED);
    }

    /** DELETE /api/reparaciones/{id} — cancelar, solo si sigue «recibida» */
    #[Route('/{id}', name: 'api_reparacion_cancelar', requirements: ['id' => '\d+'], methods: ['DELETE'])]
    public function cancelar(#[CurrentUser] Usuario $usuario, int $id): JsonResponse
    {
        $reparacion = $this->reparacionDe($usuario, $id);
        if (!$reparacion) {
            return RespuestaApi::error(404, 'La reparación no existe');
        }

        if ($reparacion->getEstadoActual() !== 'recibida') {
            return RespuestaApi::error(409, 'El taller ya ha empezado con esta reparación y no se puede cancelar');
        }

        $reparacion->cambiarEstado('cancelada', 'Cancelada por el cliente');
        $this->em->flush();

        return $this->json($this->presenter->detalle($reparacion));
    }

    private function reparacionDe(Usuario $usuario, int $id): ?Reparacion
    {
        $reparacion = $this->em->find(Reparacion::class, $id);

        return $reparacion && $reparacion->getCliente() === $usuario ? $reparacion : null;
    }
}
