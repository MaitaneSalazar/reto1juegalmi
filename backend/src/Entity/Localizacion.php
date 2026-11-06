<?php

namespace App\Entity;

use Doctrine\DBAL\Types\Types;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Validator\Constraints as Assert;

#[ORM\Entity]
#[ORM\Table(name: 'localizacion')]
#[ORM\Index(name: 'idx_localizacion_fecha', columns: ['fecha_hora'])]
class Localizacion
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column(name: 'id_localizacion')]
    private ?int $id = null;

    #[ORM\Column(type: Types::DECIMAL, precision: 9, scale: 6)]
    #[Assert\NotNull(message: 'La latitud es obligatoria')]
    #[Assert\Range(min: -90, max: 90, notInRangeMessage: 'La latitud tiene que estar entre -90 y 90')]
    private ?string $latitud = null;

    #[ORM\Column(type: Types::DECIMAL, precision: 9, scale: 6)]
    #[Assert\NotNull(message: 'La longitud es obligatoria')]
    #[Assert\Range(min: -180, max: 180, notInRangeMessage: 'La longitud tiene que estar entre -180 y 180')]
    private ?string $longitud = null;

    #[ORM\Column(name: 'fecha_hora')]
    private \DateTimeImmutable $fechaHora;

    // CLIENTE 1 — registra — N LOCALIZACION
    #[ORM\ManyToOne(targetEntity: Cliente::class)]
    #[ORM\JoinColumn(name: 'id_cliente', referencedColumnName: 'id_usuario', nullable: false, onDelete: 'CASCADE')]
    #[Assert\NotNull(message: 'La localización tiene que pertenecer a un cliente')]
    private ?Cliente $cliente = null;

    public function __construct()
    {
        $this->fechaHora = new \DateTimeImmutable();
    }

    public function getId(): ?int { return $this->id; }

    public function getLatitud(): ?float { return $this->latitud === null ? null : (float) $this->latitud; }
    public function setLatitud(float $latitud): static { $this->latitud = (string) $latitud; return $this; }

    public function getLongitud(): ?float { return $this->longitud === null ? null : (float) $this->longitud; }
    public function setLongitud(float $longitud): static { $this->longitud = (string) $longitud; return $this; }

    public function getFechaHora(): \DateTimeImmutable { return $this->fechaHora; }
    public function setFechaHora(\DateTimeImmutable $fechaHora): static { $this->fechaHora = $fechaHora; return $this; }

    public function getCliente(): ?Cliente { return $this->cliente; }
    public function setCliente(Cliente $cliente): static { $this->cliente = $cliente; return $this; }
}
