<?php

namespace App\Entity;

use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Validator\Constraints as Assert;

#[ORM\Entity]
#[ORM\Table(name: 'direccion')]
class Direccion
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column(name: 'id_direccion')]
    private ?int $id = null;

    #[ORM\Column(length: 100)]
    #[Assert\NotBlank(message: 'La calle es obligatoria')]
    #[Assert\Length(max: 100, maxMessage: 'La calle no puede tener más de 100 caracteres')]
    private ?string $calle = null;

    #[ORM\Column(length: 10)]
    #[Assert\NotBlank(message: 'El número es obligatorio')]
    #[Assert\Length(max: 10, maxMessage: 'El número no puede tener más de 10 caracteres')]
    private ?string $numero = null;

    #[ORM\Column(length: 20, nullable: true)]
    #[Assert\Length(max: 20, maxMessage: 'El piso no puede tener más de 20 caracteres')]
    private ?string $piso = null;

    #[ORM\Column(name: 'codigo_postal', length: 5)]
    #[Assert\NotBlank(message: 'El código postal es obligatorio')]
    #[Assert\Regex(pattern: '/^[0-9]{5}$/', message: 'El código postal tiene que tener 5 números')]
    private ?string $codigoPostal = null;

    #[ORM\Column(length: 60)]
    #[Assert\NotBlank(message: 'La ciudad es obligatoria')]
    #[Assert\Length(max: 60, maxMessage: 'La ciudad no puede tener más de 60 caracteres')]
    private ?string $ciudad = null;

    #[ORM\Column(length: 60)]
    #[Assert\NotBlank(message: 'La provincia es obligatoria')]
    #[Assert\Length(max: 60, maxMessage: 'La provincia no puede tener más de 60 caracteres')]
    private ?string $provincia = null;

    public function getId(): ?int { return $this->id; }

    public function getCalle(): ?string { return $this->calle; }
    public function setCalle(string $calle): static { $this->calle = $calle; return $this; }

    public function getNumero(): ?string { return $this->numero; }
    public function setNumero(string $numero): static { $this->numero = $numero; return $this; }

    public function getPiso(): ?string { return $this->piso; }
    public function setPiso(?string $piso): static { $this->piso = $piso; return $this; }

    public function getCodigoPostal(): ?string { return $this->codigoPostal; }
    public function setCodigoPostal(string $codigoPostal): static { $this->codigoPostal = $codigoPostal; return $this; }

    public function getCiudad(): ?string { return $this->ciudad; }
    public function setCiudad(string $ciudad): static { $this->ciudad = $ciudad; return $this; }

    public function getProvincia(): ?string { return $this->provincia; }
    public function setProvincia(string $provincia): static { $this->provincia = $provincia; return $this; }

    public function __toString(): string
    {
        return trim(sprintf('%s %s %s, %s %s', $this->calle, $this->numero, $this->piso ?? '', $this->codigoPostal, $this->ciudad));
    }
}
