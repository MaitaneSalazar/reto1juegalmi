<?php

namespace App\Service;

use App\Entity\FotoTienda;
use App\Entity\Producto;
use App\Message\CrearMiniatura;
use Doctrine\ORM\EntityManagerInterface;
use Symfony\Component\DependencyInjection\Attribute\Autowire;
use Symfony\Component\Messenger\MessageBusInterface;

/**
 * Pone las imágenes de fixtures/imagenes/ a los productos y fotos de la tienda que YA existen.
 * Los busca por su nombre y solo cambia la ruta de la imagen: no crea ni borra filas ni archivos.
 * Lo usan el comando app:cargar-imagenes y los datos de ejemplo (AppFixtures).
 */
class CargadorImagenes
{
    /** Imagen de cada producto (por su nombre exacto) en fixtures/imagenes/productos/ */
    public const PRODUCTOS = [
        'Elden Ring' => 'EldenRing.jpeg',
        'Forza Horizon 5' => 'ForzaHorizon5.jpeg',
        'Halo Infinite' => 'HaloInfinite.jpeg',
        'Mario Kart 8 Deluxe' => 'MarioKart8Deluxe.jpeg',
        "Marvel's Spider-Man 2" => 'MarvelsSpider-Man2.jpeg',
        'Minecraft' => 'Minecraft.jpeg',
        'Super Mario Bros. Wonder' => 'SuperMarioBros.Wonder.jpeg',
        'Zelda: Tears of the Kingdom' => 'ZeldaTearsoftheKingdom.jpeg',
        'Nintendo Switch OLED' => 'NintendoSwitchOLED.jpeg',
        'PlayStation 5 Slim' => 'PlayStation5Slim.jpeg',
        'Steam Deck OLED' => 'SteamDeckOLED.jpeg',
        'Xbox Series X' => 'XboxSeriesX.jpeg',
        'iPhone 16' => 'iPhone16.jpeg',
        'Samsung Galaxy S24' => 'SamsungGalaxyS24.jpeg',
        'Xiaomi Redmi Note 13' => 'XiaomiRedmiNote13.jpeg',
        'iPad Air 11"' => 'iPadAir11.jpeg',
        'Samsung Galaxy Tab S9 FE' => 'SamsungGalaxyTabS9FE.jpeg',
        'Xiaomi Pad 6' => 'XiaomiPad6.jpeg',
    ];

    /** Imagen de cada foto de la galería (por su título) en fixtures/imagenes/tienda/ */
    public const TIENDA = [
        'Fachada' => 'Fachada.png',
        'Mostrador' => 'Mostrador.png',
        'Zona de videojuegos' => 'Videojuegos.png',
        'Taller' => 'Taller.png',
    ];

    public function __construct(
        private EntityManagerInterface $em,
        private MessageBusInterface $bus,
        #[Autowire('%kernel.project_dir%')] private string $directorioProyecto,
    ) {
    }

    /** @return list<array{string, string, string}> una fila por imagen: [tipo, nombre, resultado] */
    public function cargar(bool $simular = false): array
    {
        $informe = [];

        foreach (self::PRODUCTOS as $nombre => $archivo) {
            $producto = $this->em->getRepository(Producto::class)->findOneBy(['nombre' => $nombre]);
            $informe[] = ['Producto', $nombre, $this->asignar($producto, 'productos', $archivo, $simular,
                fn (string $ruta) => $producto->setImagen($ruta))];
        }

        foreach (self::TIENDA as $titulo => $archivo) {
            $foto = $this->em->getRepository(FotoTienda::class)->findOneBy(['titulo' => $titulo]);
            $informe[] = ['Tienda', $titulo, $this->asignar($foto, 'tienda', $archivo, $simular,
                fn (string $ruta) => $foto->setRuta($ruta))];
        }

        if (!$simular) {
            $this->em->flush();
        }

        return $informe;
    }

    private function asignar(?object $entidad, string $carpeta, string $archivo, bool $simular, callable $ponerRuta): string
    {
        if ($entidad === null) {
            return 'No existe en la base de datos: se salta';
        }

        $origen = $this->directorioProyecto . '/fixtures/imagenes/' . $carpeta . '/' . $archivo;
        if (!is_file($origen)) {
            return 'Falta el archivo ' . $archivo . ': se salta';
        }

        // En uploads con nombre en minúsculas y sin caracteres raros (igual que las demás)
        $nombre = strtolower(trim(preg_replace('/[^A-Za-z0-9]+/', '-', pathinfo($archivo, PATHINFO_FILENAME)), '-'));
        $ruta = '/uploads/' . $carpeta . '/' . $nombre . '.' . strtolower(pathinfo($archivo, PATHINFO_EXTENSION));
        if ($simular) {
            return 'Se pondría ' . $ruta;
        }

        copy($origen, $this->directorioProyecto . '/public' . $ruta);
        $ponerRuta($ruta);
        $this->bus->dispatch(new CrearMiniatura($ruta));

        return 'OK ' . $ruta;
    }
}
