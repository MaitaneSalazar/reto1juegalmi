<?php

namespace App\Controller\Gestion;

use App\Entity\Cliente;
use App\Entity\FotoReparacion;
use App\Entity\Reparacion;
use App\Entity\Trabajador;
use App\Entity\TrabajadorReparacion;
use App\Service\SubidaImagenes;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Validator\Validator\ValidatorInterface;

/** Pantallas 07 y 08 del mockup: tablero de reparaciones y detalle */
#[Route('/gestion/reparaciones')]
class ReparacionesController extends AbstractController
{
    public const ESTADOS = [
        'recibida' => 'Recibida', 'diagnostico' => 'Diagnóstico', 'en_reparacion' => 'En reparación',
        'lista_para_recoger' => 'Lista para recoger', 'entregada' => 'Entregada',
    ];
    public const DISPOSITIVOS = [
        'consola' => 'Consola', 'movil' => 'Móvil', 'tablet' => 'Tablet', 'ordenador' => 'Ordenador',
        'mando' => 'Mando', 'auriculares' => 'Auriculares', 'reloj' => 'Reloj', 'otro' => 'Otro',
    ];
    public const ICONOS = [
        'consola' => 'gamepad-2', 'movil' => 'smartphone', 'tablet' => 'tablet', 'ordenador' => 'laptop',
        'mando' => 'gamepad', 'auriculares' => 'headphones', 'reloj' => 'watch', 'otro' => 'ellipsis',
    ];
    private const SIGUIENTE = [
        'recibida' => 'diagnostico', 'diagnostico' => 'en_reparacion',
        'en_reparacion' => 'lista_para_recoger', 'lista_para_recoger' => 'entregada',
    ];
    /** Días en el mismo estado a partir de los que la tarjeta sale en rojo */
    private const DIAS_AVISO = 5;

    public function __construct(private EntityManagerInterface $em)
    {
    }

    // ---------------------------------------------------------------- Tablero (07)

    #[Route('', name: 'gestion_reparaciones', methods: ['GET'])]
    public function tablero(Request $request): Response
    {
        $q = mb_strtolower(trim((string) $request->query->get('q', '')));
        $columnas = array_fill_keys(array_keys(self::ESTADOS), []);
        $hoy = new \DateTimeImmutable('today');

        foreach ($this->em->getRepository(Reparacion::class)->findBy([], ['id' => 'DESC']) as $reparacion) {
            $estado = $reparacion->getEstadoActual();
            if (!isset($columnas[$estado])) {
                continue; // las canceladas no salen en el tablero
            }
            $desde = $reparacion->getHistorial()->last()?->getFechaHora();
            if ($estado === 'entregada' && ($desde === null || $desde < $hoy)) {
                continue; // de las entregadas, solo las de hoy
            }
            if ($q !== '' && !str_contains($this->textoBusqueda($reparacion), $q)) {
                continue;
            }
            $columnas[$estado][] = [
                'r' => $reparacion,
                'dias' => $desde ? (int) $hoy->diff($desde->setTime(0, 0))->days : 0,
            ];
        }

        return $this->render('gestion/reparaciones/tablero.html.twig', [
            'columnas' => $columnas,
            'estados' => self::ESTADOS,
            'dispositivos' => self::DISPOSITIVOS,
            'q' => $q,
            'dias_aviso' => self::DIAS_AVISO,
        ]);
    }

    // ---------------------------------------------------------------- Registrar entrada

    #[Route('/nueva', name: 'gestion_reparacion_nueva', methods: ['GET', 'POST'])]
    public function nueva(Request $request, ValidatorInterface $validator): Response
    {
        $v = ['tipo_dispositivo' => 'consola'];
        $errores = [];

        if ($request->isMethod('POST')) {
            $v = $request->request->all();
            if (!$this->isCsrfTokenValid('reparacion', (string) $request->request->get('_token'))) {
                $errores['_'] = 'El formulario ha caducado. Vuelve a intentarlo.';
            }

            $cliente = $this->em->find(Cliente::class, (int) ($v['cliente'] ?? 0));
            if ($cliente === null) {
                $errores['cliente'] = 'Elige el cliente.';
            }
            if (!in_array($v['tipo_dispositivo'] ?? '', Reparacion::TIPOS_DISPOSITIVO, true)) {
                $errores['tipo_dispositivo'] = 'Elige el tipo de dispositivo.';
            }
            foreach (['marca' => 'Escribe la marca.', 'modelo' => 'Escribe el modelo.', 'descripcion_averia' => 'Describe la avería.'] as $campo => $mensaje) {
                if (trim((string) ($v[$campo] ?? '')) === '') {
                    $errores[$campo] = $mensaje;
                }
            }
            $presupuesto = trim((string) ($v['presupuesto'] ?? ''));
            $importe = $presupuesto === '' ? null : str_replace(',', '.', $presupuesto);
            if ($importe !== null && (!is_numeric($importe) || $importe < 0)) {
                $errores['presupuesto'] = 'Escribe un importe válido, por ejemplo 35,00.';
            }

            if ($errores === []) {
                $reparacion = (new Reparacion())
                    ->setCliente($cliente)
                    ->setTipoDispositivo($v['tipo_dispositivo'])
                    ->setMarca(trim($v['marca']))
                    ->setModelo(trim($v['modelo']))
                    ->setComponente(trim((string) ($v['componente'] ?? '')) ?: null)
                    ->setDescripcionAveria(trim($v['descripcion_averia']))
                    ->setPresupuesto($importe === null ? null : (float) $importe);

                foreach ($validator->validate($reparacion) as $error) {
                    $errores[strtolower(preg_replace('/[A-Z]/', '_$0', $error->getPropertyPath()))] ??= $error->getMessage();
                }

                if ($errores === []) {
                    $this->em->persist($reparacion);
                    $tecnico = $this->em->find(Trabajador::class, (int) ($v['tecnico'] ?? 0));
                    if ($tecnico !== null) {
                        $this->asignar($reparacion, $tecnico);
                    }
                    $this->em->flush();
                    $this->addFlash('success', sprintf('Entrada registrada: reparación Nº %04d.', $reparacion->getId()));
                    return $this->redirectToRoute('gestion_reparacion', ['id' => $reparacion->getId()]);
                }
            }
        }

        return $this->render('gestion/reparaciones/nueva.html.twig', [
            'v' => $v,
            'errores' => $errores,
            'clientes' => $this->em->getRepository(Cliente::class)->findBy(['activo' => true], ['nombre' => 'ASC', 'apellido1' => 'ASC']),
            'trabajadores' => $this->trabajadores(),
            'dispositivos' => self::DISPOSITIVOS,
            'iconos' => self::ICONOS,
        ]);
    }

    // ---------------------------------------------------------------- Detalle (08)

    #[Route('/{id}', name: 'gestion_reparacion', requirements: ['id' => '\d+'], methods: ['GET'])]
    public function detalle(Reparacion $reparacion): Response
    {
        $estado = $reparacion->getEstadoActual();
        $fechas = [];
        foreach ($reparacion->getHistorial() as $paso) {
            $fechas[$paso->getEstado()] = $paso->getFechaHora();
        }
        $indice = array_search($estado, array_keys(self::ESTADOS), true);

        $asignacion = null;
        foreach ($reparacion->getAsignaciones() as $a) {
            if ($a->getFechaFin() === null) {
                $asignacion = $a;
            }
        }

        return $this->render('gestion/reparaciones/detalle.html.twig', [
            'reparacion' => $reparacion,
            'estado' => $estado,
            'estados' => self::ESTADOS,
            'dispositivos' => self::DISPOSITIVOS,
            'fechas' => $fechas,
            'indice' => $indice === false ? -1 : $indice,
            'siguiente' => self::SIGUIENTE[$estado] ?? null,
            'cerrada' => in_array($estado, ['entregada', 'cancelada'], true),
            'entrada' => $reparacion->getFechaRecepcion(),
            'salida' => $fechas['entregada'] ?? null,
            'asignacion' => $asignacion,
            'trabajadores' => $this->trabajadores(),
            'aviso' => $this->textoAviso($reparacion),
            'mailto' => $this->mailto($reparacion),
        ]);
    }

    #[Route('/{id}/avanzar', name: 'gestion_reparacion_avanzar', requirements: ['id' => '\d+'], methods: ['POST'])]
    public function avanzar(Reparacion $reparacion, Request $request): Response
    {
        if ($this->comprobar($request)) {
            $siguiente = self::SIGUIENTE[$reparacion->getEstadoActual()] ?? null;
            if ($siguiente === null) {
                $this->addFlash('warning', 'Esta reparación ya está cerrada.');
            } else {
                $nota = trim((string) $request->request->get('nota', ''));
                $reparacion->cambiarEstado($siguiente, $nota === '' ? null : $nota);
                $this->em->flush();
                $this->addFlash('success', sprintf('La reparación pasa a «%s». El cliente ya lo ve en la app.', self::ESTADOS[$siguiente]));
            }
        }

        return $this->aDetalle($reparacion);
    }

    #[Route('/{id}/cancelar', name: 'gestion_reparacion_cancelar', requirements: ['id' => '\d+'], methods: ['POST'])]
    public function cancelar(Reparacion $reparacion, Request $request): Response
    {
        if ($this->comprobar($request)) {
            if (in_array($reparacion->getEstadoActual(), ['entregada', 'cancelada'], true)) {
                $this->addFlash('warning', 'Esta reparación ya está cerrada.');
            } else {
                $reparacion->cambiarEstado('cancelada', 'Cancelada por la tienda');
                $this->em->flush();
                $this->addFlash('success', 'Reparación cancelada. No se borra: queda en el historial.');
            }
        }

        return $this->aDetalle($reparacion);
    }

    #[Route('/{id}/presupuesto', name: 'gestion_reparacion_presupuesto', requirements: ['id' => '\d+'], methods: ['POST'])]
    public function presupuesto(Reparacion $reparacion, Request $request): Response
    {
        if ($this->comprobar($request)) {
            $texto = str_replace(',', '.', trim((string) $request->request->get('importe', '')));
            if ($texto !== '' && (!is_numeric($texto) || $texto < 0)) {
                $this->addFlash('danger', 'Escribe un importe válido, por ejemplo 35,00.');
            } else {
                $reparacion->setPresupuesto($texto === '' ? null : (float) $texto);
                $reparacion->setPresupuestoAceptado(match ((string) $request->request->get('aceptado')) {
                    '1' => true, '0' => false, default => null,
                });
                $this->em->flush();
                $this->addFlash('success', 'Presupuesto guardado.');
            }
        }

        return $this->aDetalle($reparacion);
    }

    #[Route('/{id}/tecnico', name: 'gestion_reparacion_tecnico', requirements: ['id' => '\d+'], methods: ['POST'])]
    public function tecnico(Reparacion $reparacion, Request $request): Response
    {
        if ($this->comprobar($request)) {
            $tecnico = $this->em->find(Trabajador::class, $request->request->getInt('tecnico'));
            if ($tecnico === null || !$tecnico->isActivo()) {
                $this->addFlash('danger', 'Elige un técnico.');
            } elseif ($tecnico === $reparacion->getTrabajadorActual()) {
                $this->addFlash('info', 'Ya estaba asignada a ' . $tecnico->getNombre() . '.');
            } else {
                $this->asignar($reparacion, $tecnico);
                $this->em->flush();
                $this->addFlash('success', 'Reparación asignada a ' . trim($tecnico->getNombre() . ' ' . $tecnico->getApellido1()) . '.');
            }
        }

        return $this->aDetalle($reparacion);
    }

    #[Route('/{id}/notas', name: 'gestion_reparacion_notas', requirements: ['id' => '\d+'], methods: ['POST'])]
    public function notas(Reparacion $reparacion, Request $request): Response
    {
        if ($this->comprobar($request)) {
            $notas = trim((string) $request->request->get('notas', ''));
            $reparacion->setNotasInternas($notas === '' ? null : $notas);
            $this->em->flush();
            $this->addFlash('success', 'Notas internas guardadas.');
        }

        return $this->aDetalle($reparacion);
    }

    #[Route('/{id}/avisar', name: 'gestion_reparacion_avisar', requirements: ['id' => '\d+'], methods: ['POST'])]
    public function avisar(Reparacion $reparacion, Request $request): Response
    {
        if ($this->comprobar($request)) {
            $reparacion->setAvisadoEn(new \DateTimeImmutable());
            $this->em->flush();
            $this->addFlash('success', 'Apuntado: cliente avisado hoy.');
        }

        return $this->aDetalle($reparacion);
    }

    #[Route('/{id}/fotos', name: 'gestion_reparacion_foto', requirements: ['id' => '\d+'], methods: ['POST'])]
    public function foto(Reparacion $reparacion, Request $request, SubidaImagenes $subida): Response
    {
        if ($this->comprobar($request)) {
            try {
                $foto = (new FotoReparacion())
                    ->setRuta($subida->subir($request->files->get('imagen'), 'soporte'))
                    ->setDelTaller(true);
                $reparacion->addFoto($foto);
                $this->em->persist($foto);
                $this->em->flush();
                $this->addFlash('success', 'Foto del taller añadida.');
            } catch (\InvalidArgumentException $e) {
                $this->addFlash('danger', $e->getMessage());
            }
        }

        return $this->aDetalle($reparacion);
    }

    #[Route('/{id}/resguardo', name: 'gestion_reparacion_resguardo', requirements: ['id' => '\d+'], methods: ['GET'])]
    public function resguardo(Reparacion $reparacion): Response
    {
        return $this->render('gestion/reparaciones/resguardo.html.twig', [
            'reparacion' => $reparacion,
            'dispositivos' => self::DISPOSITIVOS,
            'entrada' => $reparacion->getFechaRecepcion(),
            'estado' => self::ESTADOS[$reparacion->getEstadoActual()] ?? 'Cancelada',
        ]);
    }

    // ---------------------------------------------------------------- Ayudantes

    /** Cierra la asignación anterior y abre otra con el técnico nuevo (queda el historial) */
    private function asignar(Reparacion $reparacion, Trabajador $tecnico): void
    {
        $ahora = new \DateTimeImmutable();
        foreach ($reparacion->getAsignaciones() as $a) {
            if ($a->getFechaFin() === null) {
                $a->setFechaFin($ahora);
            }
        }
        $asignacion = (new TrabajadorReparacion())->setTrabajador($tecnico);
        $reparacion->addAsignacion($asignacion);
        $this->em->persist($asignacion);
    }

    private function trabajadores(): array
    {
        return $this->em->getRepository(Trabajador::class)->findBy(['activo' => true], ['nombre' => 'ASC']);
    }

    private function textoBusqueda(Reparacion $r): string
    {
        $c = $r->getCliente();
        return mb_strtolower(implode(' ', [
            sprintf('%04d', $r->getId()), $r->getMarca(), $r->getModelo(), $r->getDescripcionAveria(),
            self::DISPOSITIVOS[$r->getTipoDispositivo()] ?? '', $c?->getNombre(), $c?->getApellido1(),
        ]));
    }

    /** Texto del aviso al cliente según cómo va la reparación */
    private function textoAviso(Reparacion $r): string
    {
        $c = $r->getCliente();
        $equipo = trim($r->getMarca() . ' ' . $r->getModelo());
        $importe = $r->getPresupuesto() !== null ? number_format($r->getPresupuesto(), 2, ',', '.') . ' €' : null;

        $texto = $r->getEstadoActual() === 'lista_para_recoger'
            ? "Tu {$equipo} ya está listo. Puedes pasar a recogerlo por JuegAlmi (Gran Vía 12, Bilbao), de lunes a sábado de 10:00 a 20:30." . ($importe ? " Importe de la reparación: {$importe}." : '')
            : "Te escribimos por la reparación de tu {$equipo}. Estado actual: " . (self::ESTADOS[$r->getEstadoActual()] ?? 'Cancelada') . '.' . ($importe ? " Presupuesto: {$importe}." : '');

        return sprintf("Hola %s:\n\n%s\n\nNº de reparación: %04d\n\nUn saludo,\nJuegAlmi", $c?->getNombre(), $texto, $r->getId());
    }

    private function mailto(Reparacion $r): ?string
    {
        $email = $r->getCliente()?->getEmail();
        if (!$email) {
            return null;
        }

        return 'mailto:' . $email
            . '?subject=' . rawurlencode(sprintf('Tu reparación Nº %04d · JuegAlmi', $r->getId()))
            . '&body=' . rawurlencode($this->textoAviso($r));
    }

    private function comprobar(Request $request): bool
    {
        if ($this->isCsrfTokenValid('reparacion', (string) $request->request->get('_token'))) {
            return true;
        }
        $this->addFlash('danger', 'El formulario ha caducado. Vuelve a intentarlo.');
        return false;
    }

    private function aDetalle(Reparacion $reparacion): Response
    {
        return $this->redirectToRoute('gestion_reparacion', ['id' => $reparacion->getId()]);
    }
}
