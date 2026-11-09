<?php

namespace App\Controller\Api;

use App\Entity\Cliente;
use App\Entity\Domicilio;
use App\Entity\Pedido;
use App\Entity\PedidoProducto;
use App\Entity\Producto;
use App\Entity\Usuario;
use App\Service\PedidoPresenter;
use App\Service\RespuestaApi;
use Doctrine\DBAL\LockMode;
use Doctrine\ORM\EntityManagerInterface;
use Doctrine\ORM\Tools\Pagination\Paginator;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Security\Http\Attribute\CurrentUser;

#[Route('/api/pedidos', format: 'json')]
class PedidoController extends AbstractController
{
    public function __construct(
        private EntityManagerInterface $em,
        private PedidoPresenter $presenter,
    ) {
    }

    /** GET /api/pedidos?page=1 — «Mis pedidos» */
    #[Route('', name: 'api_pedidos', methods: ['GET'])]
    public function listar(#[CurrentUser] Usuario $usuario, Request $request): JsonResponse
    {
        if (!$usuario instanceof Cliente) {
            return RespuestaApi::error(403, 'Solo los clientes tienen pedidos');
        }

        [$pagina, $porPagina] = RespuestaApi::paginacion($request);

        $qb = $this->em->createQueryBuilder()
            ->select('p', 'l', 'pr')
            ->from(Pedido::class, 'p')
            ->join('p.domicilio', 'd')
            ->leftJoin('p.lineas', 'l')
            ->leftJoin('l.producto', 'pr')
            ->where('d.cliente = :cliente')
            ->setParameter('cliente', $usuario)
            ->orderBy('p.fecha', 'DESC')
            ->setFirstResult(($pagina - 1) * $porPagina)
            ->setMaxResults($porPagina);

        $paginador = new Paginator($qb);
        $datos = [];
        foreach ($paginador as $pedido) {
            $datos[] = $this->presenter->resumen($pedido);
        }

        return RespuestaApi::listado($datos, count($paginador), $pagina, $porPagina);
    }

    /** GET /api/pedidos/{id} */
    #[Route('/{id}', name: 'api_pedido', requirements: ['id' => '\d+'], methods: ['GET'])]
    public function ver(#[CurrentUser] Usuario $usuario, int $id): JsonResponse
    {
        $pedido = $this->pedidoDe($usuario, $id);
        if (!$pedido) {
            return RespuestaApi::error(404, 'El pedido no existe');
        }

        return $this->json($this->presenter->detalle($pedido));
    }

    /** POST /api/pedidos — {id_domicilio, lineas: [{id_producto, cantidad}]} — pantalla 07 */
    #[Route('', name: 'api_pedidos_crear', methods: ['POST'])]
    public function crear(#[CurrentUser] Usuario $usuario, Request $request): JsonResponse
    {
        if (!$usuario instanceof Cliente) {
            return RespuestaApi::error(403, 'Solo los clientes pueden hacer pedidos');
        }

        $datos = RespuestaApi::leerJson($request);

        // --- Domicilio: tiene que ser suyo y estar activo ---
        $domicilio = $this->em->find(Domicilio::class, (int) ($datos['id_domicilio'] ?? 0));
        if (!$domicilio || $domicilio->getCliente() !== $usuario || !$domicilio->isActivo()) {
            return RespuestaApi::errorValidacion(['id_domicilio' => 'Elige uno de tus domicilios']);
        }

        // --- Líneas: se juntan las repetidas sumando cantidades ---
        $lineas = $datos['lineas'] ?? null;
        if (!is_array($lineas) || $lineas === []) {
            return RespuestaApi::errorValidacion(['lineas' => 'La cesta está vacía']);
        }

        $cantidades = [];
        foreach ($lineas as $linea) {
            $idProducto = (int) ($linea['id_producto'] ?? 0);
            $cantidad = (int) ($linea['cantidad'] ?? 0);
            if ($idProducto <= 0 || $cantidad <= 0) {
                return RespuestaApi::errorValidacion(['lineas' => 'Cada línea necesita un id_producto y una cantidad de al menos 1']);
            }
            $cantidades[$idProducto] = ($cantidades[$idProducto] ?? 0) + $cantidad;
        }

        // --- Todo dentro de una transacción: o se hace entero o no se hace nada ---
        $this->em->beginTransaction();
        try {
            $pedido = (new Pedido())->setDomicilio($domicilio)->setEstado('pendiente');

            foreach ($cantidades as $idProducto => $cantidad) {
                // Bloquea la fila del producto hasta terminar: dos compras a la vez no venden el mismo stock
                $producto = $this->em->find(Producto::class, $idProducto, LockMode::PESSIMISTIC_WRITE);

                if (!$producto || !$producto->isActivo()) {
                    $this->em->rollback();

                    return RespuestaApi::errorValidacion(['lineas' => "El producto $idProducto no existe"]);
                }

                if ($producto->getStock() < $cantidad) {
                    $this->em->rollback();

                    return RespuestaApi::error(409, sprintf(
                        'No hay stock suficiente de %s (quedan %d)',
                        $producto->getNombre(),
                        $producto->getStock(),
                    ));
                }

                $producto->setStock($producto->getStock() - $cantidad);
                $pedido->addLinea((new PedidoProducto())->setProducto($producto)->setCantidad($cantidad));
            }

            $this->em->persist($pedido);
            $this->em->flush();
            $this->em->commit();
        } catch (\Throwable $error) {
            $this->em->rollback();
            throw $error;
        }

        return $this->json($this->presenter->detalle($pedido), Response::HTTP_CREATED);
    }

    /** PUT /api/pedidos/{id}/cancelar — solo si está pendiente o preparando; devuelve el stock */
    #[Route('/{id}/cancelar', name: 'api_pedido_cancelar', requirements: ['id' => '\d+'], methods: ['PUT'])]
    public function cancelar(#[CurrentUser] Usuario $usuario, int $id): JsonResponse
    {
        $pedido = $this->pedidoDe($usuario, $id);
        if (!$pedido) {
            return RespuestaApi::error(404, 'El pedido no existe');
        }

        if (!in_array($pedido->getEstado(), ['pendiente', 'preparando'], true)) {
            return RespuestaApi::error(409, 'Este pedido ya no se puede cancelar (está ' . $pedido->getEstado() . ')');
        }

        $this->em->wrapInTransaction(function () use ($pedido) {
            foreach ($pedido->getLineas() as $linea) {
                $producto = $linea->getProducto();
                $this->em->lock($producto, LockMode::PESSIMISTIC_WRITE);
                $producto->setStock($producto->getStock() + $linea->getCantidad());
            }
            $pedido->setEstado('cancelado');
        });

        return $this->json($this->presenter->detalle($pedido));
    }

    /** El pedido solo se devuelve si es del cliente (a través de su domicilio, como en el E-R) */
    private function pedidoDe(Usuario $usuario, int $id): ?Pedido
    {
        $pedido = $this->em->find(Pedido::class, $id);

        return $pedido && $pedido->getCliente() === $usuario ? $pedido : null;
    }
}
