<?php

namespace App\Entity;

use Doctrine\DBAL\Types\Types;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Validator\Constraints as Assert;

#[ORM\Entity]
#[ORM\Table(name: 'consola')]
class Consola extends Producto
{
    #[ORM\Column(name: 'almacenamiento_gb', type: Types::SMALLINT)]
    #[Assert\NotNull(message: 'El almacenamiento es obligatorio')]
    #[Assert\Positive(message: 'El almacenamiento tiene que ser mayor que 0')]
    private ?int $almacenamientoGb = null;

    #[ORM\Column(length: 30)]
    #[Assert\NotBlank(message: 'El color es obligatorio')]
    private ?string $color = null;

    #[ORM\Column(length: 50, nullable: true)]
    #[Assert\Length(max: 50, maxMessage: 'La edición no puede tener más de 50 caracteres')]
    private ?string $edicion = null;

    public function getAlmacenamientoGb(): ?int { return $this->almacenamientoGb; }
    public function setAlmacenamientoGb(int $almacenamientoGb): static { $this->almacenamientoGb = $almacenamientoGb; return $this; }

    public function getColor(): ?string { return $this->color; }
    public function setColor(string $color): static { $this->color = $color; return $this; }

    public function getEdicion(): ?string { return $this->edicion; }
    public function setEdicion(?string $edicion): static { $this->edicion = $edicion; return $this; }

    public function getTipo(): string { return 'consola'; }
}
