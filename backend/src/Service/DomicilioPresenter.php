<?php

namespace App\Service;

use App\Entity\Domicilio;

class DomicilioPresenter
{
    public function presentar(Domicilio $domicilio): array
    {
        $d = $domicilio->getDireccion();

        return [
            'id' => $domicilio->getId(),
            'fecha_alta' => $domicilio->getFechaAlta()->format('Y-m-d'),
            'fecha_baja' => $domicilio->getFechaBaja()?->format('Y-m-d'),
            'activo' => $domicilio->isActivo(),
            'direccion' => [
                'calle' => $d->getCalle(),
                'numero' => $d->getNumero(),
                'piso' => $d->getPiso(),
                'codigo_postal' => $d->getCodigoPostal(),
                'ciudad' => $d->getCiudad(),
                'provincia' => $d->getProvincia(),
            ],
            // Como en la cesta del mockup: «Gran Vía 12, 3ºB · Bilbao»
            'texto' => trim(sprintf('%s %s, %s', $d->getCalle(), $d->getNumero(), $d->getPiso() ?? ''), ', ') . ' · ' . $d->getCiudad(),
        ];
    }
}
