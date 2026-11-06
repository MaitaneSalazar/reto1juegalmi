<?php

namespace App\Entity;

use Doctrine\DBAL\Types\Types;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Validator\Constraints as Assert;

// TRABAJADOR N — pertenece — M DEPARTAMENTO (con fecha_inicio y fecha_fin)
#[ORM\Entity]
#[ORM\Table(name: 'trabajador_departamento')]
class TrabajadorDepartamento
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column(name: 'id_trabajador_departamento')]
    private ?int $id = null;

    #[ORM\Column(name: 'fecha_inicio', type: Types::DATE_IMMUTABLE)]
    #[Assert\NotNull(message: 'La fecha de inicio es obligatoria')]
    private ?\DateTimeImmutable $fechaInicio = null;

    #[ORM\Column(name: 'fecha_fin', type: Types::DATE_IMMUTABLE, nullable: true)]
    #[Assert\GreaterThanOrEqual(propertyPath: 'fechaInicio', message: 'La fecha de fin no puede ser anterior a la de inicio')]
    private ?\DateTimeImmutable $fechaFin = null;

    #[ORM\ManyToOne(targetEntity: Trabajador::class)]
    #[ORM\JoinColumn(name: 'id_trabajador', referencedColumnName: 'id_usuario', nullable: false, onDelete: 'CASCADE')]
    #[Assert\NotNull(message: 'Hay que indicar el trabajador')]
    private ?Trabajador $trabajador = null;

    #[ORM\ManyToOne(targetEntity: Departamento::class)]
    #[ORM\JoinColumn(name: 'id_departamento', referencedColumnName: 'id_departamento', nullable: false)]
    #[Assert\NotNull(message: 'Hay que indicar el departamento')]
    private ?Departamento $departamento = null;

    public function getId(): ?int { return $this->id; }

    public function getFechaInicio(): ?\DateTimeImmutable { return $this->fechaInicio; }
    public function setFechaInicio(\DateTimeImmutable $fechaInicio): static { $this->fechaInicio = $fechaInicio; return $this; }

    public function getFechaFin(): ?\DateTimeImmutable { return $this->fechaFin; }
    public function setFechaFin(?\DateTimeImmutable $fechaFin): static { $this->fechaFin = $fechaFin; return $this; }

    public function getTrabajador(): ?Trabajador { return $this->trabajador; }
    public function setTrabajador(Trabajador $trabajador): static { $this->trabajador = $trabajador; return $this; }

    public function getDepartamento(): ?Departamento { return $this->departamento; }
    public function setDepartamento(Departamento $departamento): static { $this->departamento = $departamento; return $this; }

    /** El trabajador sigue en el departamento mientras no haya fecha de fin */
    public function isActual(): bool
    {
        return $this->fechaFin === null;
    }
}
