<?php

namespace App\Entity;

use App\Repository\UsuarioRepository;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Bridge\Doctrine\Validator\Constraints\UniqueEntity;
use Symfony\Component\Security\Core\User\PasswordAuthenticatedUserInterface;
use Symfony\Component\Security\Core\User\UserInterface;
use Symfony\Component\Validator\Constraints as Assert;

#[ORM\Entity(repositoryClass: UsuarioRepository::class)]
#[ORM\Table(name: 'usuario')]
#[ORM\InheritanceType('JOINED')]
#[ORM\DiscriminatorColumn(name: 'tipo', type: 'string', length: 20)]
#[ORM\DiscriminatorMap(['cliente' => Cliente::class, 'trabajador' => Trabajador::class])]
#[UniqueEntity(fields: ['email'], message: 'Ya existe un usuario con este email')]
#[UniqueEntity(fields: ['dni'], message: 'Ya existe un usuario con este DNI')]
abstract class Usuario implements UserInterface, PasswordAuthenticatedUserInterface
{
    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column(name: 'id_usuario')]
    private ?int $id = null;

    #[ORM\Column(length: 50)]
    #[Assert\NotBlank(message: 'El nombre es obligatorio')]
    #[Assert\Length(max: 50, maxMessage: 'El nombre no puede tener más de 50 caracteres')]
    private ?string $nombre = null;

    #[ORM\Column(length: 50)]
    #[Assert\NotBlank(message: 'El primer apellido es obligatorio')]
    #[Assert\Length(max: 50, maxMessage: 'El apellido no puede tener más de 50 caracteres')]
    private ?string $apellido1 = null;

    #[ORM\Column(length: 50, nullable: true)]
    #[Assert\Length(max: 50, maxMessage: 'El apellido no puede tener más de 50 caracteres')]
    private ?string $apellido2 = null;

    #[ORM\Column(length: 9, unique: true)]
    #[Assert\NotBlank(message: 'El DNI es obligatorio')]
    #[Assert\Regex(pattern: '/^[0-9XYZ][0-9]{7}[A-Z]$/', message: 'El DNI no tiene un formato válido')]
    private ?string $dni = null;

    #[ORM\Column(length: 180, unique: true)]
    #[Assert\NotBlank(message: 'El email es obligatorio')]
    #[Assert\Email(message: 'El email no es válido')]
    private ?string $email = null;

    #[ORM\Column(name: 'password_hash', length: 255)]
    private ?string $password = null;

    #[ORM\Column(length: 15, nullable: true)]
    #[Assert\Regex(pattern: '/^\+?[0-9]{9,14}$/', message: 'El teléfono no es válido')]
    private ?string $telefono = null;

    #[ORM\Column(name: 'foto_perfil', length: 255, nullable: true)]
    private ?string $fotoPerfil = null;

    #[ORM\Column(options: ['default' => true])]
    private bool $activo = true;

    public function getId(): ?int { return $this->id; }

    public function getNombre(): ?string { return $this->nombre; }
    public function setNombre(string $nombre): static { $this->nombre = $nombre; return $this; }

    public function getApellido1(): ?string { return $this->apellido1; }
    public function setApellido1(string $apellido1): static { $this->apellido1 = $apellido1; return $this; }

    public function getApellido2(): ?string { return $this->apellido2; }
    public function setApellido2(?string $apellido2): static { $this->apellido2 = $apellido2; return $this; }

    public function getDni(): ?string { return $this->dni; }
    public function setDni(string $dni): static { $this->dni = strtoupper($dni); return $this; }

    public function getEmail(): ?string { return $this->email; }
    public function setEmail(string $email): static { $this->email = strtolower($email); return $this; }

    public function getPassword(): ?string { return $this->password; }
    public function setPassword(string $password): static { $this->password = $password; return $this; }

    public function getTelefono(): ?string { return $this->telefono; }
    public function setTelefono(?string $telefono): static { $this->telefono = $telefono; return $this; }

    public function getFotoPerfil(): ?string { return $this->fotoPerfil; }
    public function setFotoPerfil(?string $fotoPerfil): static { $this->fotoPerfil = $fotoPerfil; return $this; }

    public function isActivo(): bool { return $this->activo; }
    public function setActivo(bool $activo): static { $this->activo = $activo; return $this; }

    // --- Seguridad (login con JWT) ---

    public function getUserIdentifier(): string
    {
        return (string) $this->email;
    }

    /** Cada especialización define sus propios permisos */
    abstract public function getRoles(): array;

    #[\Deprecated]
    public function eraseCredentials(): void
    {
    }
}
