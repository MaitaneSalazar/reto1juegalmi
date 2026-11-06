<?php

namespace App\Entity;

use Doctrine\DBAL\Types\Types;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Validator\Constraints as Assert;
use Symfony\Component\HttpFoundation\File\UploadedFile;

#[ORM\Entity]
#[ORM\Table(name: 'producto')]
#[ORM\InheritanceType('JOINED')]
#[ORM\DiscriminatorColumn(name: 'tipo', type: 'string', length: 20)]
#[ORM\DiscriminatorMap([
    'movil' => Movil::class,
    'tablet' => Tablet::class,
    'consola' => Consola::class,
    'videojuego' => Videojuego::class,
])]
abstract class Producto
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column(name: 'id_producto')]
    private ?int $id = null;

    #[ORM\Column(length: 120)]
    #[Assert\NotBlank(message: 'El nombre es obligatorio')]
    #[Assert\Length(max: 120, maxMessage: 'El nombre no puede tener más de 120 caracteres')]
    private ?string $nombre = null;

    #[ORM\Column(type: Types::TEXT, nullable: true)]
    private ?string $descripcion = null;

    #[ORM\Column(name: 'precio_venta', type: Types::DECIMAL, precision: 8, scale: 2)]
    #[Assert\NotNull(message: 'El precio es obligatorio')]
    #[Assert\PositiveOrZero(message: 'El precio no puede ser negativo')]
    private ?string $precioVenta = null;

    #[ORM\Column(options: ['default' => 0])]
    #[Assert\PositiveOrZero(message: 'El stock no puede ser negativo')]
    private int $stock = 0;

    #[ORM\Column(length: 255, nullable: true)]
    private ?string $imagen = null;

    #[ORM\Column(options: ['default' => true])]
    private bool $activo = true;

    // EMPRESA 1 — fabrica — N PRODUCTO
    #[ORM\ManyToOne(targetEntity: Empresa::class)]
    #[ORM\JoinColumn(name: 'id_empresa', referencedColumnName: 'id_empresa', nullable: false)]
    #[Assert\NotNull(message: 'Hay que indicar la empresa que lo fabrica')]
    private ?Empresa $empresa = null;

    /** Solo para el formulario de la web: no tiene columna en la base de datos */
    private ?UploadedFile $archivoImagen = null;

    public function getId(): ?int { return $this->id; }

    public function getNombre(): ?string { return $this->nombre; }
    public function setNombre(string $nombre): static { $this->nombre = $nombre; return $this; }

    public function getDescripcion(): ?string { return $this->descripcion; }
    public function setDescripcion(?string $descripcion): static { $this->descripcion = $descripcion; return $this; }

    public function getPrecioVenta(): ?float { return $this->precioVenta === null ? null : (float) $this->precioVenta; }
    public function setPrecioVenta(float $precioVenta): static { $this->precioVenta = number_format($precioVenta, 2, '.', ''); return $this; }

    public function getStock(): int { return $this->stock; }
    public function setStock(int $stock): static { $this->stock = $stock; return $this; }

    public function getImagen(): ?string { return $this->imagen; }
    public function setImagen(?string $imagen): static { $this->imagen = $imagen; return $this; }

    public function isActivo(): bool { return $this->activo; }
    public function setActivo(bool $activo): static { $this->activo = $activo; return $this; }

    public function getEmpresa(): ?Empresa { return $this->empresa; }
    public function setEmpresa(Empresa $empresa): static { $this->empresa = $empresa; return $this; }

    /** movil, tablet, consola o videojuego (lo usará la API para filtrar) */
    public function getArchivoImagen(): ?UploadedFile { return $this->archivoImagen; }
    public function setArchivoImagen(?UploadedFile $archivo): static { $this->archivoImagen = $archivo; return $this; }

    abstract public function getTipo(): string;

    public function __toString(): string { return (string) $this->nombre; }
}
