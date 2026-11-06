<?php

namespace App\Entity;

use Doctrine\DBAL\Types\Types;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Validator\Constraints as Assert;

#[ORM\Entity]
#[ORM\Table(name: 'tablet')]
class Tablet extends Producto
{
    public const CONECTIVIDADES = ['wifi', '4g', '5g'];

    #[ORM\Column(name: 'pantalla_pulgadas', type: Types::DECIMAL, precision: 3, scale: 1)]
    #[Assert\NotNull(message: 'Las pulgadas de pantalla son obligatorias')]
    #[Assert\Positive(message: 'Las pulgadas tienen que ser mayores que 0')]
    private ?string $pantallaPulgadas = null;

    #[ORM\Column(name: 'almacenamiento_gb', type: Types::SMALLINT)]
    #[Assert\NotNull(message: 'El almacenamiento es obligatorio')]
    #[Assert\Positive(message: 'El almacenamiento tiene que ser mayor que 0')]
    private ?int $almacenamientoGb = null;

    #[ORM\Column(name: 'sistema_operativo', length: 30)]
    #[Assert\NotBlank(message: 'El sistema operativo es obligatorio')]
    private ?string $sistemaOperativo = null;

    #[ORM\Column(length: 10)]
    #[Assert\Choice(choices: self::CONECTIVIDADES, message: 'La conectividad tiene que ser wifi, 4g o 5g')]
    private string $conectividad = 'wifi';

    public function getPantallaPulgadas(): ?float { return $this->pantallaPulgadas === null ? null : (float) $this->pantallaPulgadas; }
    public function setPantallaPulgadas(float $pulgadas): static { $this->pantallaPulgadas = (string) $pulgadas; return $this; }

    public function getAlmacenamientoGb(): ?int { return $this->almacenamientoGb; }
    public function setAlmacenamientoGb(int $almacenamientoGb): static { $this->almacenamientoGb = $almacenamientoGb; return $this; }

    public function getSistemaOperativo(): ?string { return $this->sistemaOperativo; }
    public function setSistemaOperativo(string $sistemaOperativo): static { $this->sistemaOperativo = $sistemaOperativo; return $this; }

    public function getConectividad(): string { return $this->conectividad; }
    public function setConectividad(string $conectividad): static { $this->conectividad = strtolower($conectividad); return $this; }

    public function getTipo(): string { return 'tablet'; }
}
