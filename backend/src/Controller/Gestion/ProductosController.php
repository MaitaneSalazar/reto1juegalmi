<?php

namespace App\Controller\Gestion;

use App\Entity\Consola;
use App\Entity\Empresa;
use App\Entity\EntradaStock;
use App\Entity\Movil;
use App\Entity\Producto;
use App\Entity\Tablet;
use App\Entity\Trabajador;
use App\Entity\Videojuego;
use App\Service\SubidaImagenes;
use Doctrine\ORM\EntityManagerInterface;
use Doctrine\ORM\Tools\Pagination\Paginator;
use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;
use Symfony\Component\Validator\Validator\ValidatorInterface;

/** Pantallas 03 a 06 del mockup: productos y stock */
#[Route('/gestion/productos')]
class ProductosController extends AbstractController
{
    public const TIPOS = ['videojuego' => Videojuego::class, 'consola' => Consola::class, 'movil' => Movil::class, 'tablet' => Tablet::class];
    public const NOMBRES_TIPO = ['videojuego' => 'Videojuego', 'consola' => 'Consola', 'movil' => 'Móvil', 'tablet' => 'Tablet'];
    public const PLATAFORMAS = ['PlayStation', 'Switch', 'Xbox'];
    private const POR_PAGINA = 10;

    /** Campos propios de cada tipo de producto y qué dato llevan */
    private const CAMPOS = [
        'videojuego' => ['plataforma' => 'texto', 'genero' => 'texto', 'pegi' => 'entero', 'precio_alquiler_dia' => 'decimal', 'copias_alquiler' => 'entero'],
        'consola' => ['almacenamiento_gb' => 'entero', 'color' => 'texto', 'edicion' => 'texto'],
        'movil' => ['pantalla_pulgadas' => 'decimal', 'ram_gb' => 'entero', 'almacenamiento_gb' => 'entero', 'sistema_operativo' => 'texto', 'bateria_mah' => 'entero'],
        'tablet' => ['pantalla_pulgadas' => 'decimal', 'almacenamiento_gb' => 'entero', 'sistema_operativo' => 'texto', 'conectividad' => 'texto'],
    ];
    private const OBLIGATORIOS = ['plataforma', 'genero', 'pegi'];

    public function __construct(private EntityManagerInterface $em)
    {
    }

    #[Route('', name: 'gestion_productos', methods: ['GET'])]
    public function listado(Request $request): Response
    {
        $tipo = (string) $request->query->get('tipo', '');
        $tipo = isset(self::TIPOS[$tipo]) ? $tipo : '';
        $q = trim((string) $request->query->get('q', ''));
        $pagina = max(1, $request->query->getInt('page', 1));

        $qb = $this->em->createQueryBuilder()
            ->select('p', 'e')->from(Producto::class, 'p')->leftJoin('p.empresa', 'e')
            ->orderBy('p.nombre', 'ASC');
        if ($tipo !== '') {
            $qb->andWhere('p INSTANCE OF ' . self::TIPOS[$tipo]);
        }
        if ($q !== '') {
            $qb->andWhere('(LOWER(p.nombre) LIKE :q OR LOWER(e.nombre) LIKE :q)')->setParameter('q', '%' . mb_strtolower($q) . '%');
        }
        $qb->setFirstResult(($pagina - 1) * self::POR_PAGINA)->setMaxResults(self::POR_PAGINA);
        $paginador = new Paginator($qb);
        $total = count($paginador);

        // Desde el Resumen («Añadir stock») se llega con ?stock=ID y se abre la ventana directamente
        $abrir = $request->query->getInt('stock') ? $this->em->find(Producto::class, $request->query->getInt('stock')) : null;

        return $this->render('gestion/productos/listado.html.twig', [
            'productos' => iterator_to_array($paginador),
            'total' => $total,
            'pagina' => $pagina,
            'paginas' => max(1, (int) ceil($total / self::POR_PAGINA)),
            'por_pagina' => self::POR_PAGINA,
            'tipo' => $tipo,
            'q' => $q,
            'nombres_tipo' => self::NOMBRES_TIPO,
            'stock_bajo' => ResumenController::STOCK_BAJO,
            'abrir_stock' => $abrir,
        ]);
    }

    /** Ventana «Añadir stock»: suma unidades y guarda la entrada con su nota */
    #[Route('/{id}/stock', name: 'gestion_producto_stock', requirements: ['id' => '\d+'], methods: ['POST'])]
    public function anadirStock(Producto $producto, Request $request): Response
    {
        if (!$this->isCsrfTokenValid('stock', (string) $request->request->get('_token'))) {
            $this->addFlash('danger', 'El formulario ha caducado. Vuelve a intentarlo.');
            return $this->volver($request);
        }

        $cantidad = $request->request->getInt('cantidad');
        if ($cantidad < 1 || $cantidad > 999) {
            $this->addFlash('danger', 'La entrada tiene que ser de 1 a 999 unidades.');
            return $this->volver($request);
        }

        $nota = trim((string) $request->request->get('nota', ''));
        $entrada = (new EntradaStock())
            ->setProducto($producto)
            ->setCantidad($cantidad)
            ->setNota($nota === '' ? null : mb_substr($nota, 0, 120));
        if ($this->getUser() instanceof Trabajador) {
            $entrada->setTrabajador($this->getUser());
        }

        $producto->setStock($producto->getStock() + $cantidad);
        $this->em->persist($entrada);
        $this->em->flush();

        $this->addFlash('success', sprintf('Añadidas %d unidades a «%s». Ahora hay %d.', $cantidad, $producto->getNombre(), $producto->getStock()));
        return $this->volver($request);
    }

    /** Interruptor «Activo» (al desactivar, la web pide confirmación antes) */
    #[Route('/{id}/activo', name: 'gestion_producto_activo', requirements: ['id' => '\d+'], methods: ['POST'])]
    public function activo(Producto $producto, Request $request): Response
    {
        if (!$this->isCsrfTokenValid('activo', (string) $request->request->get('_token'))) {
            $this->addFlash('danger', 'El formulario ha caducado. Vuelve a intentarlo.');
            return $this->volver($request);
        }

        $activo = $request->request->getBoolean('activo');
        $producto->setActivo($activo);
        $this->em->flush();

        $this->addFlash('success', $activo
            ? sprintf('«%s» vuelve a estar activo y se ve en la app.', $producto->getNombre())
            : sprintf('«%s» se ha desactivado: ya no aparece en la app.', $producto->getNombre()));
        return $this->volver($request);
    }

    #[Route('/nuevo', name: 'gestion_producto_nuevo', methods: ['GET', 'POST'])]
    public function nuevo(Request $request, SubidaImagenes $subida, ValidatorInterface $validator): Response
    {
        return $this->formulario($request, null, $subida, $validator);
    }

    #[Route('/{id}/editar', name: 'gestion_producto_editar', requirements: ['id' => '\d+'], methods: ['GET', 'POST'])]
    public function editar(Producto $producto, Request $request, SubidaImagenes $subida, ValidatorInterface $validator): Response
    {
        return $this->formulario($request, $producto, $subida, $validator);
    }

    private function formulario(Request $request, ?Producto $producto, SubidaImagenes $subida, ValidatorInterface $validator): Response
    {
        $esNuevo = $producto === null;
        $tipo = $producto?->getTipo() ?? (string) $request->request->get('tipo', $request->query->get('tipo', 'videojuego'));
        $tipo = isset(self::TIPOS[$tipo]) ? $tipo : 'videojuego';
        $valores = $producto ? $this->valoresDe($producto) : ['activo' => true, 'stock' => 0, 'pegi' => 7, 'copias_alquiler' => 0, 'conectividad' => 'wifi'];
        $errores = [];

        if ($request->isMethod('POST')) {
            $valores = $request->request->all();
            $valores['activo'] = $request->request->has('activo');

            if (!$this->isCsrfTokenValid('producto', (string) $request->request->get('_token'))) {
                $errores['_'] = 'El formulario ha caducado. Vuelve a intentarlo.';
            }

            $clase = self::TIPOS[$tipo];
            $objeto = $producto ?? new $clase();
            $errores += $this->aplicar($objeto, $tipo, $valores);

            if ($errores === []) {
                foreach ($validator->validate($objeto) as $error) {
                    $errores[strtolower(preg_replace('/[A-Z]/', '_$0', $error->getPropertyPath()))] ??= $error->getMessage();
                }
            }

            $archivo = $request->files->get('imagen');
            if ($errores === [] && $archivo !== null) {
                try {
                    $objeto->setImagen($subida->subir($archivo, 'productos'));
                } catch (\InvalidArgumentException $e) {
                    $errores['imagen'] = $e->getMessage();
                }
            }

            if ($errores === []) {
                if ($esNuevo) {
                    $this->em->persist($objeto);
                }
                $this->em->flush();
                $this->addFlash('success', sprintf('«%s» se ha guardado.', $objeto->getNombre()));
                return $this->redirectToRoute('gestion_productos');
            }

            if (!$esNuevo) {
                $this->em->refresh($producto); // se descartan los cambios a medias
            }
        }

        return $this->render('gestion/productos/formulario.html.twig', [
            'producto' => $producto,
            'es_nuevo' => $esNuevo,
            'tipo' => $tipo,
            'v' => $valores,
            'errores' => $errores,
            'empresas' => $this->em->getRepository(Empresa::class)->findBy([], ['nombre' => 'ASC']),
            'nombres_tipo' => self::NOMBRES_TIPO,
            'plataformas' => self::PLATAFORMAS,
            'pegis' => Videojuego::PEGI,
            'generos' => $this->em->createQueryBuilder()->select('DISTINCT v.genero')->from(Videojuego::class, 'v')
                ->where('v.genero IS NOT NULL')->orderBy('v.genero')->getQuery()->getSingleColumnResult(),
        ]);
    }

    /** Pasa los datos del formulario al producto; devuelve los errores por campo */
    private function aplicar(Producto $producto, string $tipo, array $v): array
    {
        $errores = [];

        $nombre = trim((string) ($v['nombre'] ?? ''));
        $nombre === '' ? $errores['nombre'] = 'Escribe el nombre del producto.' : $producto->setNombre($nombre);

        $descripcion = trim((string) ($v['descripcion'] ?? ''));
        $producto->setDescripcion($descripcion === '' ? null : $descripcion);

        $empresa = $this->em->find(Empresa::class, (int) ($v['empresa'] ?? 0));
        $empresa === null ? $errores['empresa'] = 'Elige la marca.' : $producto->setEmpresa($empresa);

        $precio = $this->numero($v['precio_venta'] ?? '');
        ($precio === null || $precio < 0) ? $errores['precio_venta'] = 'Escribe un precio válido, por ejemplo 49,99.' : $producto->setPrecioVenta($precio);

        $stock = filter_var($v['stock'] ?? '', FILTER_VALIDATE_INT);
        ($stock === false || $stock < 0) ? $errores['stock'] = 'El stock tiene que ser un número entero, 0 o más.' : $producto->setStock($stock);

        $producto->setActivo((bool) ($v['activo'] ?? false));

        foreach (self::CAMPOS[$tipo] as $campo => $dato) {
            $texto = trim((string) ($v[$campo] ?? ''));
            if ($texto === '') {
                if (in_array($campo, self::OBLIGATORIOS, true)) {
                    $errores[$campo] = 'Este campo es obligatorio.';
                }
                continue;
            }
            $valor = match ($dato) {
                'entero' => filter_var($texto, FILTER_VALIDATE_INT),
                'decimal' => $this->numero($texto),
                default => $texto,
            };
            if ($valor === false || $valor === null || (is_numeric($valor) && $valor < 0)) {
                $errores[$campo] = 'Escribe un número válido.';
                continue;
            }
            $producto->{'set' . $this->camel($campo)}($valor);
        }

        if ($tipo === 'videojuego' && !isset($errores['plataforma']) && !in_array($v['plataforma'] ?? '', self::PLATAFORMAS, true)) {
            $errores['plataforma'] = 'Elige una plataforma.';
        }
        if ($tipo === 'videojuego' && !isset($errores['pegi']) && !in_array((int) ($v['pegi'] ?? 0), Videojuego::PEGI, true)) {
            $errores['pegi'] = 'Elige un PEGI.';
        }

        return $errores;
    }

    /** Datos de un producto para rellenar el formulario de editar */
    private function valoresDe(Producto $producto): array
    {
        $valores = [
            'nombre' => $producto->getNombre(),
            'descripcion' => $producto->getDescripcion(),
            'empresa' => $producto->getEmpresa()?->getId(),
            'precio_venta' => $producto->getPrecioVenta() === null ? '' : number_format($producto->getPrecioVenta(), 2, ',', ''),
            'stock' => $producto->getStock(),
            'activo' => $producto->isActivo(),
        ];
        foreach (self::CAMPOS[$producto->getTipo()] as $campo => $dato) {
            $valor = $producto->{'get' . $this->camel($campo)}();
            $valores[$campo] = $dato === 'decimal' && $valor !== null ? str_replace('.', ',', (string) $valor) : $valor;
        }

        return $valores;
    }

    private function numero(mixed $texto): ?float
    {
        $texto = str_replace(',', '.', trim((string) $texto));
        return is_numeric($texto) ? (float) $texto : null;
    }

    /** precio_alquiler_dia → PrecioAlquilerDia */
    private function camel(string $campo): string
    {
        return str_replace(' ', '', ucwords(str_replace('_', ' ', $campo)));
    }

    /** Vuelve al listado tal y como estaba (pestaña, búsqueda y página) */
    private function volver(Request $request): Response
    {
        $url = (string) $request->request->get('volver', '');
        return $this->redirect(str_starts_with($url, '/gestion/productos') ? $url : $this->generateUrl('gestion_productos'));
    }
}
