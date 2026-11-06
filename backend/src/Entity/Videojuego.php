<?php

namespace App\Entity;

use Doctrine\DBAL\Types\Types;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Validator\Constraints as Assert;

#[ORM\Entity]
#[ORM\Table(name: 'videojuego')]
class Videojuego extends Producto
{
    public const PEGI = [3, 7, 12, 16, 18];

    #[ORM\Column(length: 30)]
    #[Assert\NotBlank(message: 'La plataforma es obligatoria')]
    private ?string $plataforma = null;

    #[ORM\Column(length: 30)]
    #[Assert\NotBlank(message: 'El género es obligatorio')]
    private ?string $genero = null;

    #[ORM\Column(type: Types::SMALLINT)]
    #[Assert\NotNull(message: 'El PEGI es obligatorio')]
    #[Assert\Choice(choices: self::PEGI, message: 'El PEGI tiene que ser 3, 7, 12, 16 o 18')]
    private ?int $pegi = null;

    #[ORM\Column(name: 'precio_alquiler_dia', type: Types::DECIMAL, precision: 6, scale: 2)]
    #[Assert\NotNull(message: 'El precio de alquiler es obligatorio')]
    #[Assert\PositiveOrZero(message: 'El precio de alquiler no puede ser negativo')]
    private ?string $precioAlquilerDia = null;

    #[ORM\Column(name: 'copias_alquiler', options: ['default' => 0])]
    #[Assert\PositiveOrZero(message: 'Las copias de alquiler no pueden ser negativas')]
    private int $copiasAlquiler = 0;

    public function getPlataforma(): ?string { return $this->plataforma; }
    public function setPlataforma(string $plataforma): static { $this->plataforma = $plataforma; return $this; }

    public function getGenero(): ?string { return $this->genero; }
    public function setGenero(string $genero): static { $this->genero = $genero; return $this; }

    public function getPegi(): ?int { return $this->pegi; }
    public function setPegi(int $pegi): static { $this->pegi = $pegi; return $this; }

    public function getPrecioAlquilerDia(): ?float { return $this->precioAlquilerDia === null ? null : (float) $this->precioAlquilerDia; }
    public function setPrecioAlquilerDia(float $precio): static { $this->precioAlquilerDia = number_format($precio, 2, '.', ''); return $this; }

    public function getCopiasAlquiler(): int { return $this->copiasAlquiler; }
    public function setCopiasAlquiler(int $copiasAlquiler): static { $this->copiasAlquiler = $copiasAlquiler; return $this; }

    public function getTipo(): string { return 'videojuego'; }
}
