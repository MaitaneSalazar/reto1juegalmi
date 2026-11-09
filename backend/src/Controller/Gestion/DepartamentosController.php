<?php

namespace App\Controller\Gestion;

use App\Entity\Departamento;
use App\Entity\Tienda;
use App\Entity\Trabajador;
use App\Entity\TrabajadorDepartamento;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Security\Http\Attribute\IsGranted;

/** Pantalla 12 del mockup: departamentos con sus trabajadores e historial (solo admin) */
#[Route('/gestion/departamentos')]
#[IsGranted('ROLE_ADMIN')]
class DepartamentosController extends AbstractController
{
    public function __construct(private EntityManagerInterface $em)
    {
    }

    #[Route('', name: 'gestion_departamentos', methods: ['GET'])]
    public function index(Request $request): Response
    {
        $departamentos = $this->em->getRepository(Departamento::class)->findBy(['activo' => true], ['nombre' => 'ASC']);
        $repo = $this->em->getRepository(TrabajadorDepartamento::class);

        $cuentas = [];
        foreach ($repo->findBy(['fechaFin' => null]) as $a) {
            $id = $a->getDepartamento()->getId();
            $cuentas[$id] = ($cuentas[$id] ?? 0) + 1;
        }

        $elegido = $request->query->getInt('id') ? $this->em->find(Departamento::class, $request->query->getInt('id')) : ($departamentos[0] ?? null);
        $actuales = $historial = [];
        if ($elegido) {
            $actuales = $repo->findBy(['departamento' => $elegido, 'fechaFin' => null], ['fechaInicio' => 'ASC']);
            foreach ($repo->findBy(['departamento' => $elegido], ['fechaFin' => 'DESC']) as $a) {
                if ($a->getFechaFin() === null) {
                    continue;
                }
                // ¿A qué departamento pasó después? (la etapa suya que empezó al acabar esta)
                $siguiente = $this->em->createQueryBuilder()->select('s')->from(TrabajadorDepartamento::class, 's')
                    ->where('s.trabajador = :t')->andWhere('s.fechaInicio >= :fin')->andWhere('s.id != :id')
                    ->setParameter('t', $a->getTrabajador())->setParameter('fin', $a->getFechaFin())->setParameter('id', $a->getId())
                    ->orderBy('s.fechaInicio', 'ASC')->setMaxResults(1)->getQuery()->getOneOrNullResult();
                $historial[] = ['a' => $a, 'paso_a' => $siguiente?->getDepartamento()?->getNombre()];
            }
        }

        $ocupados = array_map(fn ($a) => $a->getTrabajador()->getId(), $actuales);

        return $this->render('gestion/departamentos/index.html.twig', [
            'departamentos' => $departamentos,
            'cuentas' => $cuentas,
            'elegido' => $elegido,
            'actuales' => $actuales,
            'historial' => $historial,
            'disponibles' => array_filter($this->em->getRepository(Trabajador::class)->findBy(['activo' => true], ['nombre' => 'ASC']),
                fn (Trabajador $t) => !in_array($t->getId(), $ocupados, true)),
        ]);
    }

    #[Route('/nuevo', name: 'gestion_departamento_nuevo', methods: ['POST'])]
    public function nuevo(Request $request): Response
    {
        if (!$this->comprobar($request)) {
            return $this->redirectToRoute('gestion_departamentos');
        }
        $nombre = trim((string) $request->request->get('nombre', ''));
        $tienda = $this->em->getRepository(Tienda::class)->findOneBy([]);
        if ($nombre === '' || $tienda === null) {
            $this->addFlash('danger', 'Escribe el nombre del departamento.');
            return $this->redirectToRoute('gestion_departamentos');
        }
        $departamento = (new Departamento())->setNombre($nombre)->setTienda($tienda)
            ->setDescripcion(trim((string) $request->request->get('descripcion', '')) ?: null)
            ->setTelefono(trim((string) $request->request->get('telefono', '')) ?: null);
        $this->em->persist($departamento);
        $this->em->flush();
        $this->addFlash('success', sprintf('Departamento «%s» creado.', $nombre));

        return $this->redirectToRoute('gestion_departamentos', ['id' => $departamento->getId()]);
    }

    #[Route('/{id}', name: 'gestion_departamento_guardar', requirements: ['id' => '\d+'], methods: ['POST'])]
    public function guardar(Departamento $departamento, Request $request): Response
    {
        if ($this->comprobar($request)) {
            $nombre = trim((string) $request->request->get('nombre', ''));
            if ($nombre === '') {
                $this->addFlash('danger', 'El nombre no puede quedar vacío.');
            } else {
                $departamento->setNombre($nombre)
                    ->setDescripcion(trim((string) $request->request->get('descripcion', '')) ?: null)
                    ->setTelefono(trim((string) $request->request->get('telefono', '')) ?: null);
                $this->em->flush();
                $this->addFlash('success', 'Datos del departamento guardados.');
            }
        }

        return $this->aDepartamento($departamento);
    }

    #[Route('/{id}/activo', name: 'gestion_departamento_activo', requirements: ['id' => '\d+'], methods: ['POST'])]
    public function activo(Departamento $departamento, Request $request): Response
    {
        if ($this->comprobar($request)) {
            $departamento->setActivo(!$departamento->isActivo());
            $this->em->flush();
            $this->addFlash('success', sprintf('«%s» %s.', $departamento->getNombre(), $departamento->isActivo() ? 'vuelve a estar activo' : 'se ha desactivado: no se borra y su historial se mantiene'));
        }

        return $this->aDepartamento($departamento);
    }

    #[Route('/{id}/asignar', name: 'gestion_departamento_asignar', requirements: ['id' => '\d+'], methods: ['POST'])]
    public function asignar(Departamento $departamento, Request $request): Response
    {
        if ($this->comprobar($request)) {
            $trabajador = $this->em->find(Trabajador::class, $request->request->getInt('trabajador'));
            if ($trabajador === null) {
                $this->addFlash('danger', 'Elige un trabajador.');
            } else {
                $hoy = new \DateTimeImmutable('today');
                // Si estaba en otro departamento, esa etapa se cierra hoy
                $this->em->getRepository(TrabajadorDepartamento::class)->findOneBy(['trabajador' => $trabajador, 'fechaFin' => null])?->setFechaFin($hoy);
                $this->em->persist((new TrabajadorDepartamento())->setTrabajador($trabajador)->setDepartamento($departamento)->setFechaInicio($hoy));
                $this->em->flush();
                $this->addFlash('success', sprintf('%s pasa a «%s».', $trabajador->getNombre(), $departamento->getNombre()));
            }
        }

        return $this->aDepartamento($departamento);
    }

    #[Route('/etapa/{id}/finalizar', name: 'gestion_departamento_finalizar', requirements: ['id' => '\d+'], methods: ['POST'])]
    public function finalizar(TrabajadorDepartamento $etapa, Request $request): Response
    {
        if ($this->comprobar($request) && $etapa->getFechaFin() === null) {
            $etapa->setFechaFin(new \DateTimeImmutable('today'));
            $this->em->flush();
            $this->addFlash('success', sprintf('%s ya no está en «%s». Queda en el historial.', $etapa->getTrabajador()->getNombre(), $etapa->getDepartamento()->getNombre()));
        }

        return $this->aDepartamento($etapa->getDepartamento());
    }

    private function comprobar(Request $request): bool
    {
        if ($this->isCsrfTokenValid('departamento', (string) $request->request->get('_token'))) {
            return true;
        }
        $this->addFlash('danger', 'El formulario ha caducado. Vuelve a intentarlo.');
        return false;
    }

    private function aDepartamento(Departamento $departamento): Response
    {
        return $this->redirectToRoute('gestion_departamentos', ['id' => $departamento->getId()]);
    }
}
