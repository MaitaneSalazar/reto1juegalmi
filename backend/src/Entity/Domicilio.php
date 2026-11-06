<?php

namespace App\Entity;

use Doctrine\DBAL\Types\Types;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Validator\Constraints as Assert;

#[ORM\Entity]
#[ORM\Table(name: 'domicilio')]
class Domicilio
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column(name: 'id_domicilio')]
    private ?int $id = null;

    #[ORM\Column(name: 'fecha_alta', type: Types::DATE_IMMUTABLE)]
    private \DateTimeImmutable $fechaAlta;

    #[ORM\Column(name: 'fecha_baja', type: Types::DATE_IMMUTABLE, nullable: true)]
    #[Assert\GreaterThanOrEqual(propertyPath: 'fechaAlta', message: 'La fecha de baja no puede ser anterior a la de alta')]
    private ?\DateTimeImmutable $fechaBaja = null;

    // CLIENTE 1 — tiene — N DOMICILIO
    #[ORM\ManyToOne(targetEntity: Cliente::class)]
    #[ORM\JoinColumn(name: 'id_cliente', referencedColumnName: 'id_usuario', nullable: false, onDelete: 'CASCADE')]
    #[Assert\NotNull(message: 'El domicilio tiene que pertenecer a un cliente')]
    private ?Cliente $cliente = null;

    // DIRECCION 1 — corresponde a — N DOMICILIO
    #[ORM\ManyToOne(targetEntity: Direccion::class)]
    #[ORM\JoinColumn(name: 'id_direccion', referencedColumnName: 'id_direccion', nullable: false)]
    #[Assert\NotNull(message: 'El domicilio tiene que tener una dirección')]
    #[Assert\Valid]
    private ?Direccion $direccion = null;

    public function __construct()
    {
        $this->fechaAlta = new \DateTimeImmutable('today');
    }

    public function getId(): ?int { return $this->id; }

    public function getFechaAlta(): \DateTimeImmutable { return $this->fechaAlta; }
    public function setFechaAlta(\DateTimeImmutable $fechaAlta): static { $this->fechaAlta = $fechaAlta; return $this; }

    public function getFechaBaja(): ?\DateTimeImmutable { return $this->fechaBaja; }
    public function setFechaBaja(?\DateTimeImmutable $fechaBaja): static { $this->fechaBaja = $fechaBaja; return $this; }

    public function getCliente(): ?Cliente { return $this->cliente; }
    public function setCliente(Cliente $cliente): static { $this->cliente = $cliente; return $this; }

    public function getDireccion(): ?Direccion { return $this->direccion; }
    public function setDireccion(Direccion $direccion): static { $this->direccion = $direccion; return $this; }

    /** Un domicilio está activo mientras no tenga fecha de baja */
    public function isActivo(): bool
    {
        return $this->fechaBaja === null;
    }
}
