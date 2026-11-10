<?php

namespace App\Controller\Gestion;

use App\Entity\Trabajador;
use App\Entity\TrabajadorDepartamento;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\PasswordHasher\Hasher\UserPasswordHasherInterface;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Validator\Validator\ValidatorInterface;

/** Ajustes: cada trabajador cambia sus datos y su contraseña */
#[Route('/gestion/ajustes')]
class AjustesController extends AbstractController
{
    public function __construct(private EntityManagerInterface $em)
    {
    }

    #[Route('', name: 'gestion_ajustes', methods: ['GET', 'POST'])]
    public function index(Request $request, ValidatorInterface $validator): Response
    {
        /** @var Trabajador $yo */
        $yo = $this->getUser();
        $errores = [];

        if ($request->isMethod('POST')) {
            if (!$this->isCsrfTokenValid('ajustes', (string) $request->request->get('_token'))) {
                $errores['_'] = 'El formulario ha caducado. Vuelve a intentarlo.';
            } else {
                foreach (['nombre' => 'Escribe tu nombre.', 'apellido1' => 'Escribe tu primer apellido.'] as $campo => $mensaje) {
                    if (trim((string) $request->request->get($campo, '')) === '') {
                        $errores[$campo] = $mensaje;
                    }
                }
                if ($errores === []) {
                    $yo->setNombre(trim((string) $request->request->get('nombre')))
                        ->setApellido1(trim((string) $request->request->get('apellido1')))
                        ->setApellido2(trim((string) $request->request->get('apellido2', '')) ?: null)
                        ->setTelefono(trim((string) $request->request->get('telefono', '')) ?: null);
                    foreach ($validator->validate($yo) as $error) {
                        $errores[$error->getPropertyPath()] ??= $error->getMessage();
                    }
                    if ($errores === []) {
                        $this->em->flush();
                        $this->addFlash('success', 'Tus datos se han guardado.');
                        return $this->redirectToRoute('gestion_ajustes');
                    }
                    $this->em->refresh($yo);
                }
            }
        }

        return $this->pagina($yo, $errores, $request->request->all());
    }

    #[Route('/contrasena', name: 'gestion_ajustes_contrasena', methods: ['POST'])]
    public function contrasena(Request $request, UserPasswordHasherInterface $hasher): Response
    {
        /** @var Trabajador $yo */
        $yo = $this->getUser();
        $actual = (string) $request->request->get('actual', '');
        $nueva = (string) $request->request->get('nueva', '');
        $repetida = (string) $request->request->get('repetida', '');
        $errores = [];

        if (!$this->isCsrfTokenValid('ajustes', (string) $request->request->get('_token'))) {
            $errores['_'] = 'El formulario ha caducado. Vuelve a intentarlo.';
        } elseif (!$hasher->isPasswordValid($yo, $actual)) {
            $errores['actual'] = 'La contraseña actual no es correcta.';
        } elseif (!\App\Service\ReglaContrasena::valida($nueva)) {
            $errores['nueva'] = \App\Service\ReglaContrasena::MENSAJE;
        } elseif ($nueva !== $repetida) {
            $errores['repetida'] = 'Las dos contraseñas nuevas no coinciden.';
        } elseif ($nueva === $actual) {
            $errores['nueva'] = 'La nueva tiene que ser distinta de la actual.';
        }

        if ($errores === []) {
            $yo->setPassword($hasher->hashPassword($yo, $nueva));
            $this->em->flush();
            $this->addFlash('success', 'Contraseña cambiada. La próxima vez entra con la nueva.');
            return $this->redirectToRoute('gestion_ajustes');
        }

        return $this->pagina($yo, $errores, []);
    }

    private function pagina(Trabajador $yo, array $errores, array $enviado): Response
    {
        $departamento = $this->em->getRepository(TrabajadorDepartamento::class)
            ->findOneBy(['trabajador' => $yo, 'fechaFin' => null])?->getDepartamento()?->getNombre();

        return $this->render('gestion/ajustes/index.html.twig', [
            'yo' => $yo,
            'departamento' => $departamento,
            'errores' => $errores,
            'v' => $enviado + [
                'nombre' => $yo->getNombre(), 'apellido1' => $yo->getApellido1(),
                'apellido2' => $yo->getApellido2(), 'telefono' => $yo->getTelefono(),
            ],
        ]);
    }
}
