<?php

namespace App\Entity;

use Doctrine\DBAL\Types\Types;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Validator\Constraints as Assert;

#[ORM\Entity]
#[ORM\Table(name: 'departamento')]
class Departamento
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column(name: 'id_departamento')]
    private ?int $id = null;

    #[ORM\Column(length: 60)]
    #[Assert\NotBlank(message: 'El nombre es obligatorio')]
    #[Assert\Length(max: 60, maxMessage: 'El nombre no puede tener más de 60 caracteres')]
    private ?string $nombre = null;

    #[ORM\Column(type: Types::TEXT, nullable: true)]
    private ?string $descripcion = null;

    #[ORM\Column(length: 15, nullable: true)]
    #[Assert\Regex(pattern: '/^\+?[0-9]{9,14}$/', message: 'El teléfono no es válido')]
    private ?string $telefono = null;

    #[ORM\Column(options: ['default' => true])]
    private bool $activo = true;

    // TIENDA 1 — forma parte de — N DEPARTAMENTO
    #[ORM\ManyToOne(targetEntity: Tienda::class)]
    #[ORM\JoinColumn(name: 'id_tienda', referencedColumnName: 'id_tienda', nullable: false)]
    #[Assert\NotNull(message: 'El departamento tiene que pertenecer a una tienda')]
    private ?Tienda $tienda = null;

    public function getId(): ?int { return $this->id; }

    public function getNombre(): ?string { return $this->nombre; }
    public function setNombre(string $nombre): static { $this->nombre = $nombre; return $this; }

    public function getDescripcion(): ?string { return $this->descripcion; }
    public function setDescripcion(?string $descripcion): static { $this->descripcion = $descripcion; return $this; }

    public function getTelefono(): ?string { return $this->telefono; }
    public function setTelefono(?string $telefono): static { $this->telefono = $telefono; return $this; }

    public function isActivo(): bool { return $this->activo; }
    public function setActivo(bool $activo): static { $this->activo = $activo; return $this; }

    public function getTienda(): ?Tienda { return $this->tienda; }
    public function setTienda(Tienda $tienda): static { $this->tienda = $tienda; return $this; }

    public function __toString(): string { return (string) $this->nombre; }
}
