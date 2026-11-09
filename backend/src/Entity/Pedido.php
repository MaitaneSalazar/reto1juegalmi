<?php

namespace App\Entity;

use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\Common\Collections\Collection;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Validator\Constraints as Assert;

#[ORM\Entity]
#[ORM\Table(name: 'pedido')]
class Pedido
{
    public const ESTADOS = ['pendiente', 'preparando', 'enviado', 'entregado', 'cancelado'];

    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column(name: 'id_pedido')]
    private ?int $id = null;

    #[ORM\Column]
    private \DateTimeImmutable $fecha;

    #[ORM\Column(length: 20, options: ['default' => 'pendiente'])]
    #[Assert\Choice(choices: self::ESTADOS, message: 'El estado no es válido')]
    private string $estado = 'pendiente';

    // DOMICILIO 1 — se envía a — N PEDIDO
    #[ORM\ManyToOne(targetEntity: Domicilio::class)]
    #[ORM\JoinColumn(name: 'id_domicilio', referencedColumnName: 'id_domicilio', nullable: false)]
    #[Assert\NotNull(message: 'Hay que indicar el domicilio de envío')]
    private ?Domicilio $domicilio = null;

    /** @var Collection<int, PedidoProducto> */
    #[ORM\OneToMany(targetEntity: PedidoProducto::class, mappedBy: 'pedido', cascade: ['persist'], orphanRemoval: true)]
    #[Assert\Count(min: 1, minMessage: 'El pedido tiene que tener al menos un producto')]
    #[Assert\Valid]
    private Collection $lineas;

    public function __construct()
    {
        $this->fecha = new \DateTimeImmutable();
        $this->lineas = new ArrayCollection();
    }

    public function getId(): ?int { return $this->id; }

    public function getFecha(): \DateTimeImmutable { return $this->fecha; }
    public function setFecha(\DateTimeImmutable $fecha): static { $this->fecha = $fecha; return $this; }

    public function getEstado(): string { return $this->estado; }
    public function setEstado(string $estado): static { $this->estado = $estado; return $this; }

    public function getDomicilio(): ?Domicilio { return $this->domicilio; }
    public function setDomicilio(Domicilio $domicilio): static { $this->domicilio = $domicilio; return $this; }

    /** El cliente se obtiene a través del domicilio, como en el E-R */
    public function getCliente(): ?Cliente { return $this->domicilio?->getCliente(); }

    /** @return Collection<int, PedidoProducto> */
    public function getLineas(): Collection { return $this->lineas; }

    public function addLinea(PedidoProducto $linea): static
    {
        if (!$this->lineas->contains($linea)) {
            $this->lineas->add($linea);
            $linea->setPedido($this);
        }

        return $this;
    }

    public function removeLinea(PedidoProducto $linea): static
    {
        $this->lineas->removeElement($linea);

        return $this;
    }

    /** Total calculado a partir de las líneas (no se guarda en la base de datos) */
    public function getTotal(): float
    {
        $total = 0.0;
        foreach ($this->lineas as $linea) {
            $total += $linea->getSubtotal();
        }

        return round($total, 2);
    }

    public function __toString(): string { return 'Pedido #' . $this->id; }
}
