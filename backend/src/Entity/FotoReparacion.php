<?php

namespace App\Entity;

use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Validator\Constraints as Assert;

#[ORM\Entity]
#[ORM\Table(name: 'foto_reparacion')]
class FotoReparacion
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column(name: 'id_foto')]
    private ?int $id = null;

    #[ORM\Column(length: 255)]
    #[Assert\NotBlank(message: 'La ruta de la foto es obligatoria')]
    private ?string $ruta = null;

    #[ORM\Column(name: 'fecha_subida')]
    private \DateTimeImmutable $fechaSubida;

    // REPARACION 1 — adjunta — N FOTO_REPARACION
    #[ORM\ManyToOne(targetEntity: Reparacion::class, inversedBy: 'fotos')]
    #[ORM\JoinColumn(name: 'id_reparacion', referencedColumnName: 'id_reparacion', nullable: false, onDelete: 'CASCADE')]
    private ?Reparacion $reparacion = null;

    public function __construct()
    {
        $this->fechaSubida = new \DateTimeImmutable();
    }

    public function getId(): ?int { return $this->id; }

    public function getRuta(): ?string { return $this->ruta; }
    public function setRuta(string $ruta): static { $this->ruta = $ruta; return $this; }

    public function getFechaSubida(): \DateTimeImmutable { return $this->fechaSubida; }
    public function setFechaSubida(\DateTimeImmutable $fechaSubida): static { $this->fechaSubida = $fechaSubida; return $this; }

    public function getReparacion(): ?Reparacion { return $this->reparacion; }
    public function setReparacion(?Reparacion $reparacion): static { $this->reparacion = $reparacion; return $this; }
}
