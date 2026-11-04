<?php

namespace App\Entity;

use Doctrine\DBAL\Types\Types;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Validator\Constraints as Assert;

#[ORM\Entity]
#[ORM\Table(name: 'tienda')]
class Tienda
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column(name: 'id_tienda')]
    private ?int $id = null;

    #[ORM\Column(length: 100)]
    #[Assert\NotBlank(message: 'El nombre es obligatorio')]
    #[Assert\Length(max: 100, maxMessage: 'El nombre no puede tener más de 100 caracteres')]
    private ?string $nombre = null;

    #[ORM\Column(length: 15)]
    #[Assert\NotBlank(message: 'El teléfono es obligatorio')]
    #[Assert\Regex(pattern: '/^\+?[0-9]{9,14}$/', message: 'El teléfono no es válido')]
    private ?string $telefono = null;

    #[ORM\Column(length: 180)]
    #[Assert\NotBlank(message: 'El email es obligatorio')]
    #[Assert\Email(message: 'El email no es válido')]
    private ?string $email = null;

    #[ORM\Column(type: Types::DECIMAL, precision: 9, scale: 6)]
    #[Assert\NotNull(message: 'La latitud es obligatoria')]
    #[Assert\Range(min: -90, max: 90, notInRangeMessage: 'La latitud tiene que estar entre -90 y 90')]
    private ?string $latitud = null;

    #[ORM\Column(type: Types::DECIMAL, precision: 9, scale: 6)]
    #[Assert\NotNull(message: 'La longitud es obligatoria')]
    #[Assert\Range(min: -180, max: 180, notInRangeMessage: 'La longitud tiene que estar entre -180 y 180')]
    private ?string $longitud = null;

    // Añadido respecto al relacional: texto de la opción «Historia» de las apps y la web
    #[ORM\Column(type: Types::TEXT, nullable: true)]
    private ?string $historia = null;

    // TIENDA N — situada en — 1 DIRECCION
    #[ORM\ManyToOne(targetEntity: Direccion::class)]
    #[ORM\JoinColumn(name: 'id_direccion', referencedColumnName: 'id_direccion', nullable: false)]
    #[Assert\NotNull(message: 'La tienda tiene que tener una dirección')]
    #[Assert\Valid]
    private ?Direccion $direccion = null;

    public function getId(): ?int { return $this->id; }

    public function getNombre(): ?string { return $this->nombre; }
    public function setNombre(string $nombre): static { $this->nombre = $nombre; return $this; }

    public function getTelefono(): ?string { return $this->telefono; }
    public function setTelefono(string $telefono): static { $this->telefono = $telefono; return $this; }

    public function getEmail(): ?string { return $this->email; }
    public function setEmail(string $email): static { $this->email = strtolower($email); return $this; }

    public function getLatitud(): ?float { return $this->latitud === null ? null : (float) $this->latitud; }
    public function setLatitud(float $latitud): static { $this->latitud = (string) $latitud; return $this; }

    public function getLongitud(): ?float { return $this->longitud === null ? null : (float) $this->longitud; }
    public function setLongitud(float $longitud): static { $this->longitud = (string) $longitud; return $this; }

    public function getHistoria(): ?string { return $this->historia; }
    public function setHistoria(?string $historia): static { $this->historia = $historia; return $this; }

    public function getDireccion(): ?Direccion { return $this->direccion; }
    public function setDireccion(Direccion $direccion): static { $this->direccion = $direccion; return $this; }

    public function __toString(): string { return (string) $this->nombre; }
}
