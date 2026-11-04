<?php

namespace App\DataFixtures;

use App\Entity\Alquiler;
use App\Entity\AlquilerVideojuego;
use App\Entity\Cliente;
use App\Entity\Consola;
use App\Entity\Departamento;
use App\Entity\Direccion;
use App\Entity\Domicilio;
use App\Entity\Empresa;
use App\Entity\FotoTienda;
use App\Entity\Localizacion;
use App\Entity\Movil;
use App\Entity\Pedido;
use App\Entity\PedidoProducto;
use App\Entity\Reparacion;
use App\Entity\Tablet;
use App\Entity\Tienda;
use App\Entity\Trabajador;
use App\Entity\TrabajadorDepartamento;
use App\Entity\TrabajadorReparacion;
use App\Entity\Videojuego;
use Doctrine\Bundle\FixturesBundle\Fixture;
use Doctrine\Persistence\ObjectManager;
use Symfony\Component\PasswordHasher\Hasher\UserPasswordHasherInterface;

/**
 * Datos de ejemplo de JuegAlmi, sacados de los mockups.
 * Se cargan con: php bin/console doctrine:fixtures:load
 */
class AppFixtures extends Fixture
{
    private ObjectManager $om;

    public function __construct(private UserPasswordHasherInterface $hasher)
    {
    }

    public function load(ObjectManager $manager): void
    {
        $this->om = $manager;

        // ---------- Tienda, fotos y departamentos ----------
        $tienda = (new Tienda())
            ->setNombre('JuegAlmi')
            ->setTelefono('944000102')
            ->setEmail('info@juegalmi.es')
            ->setLatitud(43.263010)
            ->setLongitud(-2.935040)
            ->setDireccion($this->direccion('Gran Vía', '12', 'Bajo', '48001'));
        $this->om->persist($tienda);

        foreach (['Fachada', 'Mostrador', 'Zona de videojuegos', 'Taller'] as $i => $titulo) {
            $this->om->persist((new FotoTienda())
                ->setTienda($tienda)
                ->setTitulo($titulo)
                ->setRuta('/uploads/tienda/foto-' . ($i + 1) . '.jpg'));
        }

        $videojuegosDep = $this->departamento($tienda, 'Videojuegos', 'Venta y alquiler de videojuegos para todas las plataformas.', '944000103');
        $consolasDep = $this->departamento($tienda, 'Consolas', 'Venta y reparación de consolas y mandos.', '944000104');
        $telefoniaDep = $this->departamento($tienda, 'Telefonía', 'Venta y reparación de móviles y tablets.', '944000105');

        // ---------- Empresas ----------
        $empresas = [];
        foreach (['Nintendo', 'Sony', 'Microsoft', 'Valve', 'Bandai Namco', 'Mojang', 'Samsung', 'Apple', 'Xiaomi'] as $nombre) {
            $empresas[$nombre] = (new Empresa())->setNombre($nombre);
            $this->om->persist($empresas[$nombre]);
        }

        // ---------- Videojuegos ----------
        $v = [];
        $v['zelda'] = $this->videojuego($empresas['Nintendo'], 'Zelda: Tears of the Kingdom', 'Explora los cielos y las profundidades de Hyrule.', 59.99, 'Switch', 'Aventura', 12, 1.50, 3, 6);
        $v['mario'] = $this->videojuego($empresas['Nintendo'], 'Super Mario Bros. Wonder', 'Mario como nunca lo habías visto, con flores maravilla que lo cambian todo.', 54.99, 'Switch', 'Plataformas', 3, 1.50, 2, 8);
        $v['kart'] = $this->videojuego($empresas['Nintendo'], 'Mario Kart 8 Deluxe', 'Carreras para toda la familia con 48 circuitos.', 49.99, 'Switch', 'Carreras', 3, 1.50, 2, 5);
        $v['elden'] = $this->videojuego($empresas['Bandai Namco'], 'Elden Ring', 'Un mundo abierto lleno de peligros en las Tierras Intermedias.', 49.99, 'PS5', 'Rol', 16, 1.50, 2, 4);
        $v['spiderman'] = $this->videojuego($empresas['Sony'], 'Marvel\'s Spider-Man 2', 'Peter Parker y Miles Morales contra Venom en Nueva York.', 69.99, 'PS5', 'Acción', 16, 2.00, 2, 3);
        $v['forza'] = $this->videojuego($empresas['Microsoft'], 'Forza Horizon 5', 'Conducción en mundo abierto por los paisajes de México.', 39.99, 'Xbox', 'Conducción', 3, 1.25, 2, 4);
        $v['halo'] = $this->videojuego($empresas['Microsoft'], 'Halo Infinite', 'El Jefe Maestro vuelve en la entrega más grande de Halo.', 29.99, 'Xbox', 'Shooter', 16, 1.00, 1, 2);
        $v['minecraft'] = $this->videojuego($empresas['Mojang'], 'Minecraft', 'Construye, explora y sobrevive en un mundo de bloques.', 29.99, 'Multi', 'Sandbox', 7, 1.00, 3, 10);

        // ---------- Consolas ----------
        $ps5 = $this->consola($empresas['Sony'], 'PlayStation 5 Slim', 'La PS5 en un formato más compacto, con lector de discos.', 499.99, 1000, 'Blanco', 'Estándar', 5);
        $switch = $this->consola($empresas['Nintendo'], 'Nintendo Switch OLED', 'Pantalla OLED de 7 pulgadas y base con puerto LAN.', 349.99, 64, 'Blanco', 'OLED', 6);
        $this->consola($empresas['Microsoft'], 'Xbox Series X', 'La Xbox más potente, con 4K a 120 fps.', 549.99, 1000, 'Negro', null, 3);
        $this->consola($empresas['Valve'], 'Steam Deck OLED', 'Tu biblioteca de Steam en una consola portátil.', 569.00, 512, 'Negro', 'OLED', 2);

        // ---------- Móviles y tablets ----------
        $galaxy = $this->movil($empresas['Samsung'], 'Samsung Galaxy S24', 'Pantalla Dynamic AMOLED y cámara de 50 MP.', 799.00, 6.2, 8, 256, 'Android', 4000, 7);
        $this->movil($empresas['Apple'], 'iPhone 16', 'Chip A18 y botón de Control de Cámara.', 959.00, 6.1, 8, 128, 'iOS', 3561, 5);
        $this->movil($empresas['Xiaomi'], 'Xiaomi Redmi Note 13', 'Gran autonomía a un precio ajustado.', 249.99, 6.7, 8, 256, 'Android', 5000, 12);

        $this->tablet($empresas['Apple'], 'iPad Air 11"', 'Chip M2, ligero y compatible con Apple Pencil.', 699.00, 11.0, 128, 'iPadOS', 'wifi', 4);
        $this->tablet($empresas['Samsung'], 'Samsung Galaxy Tab S9 FE', 'Resistente al agua y con S Pen incluido.', 449.00, 10.9, 128, 'Android', '5g', 3);
        $this->tablet($empresas['Xiaomi'], 'Xiaomi Pad 6', 'Pantalla de 144 Hz para jugar y ver series.', 349.99, 11.0, 128, 'Android', 'wifi', 6);

        // ---------- Usuarios ----------
        $ane = (new Cliente())
            ->setNombre('Ane')->setApellido1('Etxeberria')->setApellido2('Lasa')
            ->setDni('12345678Z')->setEmail('demo@juegalmi.es')->setTelefono('600123456')
            ->setFechaRegistro(new \DateTimeImmutable('-60 days'));
        $ane->setPassword($this->hasher->hashPassword($ane, '1234'));
        $this->om->persist($ane);

        $iker = (new Trabajador())
            ->setNombre('Iker')->setApellido1('Goikoetxea')->setApellido2('Arana')
            ->setDni('87654321X')->setEmail('iker@juegalmi.es')->setTelefono('611000111')
            ->setCargo('Responsable de taller')->setEsAdmin(true)
            ->setFechaContratacion(new \DateTimeImmutable('2015-03-01'));
        $iker->setPassword($this->hasher->hashPassword($iker, '1234'));
        $this->om->persist($iker);

        $maialen = (new Trabajador())
            ->setNombre('Maialen')->setApellido1('Uriarte')->setApellido2('Zubia')
            ->setDni('11223344B')->setEmail('maialen@juegalmi.es')->setTelefono('622000222')
            ->setCargo('Técnica de telefonía')->setEsAdmin(false)
            ->setFechaContratacion(new \DateTimeImmutable('2020-09-15'));
        $maialen->setPassword($this->hasher->hashPassword($maialen, '1234'));
        $this->om->persist($maialen);

        $this->om->persist((new TrabajadorDepartamento())->setTrabajador($iker)->setDepartamento($consolasDep)->setFechaInicio(new \DateTimeImmutable('2015-03-01')));
        $this->om->persist((new TrabajadorDepartamento())->setTrabajador($maialen)->setDepartamento($telefoniaDep)->setFechaInicio(new \DateTimeImmutable('2020-09-15')));
        $this->om->persist((new TrabajadorDepartamento())->setTrabajador($maialen)->setDepartamento($videojuegosDep)->setFechaInicio(new \DateTimeImmutable('2022-01-10')));

        // ---------- Domicilio y pedidos de Ane (4, como en la pantalla Cuenta) ----------
        $domicilio = (new Domicilio())
            ->setCliente($ane)
            ->setDireccion($this->direccion('Gran Vía', '12', '3ºB', '48001'))
            ->setFechaAlta(new \DateTimeImmutable('-60 days'));
        $this->om->persist($domicilio);

        $this->pedido($domicilio, '-40 days', 'entregado', [[$switch, 1], [$v['mario'], 1]]);
        $this->pedido($domicilio, '-25 days', 'entregado', [[$v['kart'], 1]]);
        $this->pedido($domicilio, '-10 days', 'enviado', [[$galaxy, 1]]);
        $this->pedido($domicilio, '-1 day', 'pendiente', [[$ps5, 1], [$v['mario'], 2]]);

        // ---------- Alquiler activo: Elden Ring (pantalla Cuenta, botón «Devolver») ----------
        $alquiler = (new Alquiler())
            ->setCliente($ane)
            ->setFechaInicio(new \DateTimeImmutable('-3 days midnight'))
            ->setFechaFinPrevista(new \DateTimeImmutable('+2 days midnight'));
        $alquiler->addLinea((new AlquilerVideojuego())->setVideojuego($v['elden']));
        $this->om->persist($alquiler);

        // Un alquiler antiguo ya devuelto
        $antiguo = (new Alquiler())
            ->setCliente($ane)
            ->setFechaInicio(new \DateTimeImmutable('-20 days midnight'))
            ->setFechaFinPrevista(new \DateTimeImmutable('-15 days midnight'));
        $antiguo->addLinea((new AlquilerVideojuego())->setVideojuego($v['zelda'])->setFechaDevolucion(new \DateTimeImmutable('-15 days midnight')));
        $this->om->persist($antiguo);

        // ---------- Reparación en curso: mando DualSense (pantallas 03 y 09) ----------
        $reparacion = (new Reparacion())
            ->setCliente($ane)
            ->setTipoDispositivo('mando')
            ->setMarca('Sony')
            ->setModelo('DualSense')
            ->setComponente('Joystick')
            ->setDescripcionAveria('Drift en el joystick izquierdo.')
            ->setPresupuesto(35.00);
        $reparacion->getHistorial()->first()->setFechaHora(new \DateTimeImmutable('-5 days 10:00'));
        $reparacion->cambiarEstado('diagnostico', 'Revisando el joystick y la placa.');
        $reparacion->getHistorial()->last()->setFechaHora(new \DateTimeImmutable('-4 days 12:00'));
        $reparacion->cambiarEstado('en_reparacion', 'Estamos sustituyendo o reparando las piezas.');
        $reparacion->getHistorial()->last()->setFechaHora(new \DateTimeImmutable('-2 days 9:30'));
        $reparacion->addAsignacion((new TrabajadorReparacion())->setTrabajador($iker)->setFechaInicio(new \DateTimeImmutable('-4 days 12:00')));
        $this->om->persist($reparacion);

        // ---------- Algunas localizaciones de Ane (Bilbao) ----------
        foreach ([['-2 days', 43.2627, -2.9253], ['-1 day', 43.2569, -2.9236], ['-3 hours', 43.2630, -2.9350]] as [$cuando, $lat, $lon]) {
            $this->om->persist((new Localizacion())->setCliente($ane)->setLatitud($lat)->setLongitud($lon)->setFechaHora(new \DateTimeImmutable($cuando)));
        }

        $this->om->flush();
    }

    // ---------- Ayudantes para no repetir código ----------

    private function direccion(string $calle, string $numero, ?string $piso, string $cp): Direccion
    {
        $direccion = (new Direccion())
            ->setCalle($calle)->setNumero($numero)->setPiso($piso)
            ->setCodigoPostal($cp)->setCiudad('Bilbao')->setProvincia('Bizkaia');
        $this->om->persist($direccion);

        return $direccion;
    }

    private function departamento(Tienda $tienda, string $nombre, string $descripcion, string $telefono): Departamento
    {
        $departamento = (new Departamento())
            ->setTienda($tienda)->setNombre($nombre)->setDescripcion($descripcion)->setTelefono($telefono);
        $this->om->persist($departamento);

        return $departamento;
    }

    private function videojuego(Empresa $empresa, string $nombre, string $descripcion, float $precio, string $plataforma, string $genero, int $pegi, float $precioDia, int $copias, int $stock): Videojuego
    {
        $juego = (new Videojuego())
            ->setPlataforma($plataforma)->setGenero($genero)->setPegi($pegi)
            ->setPrecioAlquilerDia($precioDia)->setCopiasAlquiler($copias);
        $juego->setEmpresa($empresa)->setNombre($nombre)->setDescripcion($descripcion)->setPrecioVenta($precio)->setStock($stock);
        $this->om->persist($juego);

        return $juego;
    }

    private function consola(Empresa $empresa, string $nombre, string $descripcion, float $precio, int $almacenamiento, string $color, ?string $edicion, int $stock): Consola
    {
        $consola = (new Consola())->setAlmacenamientoGb($almacenamiento)->setColor($color)->setEdicion($edicion);
        $consola->setEmpresa($empresa)->setNombre($nombre)->setDescripcion($descripcion)->setPrecioVenta($precio)->setStock($stock);
        $this->om->persist($consola);

        return $consola;
    }

    private function movil(Empresa $empresa, string $nombre, string $descripcion, float $precio, float $pulgadas, int $ram, int $almacenamiento, string $so, int $bateria, int $stock): Movil
    {
        $movil = (new Movil())
            ->setPantallaPulgadas($pulgadas)->setRamGb($ram)->setAlmacenamientoGb($almacenamiento)
            ->setSistemaOperativo($so)->setBateriaMah($bateria);
        $movil->setEmpresa($empresa)->setNombre($nombre)->setDescripcion($descripcion)->setPrecioVenta($precio)->setStock($stock);
        $this->om->persist($movil);

        return $movil;
    }

    private function tablet(Empresa $empresa, string $nombre, string $descripcion, float $precio, float $pulgadas, int $almacenamiento, string $so, string $conectividad, int $stock): Tablet
    {
        $tablet = (new Tablet())
            ->setPantallaPulgadas($pulgadas)->setAlmacenamientoGb($almacenamiento)
            ->setSistemaOperativo($so)->setConectividad($conectividad);
        $tablet->setEmpresa($empresa)->setNombre($nombre)->setDescripcion($descripcion)->setPrecioVenta($precio)->setStock($stock);
        $this->om->persist($tablet);

        return $tablet;
    }

    /** @param array<array{0: \App\Entity\Producto, 1: int}> $lineas */
    private function pedido(Domicilio $domicilio, string $cuando, string $estado, array $lineas): void
    {
        $pedido = (new Pedido())
            ->setDomicilio($domicilio)
            ->setFecha(new \DateTimeImmutable($cuando))
            ->setEstado($estado);

        foreach ($lineas as [$producto, $cantidad]) {
            $pedido->addLinea((new PedidoProducto())->setProducto($producto)->setCantidad($cantidad));
        }

        $this->om->persist($pedido);
    }
}
