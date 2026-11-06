<?php

namespace App\Controller\Api;

use App\Entity\Departamento;
use App\Entity\FotoTienda;
use App\Entity\Tienda;
use App\Service\ProductoPresenter;
use App\Service\RespuestaApi;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\Routing\Attribute\Route;

#[Route('/api', format: 'json')]
class TiendaController extends AbstractController
{
    public function __construct(private EntityManagerInterface $em)
    {
    }

    /** GET /api/tienda — pantalla 11 (ubicación). El horario y la historia van en las apps. */
    #[Route('/tienda', name: 'api_tienda', methods: ['GET'])]
    public function tienda(): JsonResponse
    {
        $tienda = $this->em->getRepository(Tienda::class)->findOneBy([], ['id' => 'ASC']);
        if (!$tienda) {
            return RespuestaApi::error(404, 'No hay ninguna tienda registrada');
        }

        $d = $tienda->getDireccion();

        return $this->json([
            'id' => $tienda->getId(),
            'nombre' => $tienda->getNombre(),
            'telefono' => $tienda->getTelefono(),
            'email' => $tienda->getEmail(),
            'latitud' => $tienda->getLatitud(),
            'longitud' => $tienda->getLongitud(),
            'direccion' => [
                'calle' => $d->getCalle(),
                'numero' => $d->getNumero(),
                'piso' => $d->getPiso(),
                'codigo_postal' => $d->getCodigoPostal(),
                'ciudad' => $d->getCiudad(),
                'provincia' => $d->getProvincia(),
            ],
            // Listo para pintar como en el mockup: «Gran Vía 12, bajo» / «48001 Bilbao, Bizkaia»
            'direccion_linea1' => trim(sprintf('%s %s, %s', $d->getCalle(), $d->getNumero(), mb_strtolower((string) $d->getPiso())), ', '),
            'direccion_linea2' => sprintf('%s %s, %s', $d->getCodigoPostal(), $d->getCiudad(), $d->getProvincia()),
        ]);
    }

    /** GET /api/tienda/fotos — pantalla 13 (galería) */
    #[Route('/tienda/fotos', name: 'api_tienda_fotos', methods: ['GET'])]
    public function fotos(ProductoPresenter $presenter): JsonResponse
    {
        $fotos = $this->em->getRepository(FotoTienda::class)->findBy([], ['id' => 'ASC']);

        return $this->json(array_map(fn (FotoTienda $f) => [
            'id' => $f->getId(),
            'titulo' => $f->getTitulo(),
            'url' => $presenter->url($f->getRuta()),
        ], $fotos));
    }

    /** GET /api/departamentos — pestañas de Servicios */
    #[Route('/departamentos', name: 'api_departamentos', methods: ['GET'])]
    public function departamentos(): JsonResponse
    {
        $departamentos = $this->em->getRepository(Departamento::class)->findBy(['activo' => true], ['id' => 'ASC']);

        return $this->json(array_map(fn (Departamento $d) => [
            'id' => $d->getId(),
            'nombre' => $d->getNombre(),
            'descripcion' => $d->getDescripcion(),
            'telefono' => $d->getTelefono(),
        ], $departamentos));
    }
}
