<?php

namespace App\Entity;

use Doctrine\DBAL\Types\Types;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Validator\Constraints as Assert;

#[ORM\Entity]
#[ORM\Table(name: 'movil')]
class Movil extends Producto
{
    #[ORM\Column(name: 'pantalla_pulgadas', type: Types::DECIMAL, precision: 3, scale: 1)]
    #[Assert\NotNull(message: 'Las pulgadas de pantalla son obligatorias')]
    #[Assert\Positive(message: 'Las pulgadas tienen que ser mayores que 0')]
    private ?string $pantallaPulgadas = null;

    #[ORM\Column(name: 'ram_gb', type: Types::SMALLINT)]
    #[Assert\NotNull(message: 'La RAM es obligatoria')]
    #[Assert\Positive(message: 'La RAM tiene que ser mayor que 0')]
    private ?int $ramGb = null;

    #[ORM\Column(name: 'almacenamiento_gb', type: Types::SMALLINT)]
    #[Assert\NotNull(message: 'El almacenamiento es obligatorio')]
    #[Assert\Positive(message: 'El almacenamiento tiene que ser mayor que 0')]
    private ?int $almacenamientoGb = null;

    #[ORM\Column(name: 'sistema_operativo', length: 30)]
    #[Assert\NotBlank(message: 'El sistema operativo es obligatorio')]
    private ?string $sistemaOperativo = null;

    #[ORM\Column(name: 'bateria_mah')]
    #[Assert\NotNull(message: 'La batería es obligatoria')]
    #[Assert\Positive(message: 'La batería tiene que ser mayor que 0')]
    private ?int $bateriaMah = null;

    public function getPantallaPulgadas(): ?float { return $this->pantallaPulgadas === null ? null : (float) $this->pantallaPulgadas; }
    public function setPantallaPulgadas(float $pulgadas): static { $this->pantallaPulgadas = (string) $pulgadas; return $this; }

    public function getRamGb(): ?int { return $this->ramGb; }
    public function setRamGb(int $ramGb): static { $this->ramGb = $ramGb; return $this; }

    public function getAlmacenamientoGb(): ?int { return $this->almacenamientoGb; }
    public function setAlmacenamientoGb(int $almacenamientoGb): static { $this->almacenamientoGb = $almacenamientoGb; return $this; }

    public function getSistemaOperativo(): ?string { return $this->sistemaOperativo; }
    public function setSistemaOperativo(string $sistemaOperativo): static { $this->sistemaOperativo = $sistemaOperativo; return $this; }

    public function getBateriaMah(): ?int { return $this->bateriaMah; }
    public function setBateriaMah(int $bateriaMah): static { $this->bateriaMah = $bateriaMah; return $this; }

    public function getTipo(): string { return 'movil'; }
}
