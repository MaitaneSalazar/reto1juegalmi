<?php

namespace App\Controller\Gestion;

use App\Entity\Alquiler;
use App\Entity\AlquilerVideojuego;
use App\Entity\Cliente;
use App\Entity\Videojuego;
use Doctrine\DBAL\LockMode;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

/** Pantalla 09 del mockup: alquileres */
#[Route('/gestion/alquileres')]
class AlquileresController extends AbstractController
{
    private const DIAS_MAX = 30;

    public function __construct(private EntityManagerInterface $em)
    {
    }

    #[Route('', name: 'gestion_alquileres', methods: ['GET'])]
    public function listado(Request $request): Response
    {
        $pestana = (string) $request->query->get('ver', 'activos');
        $pestana = in_array($pestana, ['activos', 'vencidos', 'devueltos'], true) ? $pestana : 'activos';
        $q = mb_strtolower(trim((string) $request->query->get('q', '')));
        $hoy = new \DateTimeImmutable('today');

        $filas = [];
        $cuentas = ['activos' => 0, 'vencidos' => 0, 'devueltos' => 0];
        foreach ($this->em->getRepository(Alquiler::class)->findBy([], ['fechaInicio' => 'DESC']) as $alquiler) {
            $estado = $alquiler->getEstado();
            $grupo = $estado === 'devuelto' ? 'devueltos' : 'activos';
            $cuentas[$grupo]++;
            if ($estado === 'retrasado') {
                $cuentas['vencidos']++;
            }

            $enPestana = match ($pestana) {
                'activos' => $estado !== 'devuelto',
                'vencidos' => $estado === 'retrasado',
                default => $estado === 'devuelto',
            };
            if (!$enPestana) {
                continue;
            }

            $juegos = array_map(fn (AlquilerVideojuego $l) => $l->getVideojuego(), $alquiler->getLineas()->toArray());
            $cliente = $alquiler->getCliente();
            if ($q !== '') {
                $texto = mb_strtolower(sprintf('%04d %s %s %s', $alquiler->getId(), $cliente?->getNombre(), $cliente?->getApellido1(),
                    implode(' ', array_map(fn ($j) => $j->getNombre(), $juegos))));
                if (!str_contains($texto, $q)) {
                    continue;
                }
            }

            $fin = $alquiler->getFechaFinPrevista()?->setTime(0, 0);
            $dias = $fin ? (int) $hoy->diff($fin)->format('%r%a') : 0;
            $filas[] = [
                'a' => $alquiler,
                'estado' => $estado,
                'juegos' => $juegos,
                'texto' => match (true) {
                    $estado === 'devuelto' => 'Devuelto',
                    $dias < 0 => sprintf('%d día%s de retraso', -$dias, -$dias === 1 ? '' : 's'),
                    $dias === 0 => 'Termina hoy',
                    default => sprintf('Quedan %d día%s', $dias, $dias === 1 ? '' : 's'),
                },
            ];
        }

        // Desde el Resumen («Avisar» de un alquiler vencido) se llega con ?avisar=ID
        $avisar = $request->query->getInt('avisar') ? $this->em->find(Alquiler::class, $request->query->getInt('avisar')) : null;

        return $this->render('gestion/alquileres/listado.html.twig', [
            'filas' => $filas,
            'cuentas' => $cuentas,
            'pestana' => $pestana,
            'q' => $q,
            'copias' => $this->copiasLibres(),
            'avisar' => $avisar,
            'mailto' => $avisar ? $this->mailto($avisar) : null,
        ]);
    }

    #[Route('/{id}/devolver', name: 'gestion_alquiler_devolver', requirements: ['id' => '\d+'], methods: ['POST'])]
    public function devolver(Alquiler $alquiler, Request $request): Response
    {
        if (!$this->isCsrfTokenValid('alquiler', (string) $request->request->get('_token'))) {
            $this->addFlash('danger', 'El formulario ha caducado. Vuelve a intentarlo.');
        } else {
            $ahora = new \DateTimeImmutable();
            $devueltos = 0;
            foreach ($alquiler->getLineas() as $linea) {
                if ($linea->getFechaDevolucion() === null) {
                    $linea->setFechaDevolucion($ahora);
                    $devueltos++;
                }
            }
            $this->em->flush();
            $this->addFlash($devueltos ? 'success' : 'warning', $devueltos
                ? sprintf('Alquiler #%04d devuelto: %d juego%s vuelve%s a estar libre%s.', $alquiler->getId(), $devueltos, $devueltos > 1 ? 's' : '', $devueltos > 1 ? 'n' : '', $devueltos > 1 ? 's' : '')
                : 'Este alquiler ya estaba devuelto.');
        }

        return $this->redirect($this->volver($request));
    }

    #[Route('/{id}/ampliar', name: 'gestion_alquiler_ampliar', requirements: ['id' => '\d+'], methods: ['POST'])]
    public function ampliar(Alquiler $alquiler, Request $request): Response
    {
        $dias = $request->request->getInt('dias');
        if (!$this->isCsrfTokenValid('alquiler', (string) $request->request->get('_token'))) {
            $this->addFlash('danger', 'El formulario ha caducado. Vuelve a intentarlo.');
        } elseif ($alquiler->getEstado() === 'devuelto') {
            $this->addFlash('warning', 'Este alquiler ya está devuelto.');
        } elseif ($dias < 1 || $dias > self::DIAS_MAX) {
            $this->addFlash('danger', 'Elige entre 1 y ' . self::DIAS_MAX . ' días.');
        } else {
            // Si ya está vencido se cuenta desde hoy; si no, desde la fecha de fin que tenía
            $ahora = new \DateTimeImmutable();
            $fin = $alquiler->getFechaFinPrevista();
            $base = $fin !== null && $fin > $ahora ? $fin : $ahora;
            $alquiler->setFechaFinPrevista($base->modify('+' . $dias . ' days'));
            $this->em->flush();
            $this->addFlash('success', sprintf('Alquiler #%04d ampliado: nueva devolución el %s.', $alquiler->getId(), $alquiler->getFechaFinPrevista()->format('d/m/Y')));
        }

        return $this->redirect($this->volver($request));
    }

    #[Route('/nuevo', name: 'gestion_alquiler_nuevo', methods: ['GET', 'POST'])]
    public function nuevo(Request $request): Response
    {
        $v = ['dias' => 3, 'juegos' => []];
        $errores = [];

        if ($request->isMethod('POST')) {
            $v = ['cliente' => $request->request->get('cliente'), 'dias' => $request->request->getInt('dias'),
                  'juegos' => array_map('intval', $request->request->all('juegos'))];

            if (!$this->isCsrfTokenValid('alquiler', (string) $request->request->get('_token'))) {
                $errores['_'] = 'El formulario ha caducado. Vuelve a intentarlo.';
            }
            $cliente = $this->em->find(Cliente::class, (int) $v['cliente']);
            if ($cliente === null) {
                $errores['cliente'] = 'Elige el cliente.';
            }
            if ($v['dias'] < 1 || $v['dias'] > self::DIAS_MAX) {
                $errores['dias'] = 'Entre 1 y ' . self::DIAS_MAX . ' días.';
            }
            if ($v['juegos'] === []) {
                $errores['juegos'] = 'Elige al menos un videojuego.';
            }

            if ($errores === []) {
                try {
                    $alquiler = $this->em->wrapInTransaction(function () use ($cliente, $v) {
                        $inicio = new \DateTimeImmutable();
                        $alquiler = (new Alquiler())
                            ->setCliente($cliente)
                            ->setFechaInicio($inicio)
                            ->setFechaFinPrevista($inicio->modify('+' . $v['dias'] . ' days'));

                        foreach (array_unique($v['juegos']) as $id) {
                            // Bloqueo para que dos personas no alquilen la última copia a la vez
                            $juego = $this->em->find(Videojuego::class, $id, LockMode::PESSIMISTIC_WRITE);
                            if ($juego === null || !$juego->isActivo()) {
                                throw new \DomainException('Uno de los juegos ya no está disponible.');
                            }
                            if ($juego->getCopiasAlquiler() - $this->alquiladas($juego) < 1) {
                                throw new \DomainException(sprintf('No quedan copias libres de «%s».', $juego->getNombre()));
                            }
                            $linea = (new AlquilerVideojuego())->setVideojuego($juego)->setPrecio((float) $juego->getPrecioAlquilerDia());
                            $alquiler->addLinea($linea);
                            $this->em->persist($linea);
                        }

                        $this->em->persist($alquiler);
                        return $alquiler;
                    });

                    $this->addFlash('success', sprintf('Alquiler #%04d creado. Devolución el %s.', $alquiler->getId(), $alquiler->getFechaFinPrevista()->format('d/m')));
                    return $this->redirectToRoute('gestion_alquileres');
                } catch (\DomainException $e) {
                    $errores['juegos'] = $e->getMessage();
                }
            }
        }

        return $this->render('gestion/alquileres/nuevo.html.twig', [
            'v' => $v,
            'errores' => $errores,
            'clientes' => $this->em->getRepository(Cliente::class)->findBy(['activo' => true], ['nombre' => 'ASC', 'apellido1' => 'ASC']),
            'copias' => $this->copiasLibres(),
            'dias_max' => self::DIAS_MAX,
        ]);
    }

    /** Videojuegos que se alquilan, con cuántas copias quedan libres */
    private function copiasLibres(): array
    {
        $juegos = $this->em->getRepository(Videojuego::class)->createQueryBuilder('v')
            ->where('v.activo = true')->andWhere('v.copiasAlquiler > 0')->orderBy('v.nombre', 'ASC')
            ->getQuery()->getResult();

        return array_map(fn (Videojuego $j) => [
            'juego' => $j,
            'total' => $j->getCopiasAlquiler(),
            'libres' => max(0, $j->getCopiasAlquiler() - $this->alquiladas($j)),
        ], $juegos);
    }

    /** Copias de un juego que están ahora mismo alquiladas (sin devolver) */
    private function alquiladas(Videojuego $juego): int
    {
        return (int) $this->em->createQueryBuilder()
            ->select('COUNT(l.id)')->from(AlquilerVideojuego::class, 'l')
            ->where('l.videojuego = :juego')->andWhere('l.fechaDevolucion IS NULL')
            ->setParameter('juego', $juego)->getQuery()->getSingleScalarResult();
    }

    private function mailto(Alquiler $a): ?string
    {
        $cliente = $a->getCliente();
        if (!$cliente?->getEmail()) {
            return null;
        }
        $juegos = implode(', ', array_map(fn ($l) => $l->getVideojuego()->getNombre(),
            array_filter($a->getLineas()->toArray(), fn ($l) => $l->getFechaDevolucion() === null)));
        $cuerpo = sprintf("Hola %s:\n\nEl plazo de tu alquiler de %s terminó el %s. Puedes devolverlo en JuegAlmi (Gran Vía 12, Bilbao), de lunes a sábado de 10:00 a 20:30.\n\nNº de alquiler: %04d\n\nUn saludo,\nJuegAlmi",
            $cliente->getNombre(), $juegos ?: 'tus juegos', $a->getFechaFinPrevista()->format('d/m/Y'), $a->getId());

        return 'mailto:' . $cliente->getEmail()
            . '?subject=' . rawurlencode(sprintf('Tu alquiler #%04d · JuegAlmi', $a->getId()))
            . '&body=' . rawurlencode($cuerpo);
    }

    private function volver(Request $request): string
    {
        $url = (string) $request->request->get('volver', '');
        return str_starts_with($url, '/gestion/alquileres') ? $url : $this->generateUrl('gestion_alquileres');
    }
}
