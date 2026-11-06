<?php

namespace App\Entity;

use Doctrine\DBAL\Types\Types;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Validator\Constraints as Assert;

// PEDIDO N — contiene — M PRODUCTO (con cantidad y precio_unitario)
#[ORM\Entity]
#[ORM\Table(name: 'pedido_producto')]
#[ORM\UniqueConstraint(name: 'uniq_pedido_producto', columns: ['id_pedido', 'id_producto'])]
class PedidoProducto
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column(name: 'id_pedido_producto')]
    private ?int $id = null;

    #[ORM\Column]
    #[Assert\NotNull(message: 'La cantidad es obligatoria')]
    #[Assert\Positive(message: 'La cantidad tiene que ser al menos 1')]
    private ?int $cantidad = null;

    #[ORM\Column(name: 'precio_unitario', type: Types::DECIMAL, precision: 8, scale: 2)]
    #[Assert\NotNull(message: 'El precio unitario es obligatorio')]
    #[Assert\PositiveOrZero(message: 'El precio no puede ser negativo')]
    private ?string $precioUnitario = null;

    #[ORM\ManyToOne(targetEntity: Pedido::class, inversedBy: 'lineas')]
    #[ORM\JoinColumn(name: 'id_pedido', referencedColumnName: 'id_pedido', nullable: false, onDelete: 'CASCADE')]
    private ?Pedido $pedido = null;

    #[ORM\ManyToOne(targetEntity: Producto::class)]
    #[ORM\JoinColumn(name: 'id_producto', referencedColumnName: 'id_producto', nullable: false)]
    #[Assert\NotNull(message: 'Hay que indicar el producto')]
    private ?Producto $producto = null;

    public function getId(): ?int { return $this->id; }

    public function getCantidad(): ?int { return $this->cantidad; }
    public function setCantidad(int $cantidad): static { $this->cantidad = $cantidad; return $this; }

    public function getPrecioUnitario(): ?float { return $this->precioUnitario === null ? null : (float) $this->precioUnitario; }
    public function setPrecioUnitario(float $precio): static { $this->precioUnitario = number_format($precio, 2, '.', ''); return $this; }

    public function getPedido(): ?Pedido { return $this->pedido; }
    public function setPedido(?Pedido $pedido): static { $this->pedido = $pedido; return $this; }

    public function getProducto(): ?Producto { return $this->producto; }

    /** Al asignar el producto se copia su precio actual: el precio queda fijado aunque cambie después */
    public function setProducto(Producto $producto): static
    {
        $this->producto = $producto;
        if ($this->precioUnitario === null) {
            $this->setPrecioUnitario($producto->getPrecioVenta());
        }

        return $this;
    }

    public function getSubtotal(): float
    {
        return round(($this->cantidad ?? 0) * ($this->getPrecioUnitario() ?? 0), 2);
    }
}
