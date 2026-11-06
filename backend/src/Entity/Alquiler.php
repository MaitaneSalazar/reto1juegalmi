<?php

namespace App\Entity;

use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\Common\Collections\Collection;
use Doctrine\DBAL\Types\Types;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Validator\Constraints as Assert;

#[ORM\Entity]
#[ORM\Table(name: 'alquiler')]
class Alquiler
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column(name: 'id_alquiler')]
    private ?int $id = null;

    #[ORM\Column(name: 'fecha_inicio', type: Types::DATE_IMMUTABLE)]
    private \DateTimeImmutable $fechaInicio;

    #[ORM\Column(name: 'fecha_fin_prevista', type: Types::DATE_IMMUTABLE)]
    #[Assert\NotNull(message: 'La fecha de fin prevista es obligatoria')]
    #[Assert\GreaterThanOrEqual(propertyPath: 'fechaInicio', message: 'La fecha de fin no puede ser anterior a la de inicio')]
    private ?\DateTimeImmutable $fechaFinPrevista = null;

    // CLIENTE 1 — alquila — N ALQUILER
    #[ORM\ManyToOne(targetEntity: Cliente::class)]
    #[ORM\JoinColumn(name: 'id_cliente', referencedColumnName: 'id_usuario', nullable: false)]
    #[Assert\NotNull(message: 'El alquiler tiene que pertenecer a un cliente')]
    private ?Cliente $cliente = null;

    /** @var Collection<int, AlquilerVideojuego> */
    #[ORM\OneToMany(targetEntity: AlquilerVideojuego::class, mappedBy: 'alquiler', cascade: ['persist'], orphanRemoval: true)]
    #[Assert\Count(min: 1, minMessage: 'El alquiler tiene que incluir al menos un videojuego')]
    #[Assert\Valid]
    private Collection $lineas;

    /** Solo para el formulario «Devolución» de la web: no tiene columna en la base de datos */
    private bool $marcarDevuelto = false;

    public function __construct()
    {
        $this->fechaInicio = new \DateTimeImmutable('today');
        $this->lineas = new ArrayCollection();
    }

    public function getId(): ?int { return $this->id; }

    public function getFechaInicio(): \DateTimeImmutable { return $this->fechaInicio; }
    public function setFechaInicio(\DateTimeImmutable $fechaInicio): static { $this->fechaInicio = $fechaInicio; return $this; }

    public function getFechaFinPrevista(): ?\DateTimeImmutable { return $this->fechaFinPrevista; }
    public function setFechaFinPrevista(\DateTimeImmutable $fechaFinPrevista): static { $this->fechaFinPrevista = $fechaFinPrevista; return $this; }

    public function getCliente(): ?Cliente { return $this->cliente; }
    public function setCliente(Cliente $cliente): static { $this->cliente = $cliente; return $this; }

    /** @return Collection<int, AlquilerVideojuego> */
    public function getLineas(): Collection { return $this->lineas; }

    public function addLinea(AlquilerVideojuego $linea): static
    {
        if (!$this->lineas->contains($linea)) {
            $this->lineas->add($linea);
            $linea->setAlquiler($this);
        }

        return $this;
    }

    public function removeLinea(AlquilerVideojuego $linea): static
    {
        $this->lineas->removeElement($linea);

        return $this;
    }

    /** activo, retrasado o devuelto (calculado, no se guarda) */
    public function getEstado(): string
    {
        $pendientes = $this->lineas->filter(fn (AlquilerVideojuego $l) => $l->getFechaDevolucion() === null);

        if ($pendientes->isEmpty()) {
            return 'devuelto';
        }

        return new \DateTimeImmutable('today') > $this->fechaFinPrevista ? 'retrasado' : 'activo';
    }

    /** Importe total calculado a partir de las líneas */
    public function getImporte(): float
    {
        $total = 0.0;
        foreach ($this->lineas as $linea) {
            $total += $linea->getImporte();
        }

        return round($total, 2);
    }

    public function isMarcarDevuelto(): bool { return $this->marcarDevuelto; }
    public function setMarcarDevuelto(bool $marcar): static { $this->marcarDevuelto = $marcar; return $this; }
    public function __toString(): string { return 'Alquiler #' . $this->id; }
}
