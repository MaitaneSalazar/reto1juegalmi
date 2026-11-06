<?php

namespace App\Entity;

use Doctrine\ORM\Mapping as ORM;

#[ORM\Entity]
#[ORM\Table(name: 'cliente')]
class Cliente extends Usuario
{
    #[ORM\Column(name: 'fecha_registro')]
    private \DateTimeImmutable $fechaRegistro;

    public function __construct()
    {
        $this->fechaRegistro = new \DateTimeImmutable();
    }

    public function getFechaRegistro(): \DateTimeImmutable { return $this->fechaRegistro; }
    public function setFechaRegistro(\DateTimeImmutable $fechaRegistro): static { $this->fechaRegistro = $fechaRegistro; return $this; }

    public function getRoles(): array
    {
        return ['ROLE_USER', 'ROLE_CLIENTE'];
    }
}
