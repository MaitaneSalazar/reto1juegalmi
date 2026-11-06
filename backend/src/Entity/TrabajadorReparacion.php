<?php

namespace App\Entity;

use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Validator\Constraints as Assert;

// TRABAJADOR N — repara — M REPARACION (con fecha_inicio y fecha_fin)
#[ORM\Entity]
#[ORM\Table(name: 'trabajador_reparacion')]
class TrabajadorReparacion
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column(name: 'id_trabajador_reparacion')]
    private ?int $id = null;

    #[ORM\Column(name: 'fecha_inicio')]
    private \DateTimeImmutable $fechaInicio;

    #[ORM\Column(name: 'fecha_fin', nullable: true)]
    #[Assert\GreaterThanOrEqual(propertyPath: 'fechaInicio', message: 'La fecha de fin no puede ser anterior a la de inicio')]
    private ?\DateTimeImmutable $fechaFin = null;

    #[ORM\ManyToOne(targetEntity: Trabajador::class)]
    #[ORM\JoinColumn(name: 'id_trabajador', referencedColumnName: 'id_usuario', nullable: false)]
    #[Assert\NotNull(message: 'Hay que indicar el trabajador')]
    private ?Trabajador $trabajador = null;

    #[ORM\ManyToOne(targetEntity: Reparacion::class, inversedBy: 'asignaciones')]
    #[ORM\JoinColumn(name: 'id_reparacion', referencedColumnName: 'id_reparacion', nullable: false, onDelete: 'CASCADE')]
    private ?Reparacion $reparacion = null;

    public function __construct()
    {
        $this->fechaInicio = new \DateTimeImmutable();
    }

    public function getId(): ?int { return $this->id; }

    public function getFechaInicio(): \DateTimeImmutable { return $this->fechaInicio; }
    public function setFechaInicio(\DateTimeImmutable $fechaInicio): static { $this->fechaInicio = $fechaInicio; return $this; }

    public function getFechaFin(): ?\DateTimeImmutable { return $this->fechaFin; }
    public function setFechaFin(?\DateTimeImmutable $fechaFin): static { $this->fechaFin = $fechaFin; return $this; }

    public function getTrabajador(): ?Trabajador { return $this->trabajador; }
    public function setTrabajador(Trabajador $trabajador): static { $this->trabajador = $trabajador; return $this; }

    public function getReparacion(): ?Reparacion { return $this->reparacion; }
    public function setReparacion(?Reparacion $reparacion): static { $this->reparacion = $reparacion; return $this; }
}
