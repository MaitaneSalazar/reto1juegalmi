<?php

namespace App\Service;

use App\Entity\FotoReparacion;
use App\Entity\HistorialEstado;
use App\Entity\Reparacion;
use App\Entity\TrabajadorDepartamento;
use Doctrine\ORM\EntityManagerInterface;

class ReparacionPresenter
{
    /** Los 5 pasos de la pantalla 09, en orden */
    public const PASOS = [
        'recibida' => 'Recibida',
        'diagnostico' => 'Diagnóstico',
        'en_reparacion' => 'En reparación',
        'lista_para_recoger' => 'Lista para recoger',
        'entregada' => 'Entregada',
    ];

    public function __construct(
        private ProductoPresenter $productos,
        private EntityManagerInterface $em,
    ) {
    }

    /** Cuándo pasó a «entregada» (la última vez), en ISO 8601; null si aún no se ha entregado */
    private function fechaEntrega(Reparacion $reparacion): ?string
    {
        $fecha = null;
        foreach ($reparacion->getHistorial() as $paso) {
            if ($paso->getEstado() === 'entregada' && ($fecha === null || $paso->getFechaHora() > $fecha)) {
                $fecha = $paso->getFechaHora();
            }
        }

        return $fecha?->format(DATE_ATOM);
    }

    /** Para el listado y la tarjeta de Inicio */
    public function resumen(Reparacion $reparacion): array
    {
        $estado = $reparacion->getEstadoActual();
        $paso = array_search($estado, array_keys(self::PASOS), true);

        return [
            'id' => $reparacion->getId(),
            'numero' => sprintf('Nº %04d', $reparacion->getId()),
            'tipo_dispositivo' => $reparacion->getTipoDispositivo(),
            'marca' => $reparacion->getMarca(),
            'modelo' => $reparacion->getModelo(),
            'estado' => $estado,
            'estado_texto' => self::PASOS[$estado] ?? 'Cancelada',
            'paso' => $paso === false ? null : $paso + 1,       // «3/5»; null si está cancelada
            'total_pasos' => count(self::PASOS),
            'fecha' => $reparacion->getHistorial()->first()?->getFechaHora()->format(DATE_ATOM),
            'se_puede_cancelar' => $estado === 'recibida',
            'presupuesto' => $reparacion->getPresupuesto(),          // null hasta que la tienda lo ponga
            'fecha_entrega' => $this->fechaEntrega($reparacion),      // null hasta que se entregue
        ];
    }

    /** Para la pantalla 09 (seguimiento) */
    public function detalle(Reparacion $reparacion): array
    {
        $historial = $reparacion->getHistorial()->toArray();

        // Fecha y descripción de cada paso (la última vez que se pasó por él)
        $hechos = [];
        foreach ($historial as $entrada) {
            $hechos[$entrada->getEstado()] = $entrada;
        }

        $pasos = [];
        foreach (self::PASOS as $clave => $texto) {
            $entrada = $hechos[$clave] ?? null;
            $pasos[] = [
                'estado' => $clave,
                'texto' => $texto,
                'hecho' => $entrada !== null,
                'actual' => $reparacion->getEstadoActual() === $clave,
                'fecha' => $entrada?->getFechaHora()->format('Y-m-d'),
                'descripcion' => $entrada?->getDescripcion(),
            ];
        }

        $trabajador = $reparacion->getTrabajadorActual();

        return $this->resumen($reparacion) + [
            'componente' => $reparacion->getComponente(),
            'descripcion_averia' => $reparacion->getDescripcionAveria(),
            'presupuesto' => $reparacion->getPresupuesto(),
            'pasos' => $pasos,
            'historial' => array_map(fn (HistorialEstado $h) => [
                'estado' => $h->getEstado(),
                'fecha_hora' => $h->getFechaHora()->format(DATE_ATOM),
                'descripcion' => $h->getDescripcion(),
            ], $historial),
            'trabajador' => $trabajador ? [
                'nombre_completo' => trim($trabajador->getNombre() . ' ' . $trabajador->getApellido1()),
                'cargo' => $trabajador->getCargo(),
                'telefono' => $trabajador->getTelefono(),
                'departamento' => $this->departamentoDe($trabajador),
            ] : null,
            'fotos' => array_map(fn (FotoReparacion $f) => [
                'id' => $f->getId(),
                'url' => $this->productos->url($f->getRuta()),
                'miniatura_url' => $this->productos->miniatura($f->getRuta()),
                'fecha_subida' => $f->getFechaSubida()->format(DATE_ATOM),
            ], $reparacion->getFotos()->toArray()),
        ];
    }

    /** Como en el E-R: el departamento de la reparación es el del trabajador asignado */
    private function departamentoDe(\App\Entity\Trabajador $trabajador): ?string
    {
        $pertenencia = $this->em->getRepository(TrabajadorDepartamento::class)->findOneBy(
            ['trabajador' => $trabajador, 'fechaFin' => null],
            ['fechaInicio' => 'ASC'],
        );

        return $pertenencia?->getDepartamento()->getNombre();
    }
}
