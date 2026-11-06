<?php

namespace App\Entity;

use Doctrine\DBAL\Types\Types;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Validator\Constraints as Assert;

// ALQUILER N — incluye — M VIDEOJUEGO (con precio y fecha_devolucion)
#[ORM\Entity]
#[ORM\Table(name: 'alquiler_videojuego')]
#[ORM\UniqueConstraint(name: 'uniq_alquiler_videojuego', columns: ['id_alquiler', 'id_videojuego'])]
class AlquilerVideojuego
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column(name: 'id_alquiler_videojuego')]
    private ?int $id = null;

    // Precio por día en el momento del alquiler
    #[ORM\Column(type: Types::DECIMAL, precision: 6, scale: 2)]
    #[Assert\NotNull(message: 'El precio es obligatorio')]
    #[Assert\PositiveOrZero(message: 'El precio no puede ser negativo')]
    private ?string $precio = null;

    #[ORM\Column(name: 'fecha_devolucion', type: Types::DATE_IMMUTABLE, nullable: true)]
    private ?\DateTimeImmutable $fechaDevolucion = null;

    #[ORM\ManyToOne(targetEntity: Alquiler::class, inversedBy: 'lineas')]
    #[ORM\JoinColumn(name: 'id_alquiler', referencedColumnName: 'id_alquiler', nullable: false, onDelete: 'CASCADE')]
    private ?Alquiler $alquiler = null;

    #[ORM\ManyToOne(targetEntity: Videojuego::class)]
    #[ORM\JoinColumn(name: 'id_videojuego', referencedColumnName: 'id_producto', nullable: false)]
    #[Assert\NotNull(message: 'Hay que indicar el videojuego')]
    private ?Videojuego $videojuego = null;

    public function getId(): ?int { return $this->id; }

    public function getPrecio(): ?float { return $this->precio === null ? null : (float) $this->precio; }
    public function setPrecio(float $precio): static { $this->precio = number_format($precio, 2, '.', ''); return $this; }

    public function getFechaDevolucion(): ?\DateTimeImmutable { return $this->fechaDevolucion; }
    public function setFechaDevolucion(?\DateTimeImmutable $fechaDevolucion): static { $this->fechaDevolucion = $fechaDevolucion; return $this; }

    public function getAlquiler(): ?Alquiler { return $this->alquiler; }
    public function setAlquiler(?Alquiler $alquiler): static { $this->alquiler = $alquiler; return $this; }

    public function getVideojuego(): ?Videojuego { return $this->videojuego; }

    /** Al asignar el videojuego se copia su precio de alquiler por día de ese momento */
    public function setVideojuego(Videojuego $videojuego): static
    {
        $this->videojuego = $videojuego;
        if ($this->precio === null) {
            $this->setPrecio($videojuego->getPrecioAlquilerDia());
        }

        return $this;
    }

    /** Días de alquiler: hasta la devolución, o hasta la fecha prevista si aún no se ha devuelto (mínimo 1) */
    public function getDias(): int
    {
        $inicio = $this->alquiler?->getFechaInicio();
        $fin = $this->fechaDevolucion ?? $this->alquiler?->getFechaFinPrevista();

        if ($inicio === null || $fin === null) {
            return 1;
        }

        return max(1, (int) $inicio->diff($fin)->days);
    }

    public function getImporte(): float
    {
        return round($this->getDias() * ($this->getPrecio() ?? 0), 2);
    }
}
