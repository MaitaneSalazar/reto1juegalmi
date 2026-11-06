<?php

namespace App\Service;

use App\Entity\Alquiler;
use App\Entity\AlquilerVideojuego;

class AlquilerPresenter
{
    public function __construct(private ProductoPresenter $productos)
    {
    }

    public function presentar(Alquiler $alquiler): array
    {
        $hoy = new \DateTimeImmutable('today');
        $fin = $alquiler->getFechaFinPrevista();

        return [
            'id' => $alquiler->getId(),
            'fecha_inicio' => $alquiler->getFechaInicio()->format('Y-m-d'),
            'fecha_fin_prevista' => $fin->format('Y-m-d'),
            'estado' => $alquiler->getEstado(),
            // Positivo: días que quedan. Negativo: días de retraso.
            'dias_restantes' => (int) $hoy->diff($fin)->format('%r%a'),
            'importe' => $alquiler->getImporte(),
            'lineas' => array_map(fn (AlquilerVideojuego $l) => [
                'id' => $l->getId(),
                'videojuego' => $this->productos->resumen($l->getVideojuego()),
                'precio_dia' => $l->getPrecio(),
                'fecha_devolucion' => $l->getFechaDevolucion()?->format('Y-m-d'),
                'devuelto' => $l->getFechaDevolucion() !== null,
                'dias' => $l->getDias(),
                'importe' => $l->getImporte(),
            ], $alquiler->getLineas()->toArray()),
        ];
    }
}
