<?php

namespace App\Controller\Api;

use App\Entity\Cliente;
use App\Service\RespuestaApi;
use App\Service\UsuarioPresenter;
use Doctrine\ORM\EntityManagerInterface;
use Lexik\Bundle\JWTAuthenticationBundle\Services\JWTTokenManagerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\PasswordHasher\Hasher\UserPasswordHasherInterface;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Validator\Constraints as Assert;
use Symfony\Component\Validator\Validator\ValidatorInterface;

#[Route('/api', format: 'json')]
class AuthController extends AbstractController
{
    /**
     * POST /api/registro — pantalla 02 del mockup.
     * Crea un cliente y devuelve directamente el token, para entrar sin pasar por el login.
     */
    #[Route('/registro', name: 'api_registro', methods: ['POST'])]
    public function registro(
        Request $request,
        ValidatorInterface $validator,
        UserPasswordHasherInterface $hasher,
        EntityManagerInterface $em,
        JWTTokenManagerInterface $jwt,
        UsuarioPresenter $presenter,
    ): JsonResponse {
        $datos = RespuestaApi::leerJson($request);
        $texto = fn (string $campo): string => trim((string) ($datos[$campo] ?? ''));

        $cliente = (new Cliente())
            ->setNombre($texto('nombre'))
            ->setApellido1($texto('apellido1'))
            ->setApellido2($texto('apellido2') ?: null)
            ->setDni($texto('dni'))
            ->setEmail($texto('email'))
            ->setTelefono($texto('telefono') ?: null);

        // Validaciones de la entidad (obligatorios, formato de DNI y email, que no se repitan...)
        $campos = RespuestaApi::camposConError($validator->validate($cliente));

        // La contraseña se valida aparte, porque en la entidad se guarda ya cifrada
        $password = (string) ($datos['password'] ?? '');
        $erroresPassword = $validator->validate($password, [
            new Assert\NotBlank(message: 'La contraseña es obligatoria'),
            new Assert\Length(min: 6, minMessage: 'La contraseña tiene que tener al menos 6 caracteres'),
        ]);
        if (count($erroresPassword) > 0) {
            $campos['password'] = $erroresPassword[0]->getMessage();
        }

        if ($campos !== []) {
            return RespuestaApi::errorValidacion($campos);
        }

        $cliente->setPassword($hasher->hashPassword($cliente, $password));
        $em->persist($cliente);
        $em->flush();

        return $this->json([
            'token' => $jwt->create($cliente),
            'usuario' => $presenter->presentar($cliente),
        ], Response::HTTP_CREATED);
    }
}
