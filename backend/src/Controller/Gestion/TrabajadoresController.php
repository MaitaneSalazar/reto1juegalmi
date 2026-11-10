<?php

namespace App\Controller\Gestion;

use App\Entity\Departamento;
use App\Entity\Trabajador;
use App\Entity\TrabajadorDepartamento;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\PasswordHasher\Hasher\UserPasswordHasherInterface;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Security\Http\Attribute\IsGranted;
use Symfony\Component\Validator\Validator\ValidatorInterface;

/** Pantalla 11 del mockup: trabajadores (solo admin) */
#[Route('/gestion/trabajadores')]
#[IsGranted('ROLE_ADMIN')]
class TrabajadoresController extends AbstractController
{
    public function __construct(private EntityManagerInterface $em)
    {
    }

    #[Route('', name: 'gestion_trabajadores', methods: ['GET'])]
    public function listado(): Response
    {
        return $this->render('gestion/trabajadores/listado.html.twig', [
            'trabajadores' => $this->em->getRepository(Trabajador::class)->findBy([], ['activo' => 'DESC', 'nombre' => 'ASC']),
            'departamentos' => $this->departamentosActuales(),
        ]);
    }

    #[Route('/{id}/activo', name: 'gestion_trabajador_activo', requirements: ['id' => '\d+'], methods: ['POST'])]
    public function activo(Trabajador $trabajador, Request $request): Response
    {
        if (!$this->isCsrfTokenValid('trabajador', (string) $request->request->get('_token'))) {
            $this->addFlash('danger', 'El formulario ha caducado. Vuelve a intentarlo.');
        } elseif ($this->esYo($trabajador)) {
            $this->addFlash('warning', 'No puedes desactivarte a ti mismo.');
        } else {
            $trabajador->setActivo($request->request->getBoolean('activo'));
            $this->em->flush();
            $this->addFlash('success', sprintf('%s %s.', $trabajador->getNombre(), $trabajador->isActivo() ? 'vuelve a estar activo' : 'se ha desactivado: ya no puede entrar en la web'));
        }

        return $this->redirectToRoute('gestion_trabajadores');
    }

    #[Route('/nuevo', name: 'gestion_trabajador_nuevo', methods: ['GET', 'POST'])]
    public function nuevo(Request $request, UserPasswordHasherInterface $hasher, ValidatorInterface $validator): Response
    {
        return $this->formulario($request, null, $hasher, $validator);
    }

    #[Route('/{id}/editar', name: 'gestion_trabajador_editar', requirements: ['id' => '\d+'], methods: ['GET', 'POST'])]
    public function editar(Trabajador $trabajador, Request $request, UserPasswordHasherInterface $hasher, ValidatorInterface $validator): Response
    {
        return $this->formulario($request, $trabajador, $hasher, $validator);
    }

    private function formulario(Request $request, ?Trabajador $trabajador, UserPasswordHasherInterface $hasher, ValidatorInterface $validator): Response
    {
        $esNuevo = $trabajador === null;
        $actual = $trabajador ? $this->asignacionActual($trabajador)?->getDepartamento() : null;
        $v = $trabajador ? [
            'nombre' => $trabajador->getNombre(), 'apellido1' => $trabajador->getApellido1(), 'apellido2' => $trabajador->getApellido2(),
            'dni' => $trabajador->getDni(), 'email' => $trabajador->getEmail(), 'telefono' => $trabajador->getTelefono(),
            'cargo' => $trabajador->getCargo(), 'fecha_contratacion' => $trabajador->getFechaContratacion()?->format('Y-m-d'),
            'es_admin' => $trabajador->isEsAdmin(), 'activo' => $trabajador->isActivo(), 'departamento' => $actual?->getId(),
        ] : ['activo' => true, 'es_admin' => false, 'fecha_contratacion' => (new \DateTimeImmutable())->format('Y-m-d')];
        $errores = [];

        if ($request->isMethod('POST')) {
            $v = $request->request->all();
            $v['es_admin'] = $request->request->has('es_admin');
            $v['activo'] = $request->request->has('activo');

            if (!$this->isCsrfTokenValid('trabajador', (string) $request->request->get('_token'))) {
                $errores['_'] = 'El formulario ha caducado. Vuelve a intentarlo.';
            }
            foreach (['nombre' => 'Escribe el nombre.', 'apellido1' => 'Escribe el primer apellido.', 'dni' => 'Escribe el DNI.', 'email' => 'Escribe el email.', 'cargo' => 'Escribe el cargo.'] as $campo => $mensaje) {
                if (trim((string) ($v[$campo] ?? '')) === '') {
                    $errores[$campo] = $mensaje;
                }
            }
            $fecha = \DateTimeImmutable::createFromFormat('!Y-m-d', (string) ($v['fecha_contratacion'] ?? ''));
            if ($fecha === false) {
                $errores['fecha_contratacion'] = 'Elige la fecha de contratación.';
            }
            $contrasena = (string) ($v['contrasena'] ?? '');
            if ($esNuevo && !\App\Service\ReglaContrasena::valida($contrasena)) {
                $errores['contrasena'] = \App\Service\ReglaContrasena::MENSAJE;
            } elseif (!$esNuevo && $contrasena !== '' && !\App\Service\ReglaContrasena::valida($contrasena)) {
                $errores['contrasena'] = \App\Service\ReglaContrasena::MENSAJE;
            }
            if (!$esNuevo && $this->esYo($trabajador) && (!$v['activo'] || !$v['es_admin'])) {
                $errores['es_admin'] = 'No puedes desactivarte ni quitarte el permiso de admin a ti mismo.';
            }

            if ($errores === []) {
                $objeto = $trabajador ?? new Trabajador();
                $objeto->setNombre(trim($v['nombre']))->setApellido1(trim($v['apellido1']))
                    ->setApellido2(trim((string) ($v['apellido2'] ?? '')) ?: null)
                    ->setDni(trim($v['dni']))->setEmail(trim($v['email']))
                    ->setTelefono(trim((string) ($v['telefono'] ?? '')) ?: null)
                    ->setActivo($v['activo']);
                $objeto->setCargo(trim($v['cargo']))->setEsAdmin($v['es_admin'])->setFechaContratacion($fecha);
                if ($contrasena !== '') {
                    $objeto->setPassword($hasher->hashPassword($objeto, $contrasena));
                }

                foreach ($validator->validate($objeto) as $error) {
                    $errores[strtolower(preg_replace('/[A-Z]/', '_$0', $error->getPropertyPath()))] ??= $error->getMessage();
                }

                if ($errores === []) {
                    if ($esNuevo) {
                        $this->em->persist($objeto);
                    }
                    $departamento = $this->em->find(Departamento::class, (int) ($v['departamento'] ?? 0));
                    if ($departamento !== null && $departamento !== $actual) {
                        $this->cambiarDepartamento($objeto, $departamento);
                    }
                    $this->em->flush();
                    $this->addFlash('success', sprintf('%s %s se ha guardado.', $objeto->getNombre(), $objeto->getApellido1()));
                    return $this->redirectToRoute('gestion_trabajadores');
                }

                if (!$esNuevo) {
                    $this->em->refresh($trabajador);
                }
            }
        }

        return $this->render('gestion/trabajadores/formulario.html.twig', [
            'trabajador' => $trabajador,
            'es_nuevo' => $esNuevo,
            'v' => $v,
            'errores' => $errores,
            'departamentos' => $this->em->getRepository(Departamento::class)->findBy(['activo' => true], ['nombre' => 'ASC']),
        ]);
    }

    /** Cierra la etapa en el departamento anterior y abre otra en el nuevo */
    private function cambiarDepartamento(Trabajador $trabajador, Departamento $departamento): void
    {
        $hoy = new \DateTimeImmutable('today');
        $this->asignacionActual($trabajador)?->setFechaFin($hoy);
        $this->em->persist((new TrabajadorDepartamento())->setTrabajador($trabajador)->setDepartamento($departamento)->setFechaInicio($hoy));
    }

    private function asignacionActual(Trabajador $trabajador): ?TrabajadorDepartamento
    {
        return $trabajador->getId() === null ? null
            : $this->em->getRepository(TrabajadorDepartamento::class)->findOneBy(['trabajador' => $trabajador, 'fechaFin' => null]);
    }

    /** id del trabajador → nombre de su departamento actual */
    private function departamentosActuales(): array
    {
        $mapa = [];
        foreach ($this->em->getRepository(TrabajadorDepartamento::class)->findBy(['fechaFin' => null]) as $a) {
            $mapa[$a->getTrabajador()->getId()] = $a->getDepartamento()->getNombre();
        }
        return $mapa;
    }

    private function esYo(Trabajador $trabajador): bool
    {
        $yo = $this->getUser();
        return $yo instanceof Trabajador && $yo->getId() === $trabajador->getId();
    }
}
