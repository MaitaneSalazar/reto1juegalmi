<?php

namespace App\Service;

use App\Entity\Consola;
use App\Entity\Movil;
use App\Entity\Producto;
use App\Entity\Tablet;
use App\Entity\Videojuego;
use Symfony\Component\HttpFoundation\RequestStack;

/**
 * Datos de un producto que devuelve la API.
 * resumen(): para los listados (tarjetas). detalle(): para la ficha.
 */
class ProductoPresenter
{
    public function __construct(private RequestStack $requestStack)
    {
    }

    public function resumen(Producto $producto): array
    {
        $datos = [
            'id' => $producto->getId(),
            'tipo' => $producto->getTipo(),
            'nombre' => $producto->getNombre(),
            'empresa' => $producto->getEmpresa()?->getNombre(),
            'precio_venta' => $producto->getPrecioVenta(),
            'stock' => $producto->getStock(),
            'disponible' => $producto->getStock() > 0,
            'imagen_url' => $this->url($producto->getImagen()),
        ];

        if ($producto instanceof Videojuego) {
            $datos['plataforma'] = $producto->getPlataforma();
            $datos['precio_alquiler_dia'] = $producto->getPrecioAlquilerDia();
        }

        return $datos;
    }

    public function detalle(Producto $producto): array
    {
        $datos = $this->resumen($producto);
        $datos['descripcion'] = $producto->getDescripcion();

        if ($producto instanceof Videojuego) {
            $datos += [
                'genero' => $producto->getGenero(),
                'pegi' => $producto->getPegi(),
                'copias_alquiler' => $producto->getCopiasAlquiler(),
            ];
        } elseif ($producto instanceof Consola) {
            $datos += [
                'almacenamiento_gb' => $producto->getAlmacenamientoGb(),
                'color' => $producto->getColor(),
                'edicion' => $producto->getEdicion(),
            ];
        } elseif ($producto instanceof Movil) {
            $datos += [
                'pantalla_pulgadas' => $producto->getPantallaPulgadas(),
                'ram_gb' => $producto->getRamGb(),
                'almacenamiento_gb' => $producto->getAlmacenamientoGb(),
                'sistema_operativo' => $producto->getSistemaOperativo(),
                'bateria_mah' => $producto->getBateriaMah(),
            ];
        } elseif ($producto instanceof Tablet) {
            $datos += [
                'pantalla_pulgadas' => $producto->getPantallaPulgadas(),
                'almacenamiento_gb' => $producto->getAlmacenamientoGb(),
                'sistema_operativo' => $producto->getSistemaOperativo(),
                'conectividad' => $producto->getConectividad(),
            ];
        }

        return $datos;
    }

    /** Convierte una ruta guardada (/uploads/...) en una dirección completa para Glide o Ionic */
    public function url(?string $ruta): ?string
    {
        if ($ruta === null || $ruta === '') {
            return null;
        }
        if (str_starts_with($ruta, 'http')) {
            return $ruta;
        }

        $request = $this->requestStack->getCurrentRequest();

        return $request ? $request->getSchemeAndHttpHost() . $ruta : $ruta;
    }
}
