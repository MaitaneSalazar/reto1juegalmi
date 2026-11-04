<?php

namespace App\Entity;

use Doctrine\DBAL\Types\Types;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Validator\Constraints as Assert;

#[ORM\Entity]
#[ORM\Table(name: 'historial_estado')]
class HistorialEstado
{
    public const ESTADOS = ['recibida', 'diagnostico', 'en_reparacion', 'lista_para_recoger', 'entregada', 'cancelada'];

    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column(name: 'id_historial')]
    private ?int $id = null;

    #[ORM\Column(length: 20)]
    #[Assert\NotBlank(message: 'El estado es obligatorio')]
    #[Assert\Choice(choices: self::ESTADOS, message: 'El estado no es válido')]
    private ?string $estado = null;

    #[ORM\Column(name: 'fecha_hora')]
    private \DateTimeImmutable $fechaHora;

    #[ORM\Column(type: Types::TEXT, nullable: true)]
    private ?string $descripcion = null;

    // REPARACION 1 — pasa por — N HISTORIAL_ESTADO
    #[ORM\ManyToOne(targetEntity: Reparacion::class, inversedBy: 'historial')]
    #[ORM\JoinColumn(name: 'id_reparacion', referencedColumnName: 'id_reparacion', nullable: false, onDelete: 'CASCADE')]
    private ?Reparacion $reparacion = null;

    public function __construct()
    {
        $this->fechaHora = new \DateTimeImmutable();
    }

    public function getId(): ?int { return $this->id; }

    public function getEstado(): ?string { return $this->estado; }
    public function setEstado(string $estado): static { $this->estado = $estado; return $this; }

    public function getFechaHora(): \DateTimeImmutable { return $this->fechaHora; }
    public function setFechaHora(\DateTimeImmutable $fechaHora): static { $this->fechaHora = $fechaHora; return $this; }

    public function getDescripcion(): ?string { return $this->descripcion; }
    public function setDescripcion(?string $descripcion): static { $this->descripcion = $descripcion; return $this; }

    public function getReparacion(): ?Reparacion { return $this->reparacion; }
    public function setReparacion(?Reparacion $reparacion): static { $this->reparacion = $reparacion; return $this; }
}
