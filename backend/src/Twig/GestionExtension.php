<?php

namespace App\Twig;

use App\Entity\Alquiler;
use App\Entity\Pedido;
use App\Entity\Reparacion;
use Doctrine\ORM\EntityManagerInterface;
use Twig\Extension\AbstractExtension;
use Twig\TwigFilter;
use Twig\TwigFunction;

/** Funciones y filtros que usan las plantillas de la web de gestión */
class GestionExtension extends AbstractExtension
{
    private ?array $contadores = null;

    public function __construct(private EntityManagerInterface $em)
    {
    }

    public function getFunctions(): array
    {
        return [new TwigFunction('menu_contadores', [$this, 'contadores'])];
    }

    public function getFilters(): array
    {
        return [
            new TwigFilter('miniatura', [$this, 'miniatura']),
            new TwigFilter('iniciales', [$this, 'iniciales']),
        ];
    }

    /** Números del menú: reparaciones en curso, alquileres vencidos y pedidos pendientes */
    public function contadores(): array
    {
        if ($this->contadores === null) {
            $reparaciones = array_filter(
                $this->em->getRepository(Reparacion::class)->findAll(),
                fn (Reparacion $r) => !in_array($r->getEstadoActual(), ['entregada', 'cancelada'], true),
            );
            $vencidos = array_filter(
                $this->em->getRepository(Alquiler::class)->findAll(),
                fn (Alquiler $a) => $a->getEstado() === 'retrasado',
            );
            $this->contadores = [
                'reparaciones' => count($reparaciones),
                'vencidos' => count($vencidos),
                'pendientes' => $this->em->getRepository(Pedido::class)->count(['estado' => 'pendiente']),
            ];
        }

        return $this->contadores;
    }

    /** /uploads/productos/foto.jpg → /uploads/productos/foto_mini.jpg (la que hace el worker) */
    public function miniatura(?string $ruta): ?string
    {
        if ($ruta === null || $ruta === '') {
            return null;
        }
        $punto = strrpos($ruta, '.');

        return $punto === false ? $ruta : substr($ruta, 0, $punto) . '_mini' . substr($ruta, $punto);
    }

    /** «Iker Goikoetxea» → «IG» */
    public function iniciales(?object $persona): string
    {
        if ($persona === null || !method_exists($persona, 'getNombre')) {
            return '';
        }

        return mb_strtoupper(mb_substr((string) $persona->getNombre(), 0, 1) . mb_substr((string) $persona->getApellido1(), 0, 1));
    }
}
