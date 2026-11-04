<?php

namespace App\Controller\Api;

use App\Entity\Cliente;
use App\Entity\Direccion;
use App\Entity\Domicilio;
use App\Entity\Usuario;
use App\Service\DomicilioPresenter;
use App\Service\RespuestaApi;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Security\Http\Attribute\CurrentUser;
use Symfony\Component\Validator\Validator\ValidatorInterface;

#[Route('/api/domicilios', format: 'json')]
class DomicilioController extends AbstractController
{
    public function __construct(
        private EntityManagerInterface $em,
        private DomicilioPresenter $presenter,
    ) {
    }

    /** GET /api/domicilios — domicilios activos del cliente */
    #[Route('', name: 'api_domicilios', methods: ['GET'])]
    public function listar(#[CurrentUser] Usuario $usuario): JsonResponse
    {
        if (!$usuario instanceof Cliente) {
            return RespuestaApi::error(403, 'Solo los clientes tienen domicilios');
        }

        $domicilios = $this->em->getRepository(Domicilio::class)->findBy(
            ['cliente' => $usuario, 'fechaBaja' => null],
            ['fechaAlta' => 'DESC', 'id' => 'DESC'],
        );

        return $this->json(array_map([$this->presenter, 'presentar'], $domicilios));
    }

    /** POST /api/domicilios — {calle, numero, piso, codigo_postal, ciudad, provincia} */
    #[Route('', name: 'api_domicilios_crear', methods: ['POST'])]
    public function crear(#[CurrentUser] Usuario $usuario, Request $request, ValidatorInterface $validator): JsonResponse
    {
        if (!$usuario instanceof Cliente) {
            return RespuestaApi::error(403, 'Solo los clientes pueden añadir domicilios');
        }

        $datos = RespuestaApi::leerJson($request);
        $texto = fn (string $campo): string => trim((string) ($datos[$campo] ?? ''));

        $direccion = (new Direccion())
            ->setCalle($texto('calle'))
            ->setNumero($texto('numero'))
            ->setPiso($texto('piso') ?: null)
            ->setCodigoPostal($texto('codigo_postal'))
            ->setCiudad($texto('ciudad'))
            ->setProvincia($texto('provincia'));

        $campos = RespuestaApi::camposConError($validator->validate($direccion));
        if ($campos !== []) {
            return RespuestaApi::errorValidacion($campos);
        }

        $domicilio = (new Domicilio())->setCliente($usuario)->setDireccion($direccion);
        $this->em->persist($direccion);
        $this->em->persist($domicilio);
        $this->em->flush();

        return $this->json($this->presenter->presentar($domicilio), Response::HTTP_CREATED);
    }

    /** DELETE /api/domicilios/{id} — baja del domicilio (se guarda la fecha, no se borra) */
    #[Route('/{id}', name: 'api_domicilios_baja', requirements: ['id' => '\d+'], methods: ['DELETE'])]
    public function baja(#[CurrentUser] Usuario $usuario, int $id): JsonResponse
    {
        $domicilio = $this->em->find(Domicilio::class, $id);

        // Si no existe, no es suyo o ya estaba de baja: 404, como si no existiera
        if (!$domicilio || $domicilio->getCliente() !== $usuario || !$domicilio->isActivo()) {
            return RespuestaApi::error(404, 'El domicilio no existe');
        }

        $domicilio->setFechaBaja(new \DateTimeImmutable('today'));
        $this->em->flush();

        return $this->json(['mensaje' => 'Domicilio dado de baja', 'domicilio' => $this->presenter->presentar($domicilio)]);
    }

    /** PUT /api/domicilios/{id} — «editar»: da de baja el antiguo y crea el nuevo en una sola operación */
    #[Route('/{id}', name: 'api_domicilios_modificar', requirements: ['id' => '\d+'], methods: ['PUT'])]
    public function modificar(#[CurrentUser] Usuario $usuario, int $id, Request $request, ValidatorInterface $validator): JsonResponse
    {
        $antiguo = $this->em->find(Domicilio::class, $id);
        if (!$antiguo || $antiguo->getCliente() !== $usuario || !$antiguo->isActivo()) {
            return RespuestaApi::error(404, 'El domicilio no existe');
        }

        $datos = RespuestaApi::leerJson($request);
        $actual = $antiguo->getDireccion();

        // Los campos que no se envían se copian de la dirección antigua
        $valor = fn (string $campo, ?string $anterior): ?string => array_key_exists($campo, $datos)
            ? trim((string) $datos[$campo])
            : $anterior;

        $direccion = (new Direccion())
            ->setCalle((string) $valor('calle', $actual->getCalle()))
            ->setNumero((string) $valor('numero', $actual->getNumero()))
            ->setPiso($valor('piso', $actual->getPiso()) ?: null)
            ->setCodigoPostal((string) $valor('codigo_postal', $actual->getCodigoPostal()))
            ->setCiudad((string) $valor('ciudad', $actual->getCiudad()))
            ->setProvincia((string) $valor('provincia', $actual->getProvincia()));

        $campos = RespuestaApi::camposConError($validator->validate($direccion));
        if ($campos !== []) {
            return RespuestaApi::errorValidacion($campos);
        }

        $nuevo = (new Domicilio())->setCliente($usuario)->setDireccion($direccion);

        // Baja y alta juntas: o se hacen las dos o ninguna
        $this->em->wrapInTransaction(function () use ($antiguo, $direccion, $nuevo) {
            $antiguo->setFechaBaja(new \DateTimeImmutable('today'));
            $this->em->persist($direccion);
            $this->em->persist($nuevo);
        });

        return $this->json($this->presenter->presentar($nuevo) + ['sustituye_a' => $antiguo->getId()]);
    }
}
