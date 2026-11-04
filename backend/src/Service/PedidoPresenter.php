<?php

namespace App\Service;

use App\Entity\Pedido;
use App\Entity\PedidoProducto;

class PedidoPresenter
{
    public function __construct(
        private ProductoPresenter $productos,
        private DomicilioPresenter $domicilios,
    ) {
    }

    /** Para el listado «Mis pedidos» */
    public function resumen(Pedido $pedido): array
    {
        $unidades = 0;
        foreach ($pedido->getLineas() as $linea) {
            $unidades += $linea->getCantidad();
        }
        $primera = $pedido->getLineas()->first();

        return [
            'id' => $pedido->getId(),
            'fecha' => $pedido->getFecha()->format(DATE_ATOM),
            'estado' => $pedido->getEstado(),
            'total' => $pedido->getTotal(),
            'unidades' => $unidades,
            // Para la miniatura de la tarjeta
            'primer_producto' => $primera ? $primera->getProducto()->getNombre() : null,
            'imagen_url' => $primera ? $this->productos->url($primera->getProducto()->getImagen()) : null,
            'se_puede_cancelar' => in_array($pedido->getEstado(), ['pendiente', 'pagado'], true),
        ];
    }

    /** Para el detalle de un pedido */
    public function detalle(Pedido $pedido): array
    {
        return $this->resumen($pedido) + [
            'domicilio' => $this->domicilios->presentar($pedido->getDomicilio()),
            'lineas' => array_map(fn (PedidoProducto $l) => [
                'id' => $l->getId(),
                'producto' => $this->productos->resumen($l->getProducto()),
                'cantidad' => $l->getCantidad(),
                'precio_unitario' => $l->getPrecioUnitario(),
                'subtotal' => $l->getSubtotal(),
            ], $pedido->getLineas()->toArray()),
        ];
    }
}
