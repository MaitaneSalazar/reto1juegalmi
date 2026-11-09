<?php

namespace App\Controller\Gestion;

use App\Entity\Pedido;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

/** Pantalla 10 del mockup: pedidos con el panel del pedido elegido */
#[Route('/gestion/pedidos')]
class PedidosController extends AbstractController
{
    public const ESTADOS = ['pendiente' => 'Pendiente', 'preparando' => 'Preparando', 'enviado' => 'Enviado', 'entregado' => 'Entregado', 'cancelado' => 'Cancelado'];
    private const SIGUIENTE = ['pendiente' => 'preparando', 'preparando' => 'enviado', 'enviado' => 'entregado'];
    private const SE_PUEDE_CANCELAR = ['pendiente', 'preparando'];

    public function __construct(private EntityManagerInterface $em)
    {
    }

    #[Route('', name: 'gestion_pedidos', methods: ['GET'])]
    public function listado(Request $request): Response
    {
        $ver = (string) $request->query->get('ver', 'todos');
        $ver = isset(self::ESTADOS[$ver]) ? $ver : 'todos';

        $criterio = $ver === 'todos' ? [] : ['estado' => $ver];
        $pedidos = $this->em->getRepository(Pedido::class)->findBy($criterio, ['fecha' => 'DESC', 'id' => 'DESC']);

        // El pedido del panel: el que se ha pulsado o, si no, el primero de la lista
        $elegido = $request->query->getInt('id') ? $this->em->find(Pedido::class, $request->query->getInt('id')) : ($pedidos[0] ?? null);

        return $this->render('gestion/pedidos/listado.html.twig', [
            'pedidos' => $pedidos,
            'ver' => $ver,
            'elegido' => $elegido,
            'estados' => self::ESTADOS,
            'siguiente' => $elegido ? (self::SIGUIENTE[$elegido->getEstado()] ?? null) : null,
            'se_puede_cancelar' => $elegido && in_array($elegido->getEstado(), self::SE_PUEDE_CANCELAR, true),
        ]);
    }

    #[Route('/{id}/avanzar', name: 'gestion_pedido_avanzar', requirements: ['id' => '\d+'], methods: ['POST'])]
    public function avanzar(Pedido $pedido, Request $request): Response
    {
        if ($this->comprobar($request)) {
            $siguiente = self::SIGUIENTE[$pedido->getEstado()] ?? null;
            if ($siguiente === null) {
                $this->addFlash('warning', 'Este pedido ya está cerrado.');
            } else {
                $pedido->setEstado($siguiente);
                $this->em->flush();
                $this->addFlash('success', sprintf('Pedido #%d marcado como «%s».', $pedido->getId(), self::ESTADOS[$siguiente]));
            }
        }

        return $this->volver($request, $pedido);
    }

    /** Igual que la API: solo pendiente o preparando, y se devuelve el stock */
    #[Route('/{id}/cancelar', name: 'gestion_pedido_cancelar', requirements: ['id' => '\d+'], methods: ['POST'])]
    public function cancelar(Pedido $pedido, Request $request): Response
    {
        if ($this->comprobar($request)) {
            if (!in_array($pedido->getEstado(), self::SE_PUEDE_CANCELAR, true)) {
                $this->addFlash('warning', 'Solo se pueden cancelar pedidos pendientes o en preparación.');
            } else {
                foreach ($pedido->getLineas() as $linea) {
                    $producto = $linea->getProducto();
                    $producto->setStock($producto->getStock() + $linea->getCantidad());
                }
                $pedido->setEstado('cancelado');
                $this->em->flush();
                $this->addFlash('success', sprintf('Pedido #%d cancelado. El stock se ha devuelto.', $pedido->getId()));
            }
        }

        return $this->volver($request, $pedido);
    }

    private function comprobar(Request $request): bool
    {
        if ($this->isCsrfTokenValid('pedido', (string) $request->request->get('_token'))) {
            return true;
        }
        $this->addFlash('danger', 'El formulario ha caducado. Vuelve a intentarlo.');
        return false;
    }

    private function volver(Request $request, Pedido $pedido): Response
    {
        $ver = (string) $request->request->get('ver', 'todos');
        return $this->redirectToRoute('gestion_pedidos', ['ver' => $ver !== 'todos' ? $ver : null, 'id' => $pedido->getId()]);
    }
}
