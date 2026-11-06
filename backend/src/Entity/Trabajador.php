<?php

namespace App\Entity;

use Doctrine\DBAL\Types\Types;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Validator\Constraints as Assert;

#[ORM\Entity]
#[ORM\Table(name: 'trabajador')]
class Trabajador extends Usuario
{
    #[ORM\Column(length: 50)]
    #[Assert\NotBlank(message: 'El cargo es obligatorio')]
    #[Assert\Length(max: 50, maxMessage: 'El cargo no puede tener más de 50 caracteres')]
    private ?string $cargo = null;

    #[ORM\Column(name: 'es_admin', options: ['default' => false])]
    private bool $esAdmin = false;

    #[ORM\Column(name: 'fecha_contratacion', type: Types::DATE_IMMUTABLE)]
    #[Assert\NotNull(message: 'La fecha de contratación es obligatoria')]
    private ?\DateTimeImmutable $fechaContratacion = null;


    /* Solo para el formulario de la web: no tienen columna en la base de datos */
    private ?string $contrasenaNueva = null;
    private ?Departamento $departamentoNuevo = null;

    public function getContrasenaNueva(): ?string { return $this->contrasenaNueva; }
    public function setContrasenaNueva(?string $contrasena): static { $this->contrasenaNueva = $contrasena; return $this; }

    public function getDepartamentoNuevo(): ?Departamento { return $this->departamentoNuevo; }
    public function setDepartamentoNuevo(?Departamento $departamento): static { $this->departamentoNuevo = $departamento; return $this; }

    public function getCargo(): ?string { return $this->cargo; }
    public function setCargo(string $cargo): static { $this->cargo = $cargo; return $this; }

    public function isEsAdmin(): bool { return $this->esAdmin; }
    public function setEsAdmin(bool $esAdmin): static { $this->esAdmin = $esAdmin; return $this; }

    public function getFechaContratacion(): ?\DateTimeImmutable { return $this->fechaContratacion; }
    public function setFechaContratacion(\DateTimeImmutable $fechaContratacion): static { $this->fechaContratacion = $fechaContratacion; return $this; }

    public function getRoles(): array
    {
        $roles = ['ROLE_USER', 'ROLE_TRABAJADOR'];
        if ($this->esAdmin) {
            $roles[] = 'ROLE_ADMIN';
        }

        return $roles;
    }
}
