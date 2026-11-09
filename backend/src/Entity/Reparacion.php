<?php

namespace App\Entity;

use Doctrine\Common\Collections\ArrayCollection;
use Doctrine\Common\Collections\Collection;
use Doctrine\DBAL\Types\Types;
use Doctrine\ORM\Mapping as ORM;
use Symfony\Component\Validator\Constraints as Assert;

#[ORM\Entity]
#[ORM\Table(name: 'reparacion')]
class Reparacion
{
    public const TIPOS_DISPOSITIVO = ['consola', 'movil', 'tablet', 'ordenador', 'mando', 'auriculares', 'reloj', 'otro'];

    #[ORM\Id]
    #[ORM\GeneratedValue]
    #[ORM\Column(name: 'id_reparacion')]
    private ?int $id = null;

    #[ORM\Column(name: 'tipo_dispositivo', length: 20)]
    #[Assert\NotBlank(message: 'El tipo de dispositivo es obligatorio')]
    #[Assert\Choice(choices: self::TIPOS_DISPOSITIVO, message: 'El tipo de dispositivo no es válido')]
    private ?string $tipoDispositivo = null;

    #[ORM\Column(length: 50)]
    #[Assert\NotBlank(message: 'La marca es obligatoria')]
    #[Assert\Length(max: 50, maxMessage: 'La marca no puede tener más de 50 caracteres')]
    private ?string $marca = null;

    #[ORM\Column(length: 100)]
    #[Assert\NotBlank(message: 'El modelo es obligatorio')]
    #[Assert\Length(max: 100, maxMessage: 'El modelo no puede tener más de 100 caracteres')]
    private ?string $modelo = null;

    // Lo rellena el trabajador tras el diagnóstico
    #[ORM\Column(length: 100, nullable: true)]
    #[Assert\Length(max: 100, maxMessage: 'El componente no puede tener más de 100 caracteres')]
    private ?string $componente = null;

    #[ORM\Column(name: 'descripcion_averia', type: Types::TEXT)]
    #[Assert\NotBlank(message: 'Describe la avería')]
    private ?string $descripcionAveria = null;

    // Lo rellena el trabajador tras el diagnóstico
    #[ORM\Column(type: Types::DECIMAL, precision: 8, scale: 2, nullable: true)]
    #[Assert\PositiveOrZero(message: 'El presupuesto no puede ser negativo')]
    private ?string $presupuesto = null;

    /** Notas del taller: solo las ve el equipo, nunca el cliente */
    #[ORM\Column(name: 'notas_internas', type: 'text', nullable: true)]
    private ?string $notasInternas = null;

    /** null = pendiente de respuesta · true = aceptado · false = rechazado */
    #[ORM\Column(name: 'presupuesto_aceptado', nullable: true)]
    private ?bool $presupuestoAceptado = null;

    /** Última vez que la tienda avisó al cliente */
    #[ORM\Column(name: 'avisado_en', nullable: true)]
    private ?\DateTimeImmutable $avisadoEn = null;

    // CLIENTE 1 — solicita — N REPARACION
    #[ORM\ManyToOne(targetEntity: Cliente::class)]
    #[ORM\JoinColumn(name: 'id_cliente', referencedColumnName: 'id_usuario', nullable: false)]
    #[Assert\NotNull(message: 'La reparación tiene que pertenecer a un cliente')]
    private ?Cliente $cliente = null;

    /** @var Collection<int, HistorialEstado> */
    #[ORM\OneToMany(targetEntity: HistorialEstado::class, mappedBy: 'reparacion', cascade: ['persist'], orphanRemoval: true)]
    #[ORM\OrderBy(['fechaHora' => 'ASC', 'id' => 'ASC'])]
    private Collection $historial;

    /** @var Collection<int, FotoReparacion> */
    #[ORM\OneToMany(targetEntity: FotoReparacion::class, mappedBy: 'reparacion', cascade: ['persist'], orphanRemoval: true)]
    private Collection $fotos;

    /** @var Collection<int, TrabajadorReparacion> */
    #[ORM\OneToMany(targetEntity: TrabajadorReparacion::class, mappedBy: 'reparacion', cascade: ['persist'], orphanRemoval: true)]
    private Collection $asignaciones;

    public function __construct()
    {
        $this->historial = new ArrayCollection();
        $this->fotos = new ArrayCollection();
        $this->asignaciones = new ArrayCollection();

        // Toda reparación empieza con el estado «recibida»
        $this->cambiarEstado('recibida', 'Solicitud de reparación recibida');
    }

    public function getId(): ?int { return $this->id; }

    public function getTipoDispositivo(): ?string { return $this->tipoDispositivo; }
    public function setTipoDispositivo(string $tipo): static { $this->tipoDispositivo = strtolower($tipo); return $this; }

    public function getMarca(): ?string { return $this->marca; }
    public function setMarca(string $marca): static { $this->marca = $marca; return $this; }

    public function getModelo(): ?string { return $this->modelo; }
    public function setModelo(string $modelo): static { $this->modelo = $modelo; return $this; }

    public function getComponente(): ?string { return $this->componente; }
    public function setComponente(?string $componente): static { $this->componente = $componente; return $this; }

    public function getDescripcionAveria(): ?string { return $this->descripcionAveria; }
    public function setDescripcionAveria(string $descripcion): static { $this->descripcionAveria = $descripcion; return $this; }

    public function getPresupuesto(): ?float { return $this->presupuesto === null ? null : (float) $this->presupuesto; }
    public function setPresupuesto(?float $presupuesto): static { $this->presupuesto = $presupuesto === null ? null : number_format($presupuesto, 2, '.', ''); return $this; }

    public function getCliente(): ?Cliente { return $this->cliente; }
    public function setCliente(Cliente $cliente): static { $this->cliente = $cliente; return $this; }

    /** @return Collection<int, HistorialEstado> */
    public function getHistorial(): Collection { return $this->historial; }

    /** Añade una entrada al historial; es la única forma de cambiar el estado */
    public function cambiarEstado(string $estado, ?string $descripcion = null): static
    {
        $entrada = (new HistorialEstado())
            ->setEstado($estado)
            ->setDescripcion($descripcion)
            ->setReparacion($this);
        $this->historial->add($entrada);

        return $this;
    }

    /** Estado actual: el último del historial (calculado, no se guarda) */
    public function getEstadoActual(): string
    {
        $ultimo = $this->historial->last();

        return $ultimo ? $ultimo->getEstado() : 'recibida';
    }

    /** @return Collection<int, FotoReparacion> */
    public function getFotos(): Collection { return $this->fotos; }

    public function addFoto(FotoReparacion $foto): static
    {
        if (!$this->fotos->contains($foto)) {
            $this->fotos->add($foto);
            $foto->setReparacion($this);
        }

        return $this;
    }

    public function removeFoto(FotoReparacion $foto): static
    {
        $this->fotos->removeElement($foto);

        return $this;
    }

    /** @return Collection<int, TrabajadorReparacion> */
    public function getAsignaciones(): Collection { return $this->asignaciones; }

    public function addAsignacion(TrabajadorReparacion $asignacion): static
    {
        if (!$this->asignaciones->contains($asignacion)) {
            $this->asignaciones->add($asignacion);
            $asignacion->setReparacion($this);
        }

        return $this;
    }

    /** Trabajador que la tiene ahora (asignación sin fecha de fin) */
    public function getTrabajadorActual(): ?Trabajador
    {
        foreach ($this->asignaciones as $asignacion) {
            if ($asignacion->getFechaFin() === null) {
                return $asignacion->getTrabajador();
            }
        }

        return null;
    }

    public function getNotasInternas(): ?string { return $this->notasInternas; }
    public function setNotasInternas(?string $notas): static { $this->notasInternas = $notas; return $this; }

    public function getPresupuestoAceptado(): ?bool { return $this->presupuestoAceptado; }
    public function setPresupuestoAceptado(?bool $aceptado): static { $this->presupuestoAceptado = $aceptado; return $this; }

    public function getAvisadoEn(): ?\DateTimeImmutable { return $this->avisadoEn; }
    public function setAvisadoEn(?\DateTimeImmutable $fecha): static { $this->avisadoEn = $fecha; return $this; }

    public function getNombreTrabajadorActual(): string
    {
        $t = $this->getTrabajadorActual();
        return $t === null ? 'Sin asignar' : trim($t->getNombre() . ' ' . $t->getApellido1());
    }

    /** Fecha del primer estado («recibida»): cuándo entró en la tienda */
    public function getFechaRecepcion(): ?\DateTimeImmutable
    {
        $primera = null;
        foreach ($this->historial as $h) {
            if ($primera === null || $h->getFechaHora() < $primera) {
                $primera = $h->getFechaHora();
            }
        }
        return $primera;
    }

    public function __toString(): string { return sprintf('Reparación #%d (%s %s)', $this->id, $this->marca, $this->modelo); }
}
