<?php

namespace App\Controller\Api;

use App\Entity\Alquiler;
use App\Entity\Cliente;
use App\Entity\Pedido;
use App\Entity\Reparacion;
use App\Entity\Usuario;
use App\Service\RespuestaApi;
use App\Service\UsuarioPresenter;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\PasswordHasher\Hasher\UserPasswordHasherInterface;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Security\Http\Attribute\CurrentUser;
use Symfony\Component\Validator\Constraints as Assert;
use Symfony\Component\Validator\Validator\ValidatorInterface;

#[Route('/api', format: 'json')]
class UsuarioController extends AbstractController
{
    public function __construct(
        private EntityManagerInterface $em,
        private UsuarioPresenter $presenter,
    ) {
    }

    /** GET /api/yo — pantallas 03 (Inicio), 10 (Cuenta) y 14 (Menú lateral) */
    #[Route('/yo', name: 'api_yo', methods: ['GET'])]
    public function yo(#[CurrentUser] Usuario $usuario): JsonResponse
    {
        $datos = $this->presenter->presentar($usuario);

        if ($usuario instanceof Cliente) {
            $datos['contadores'] = $this->contadores($usuario);
        }

        return $this->json($datos);
    }

    /** PUT /api/yo — «Datos personales» de la pantalla 10. Solo se envían los campos que cambian. */
    #[Route('/yo', name: 'api_yo_modificar', methods: ['PUT'])]
    public function modificar(
        #[CurrentUser] Usuario $usuario,
        Request $request,
        ValidatorInterface $validator,
        UserPasswordHasherInterface $hasher,
    ): JsonResponse {
        $datos = RespuestaApi::leerJson($request);

        if (array_key_exists('nombre', $datos)) {
            $usuario->setNombre(trim((string) $datos['nombre']));
        }
        if (array_key_exists('apellido1', $datos)) {
            $usuario->setApellido1(trim((string) $datos['apellido1']));
        }
        if (array_key_exists('apellido2', $datos)) {
            $usuario->setApellido2(trim((string) $datos['apellido2']) ?: null);
        }
        if (array_key_exists('telefono', $datos)) {
            $usuario->setTelefono(trim((string) $datos['telefono']) ?: null);
        }
        if (array_key_exists('foto_perfil', $datos)) {
            $usuario->setFotoPerfil(trim((string) $datos['foto_perfil']) ?: null);
        }

        $campos = RespuestaApi::camposConError($validator->validate($usuario));

        // Cambio de contraseña: hace falta la actual
        if (isset($datos['password_nueva'])) {
            if (!$hasher->isPasswordValid($usuario, (string) ($datos['password_actual'] ?? ''))) {
                $campos['password_actual'] = 'La contraseña actual no es correcta';
            }

            $errores = $validator->validate((string) $datos['password_nueva'], [
                new Assert\Length(min: 6, minMessage: 'La contraseña tiene que tener al menos 6 caracteres'),
            ]);
            if (count($errores) > 0) {
                $campos['password_nueva'] = $errores[0]->getMessage();
            }
        }

        if ($campos !== []) {
            // Se descartan los cambios que ya se habían aplicado al objeto
            $this->em->refresh($usuario);

            return RespuestaApi::errorValidacion($campos);
        }

        if (isset($datos['password_nueva'])) {
            $usuario->setPassword($hasher->hashPassword($usuario, (string) $datos['password_nueva']));
        }

        $this->em->flush();

        return $this->yo($usuario);
    }

    /** Números de las tarjetas de la pantalla Cuenta */
    private function contadores(Cliente $cliente): array
    {
        $pedidos = $this->em->createQuery(
            'SELECT COUNT(p.id) FROM ' . Pedido::class . ' p JOIN p.domicilio d WHERE d.cliente = :cliente'
        )->setParameter('cliente', $cliente)->getSingleScalarResult();

        $alquileres = $this->em->createQuery(
            'SELECT COUNT(DISTINCT a.id) FROM ' . Alquiler::class . ' a JOIN a.lineas l
             WHERE a.cliente = :cliente AND l.fechaDevolucion IS NULL'
        )->setParameter('cliente', $cliente)->getSingleScalarResult();

        $reparaciones = $this->em->createQuery(
            'SELECT COUNT(r.id) FROM ' . Reparacion::class . ' r
             WHERE r.cliente = :cliente AND NOT EXISTS (
                 SELECT h.id FROM App\Entity\HistorialEstado h
                 WHERE h.reparacion = r AND h.estado IN (:terminados)
             )'
        )->setParameter('cliente', $cliente)
         ->setParameter('terminados', ['entregada', 'cancelada'])
         ->getSingleScalarResult();

        return [
            'pedidos' => (int) $pedidos,
            'alquileres_activos' => (int) $alquileres,
            'reparaciones_en_curso' => (int) $reparaciones,
        ];
    }
}
