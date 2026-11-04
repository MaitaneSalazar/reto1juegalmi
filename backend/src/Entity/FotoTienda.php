<?php

namespace App\Entity;

use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Validator\Constraints as Assert;

#[ORM\Entity]
#[ORM\Table(name: 'foto_tienda')]
class FotoTienda
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column(name: 'id_foto')]
    private ?int $id = null;

    #[ORM\Column(length: 255)]
    #[Assert\NotBlank(message: 'La ruta de la foto es obligatoria')]
    private ?string $ruta = null;

    #[ORM\Column(length: 100, nullable: true)]
    #[Assert\Length(max: 100, maxMessage: 'El título no puede tener más de 100 caracteres')]
    private ?string $titulo = null;

    // TIENDA 1 — muestra — N FOTO_TIENDA
    #[ORM\ManyToOne(targetEntity: Tienda::class)]
    #[ORM\JoinColumn(name: 'id_tienda', referencedColumnName: 'id_tienda', nullable: false, onDelete: 'CASCADE')]
    #[Assert\NotNull(message: 'La foto tiene que pertenecer a una tienda')]
    private ?Tienda $tienda = null;

    public function getId(): ?int { return $this->id; }

    public function getRuta(): ?string { return $this->ruta; }
    public function setRuta(string $ruta): static { $this->ruta = $ruta; return $this; }

    public function getTitulo(): ?string { return $this->titulo; }
    public function setTitulo(?string $titulo): static { $this->titulo = $titulo; return $this; }

    public function getTienda(): ?Tienda { return $this->tienda; }
    public function setTienda(Tienda $tienda): static { $this->tienda = $tienda; return $this; }
}
