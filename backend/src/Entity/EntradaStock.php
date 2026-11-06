<?php

namespace App\Entity;

use Doctrine\ORM\Mapping as ORM;

/** Cada vez que se añaden unidades de un producto desde la web («Añadir stock») */
#[ORM\Entity]
#[ORM\Table(name: 'entrada_stock')]
class EntradaStock
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column(name: 'id_entrada')]
    private ?int $id = null;

    #[ORM\ManyToOne]
    #[ORM\JoinColumn(name: 'id_producto', referencedColumnName: 'id_producto', nullable: false, onDelete: 'CASCADE')]
    private ?Producto $producto = null;

    /** Quién la registró (si se da de baja al trabajador, la entrada se queda sin nombre) */
    #[ORM\ManyToOne]
    #[ORM\JoinColumn(name: 'id_trabajador', referencedColumnName: 'id_usuario', nullable: true, onDelete: 'SET NULL')]
    private ?Trabajador $trabajador = null;

    #[ORM\Column]
    private int $cantidad = 0;

    /** Nº de albarán o proveedor */
    #[ORM\Column(length: 120, nullable: true)]
    private ?string $nota = null;

    #[ORM\Column(name: 'fecha_hora')]
    private \DateTimeImmutable $fechaHora;

    public function __construct()
    {
        $this->fechaHora = new \DateTimeImmutable();
    }

    public function getId(): ?int { return $this->id; }

    public function getProducto(): ?Producto { return $this->producto; }
    public function setProducto(Producto $producto): static { $this->producto = $producto; return $this; }

    public function getTrabajador(): ?Trabajador { return $this->trabajador; }
    public function setTrabajador(?Trabajador $trabajador): static { $this->trabajador = $trabajador; return $this; }

    public function getCantidad(): int { return $this->cantidad; }
    public function setCantidad(int $cantidad): static { $this->cantidad = $cantidad; return $this; }

    public function getNota(): ?string { return $this->nota; }
    public function setNota(?string $nota): static { $this->nota = $nota; return $this; }

    public function getFechaHora(): \DateTimeImmutable { return $this->fechaHora; }
}
