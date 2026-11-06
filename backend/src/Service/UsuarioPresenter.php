<?php

namespace App\Service;

use App\Entity\Cliente;
use App\Entity\Trabajador;
use App\Entity\Usuario;

/**
 * Datos de un usuario que devuelve la API (nunca la contraseña).
 */
class UsuarioPresenter
{
    /** Reutiliza las funciones que convierten una ruta en dirección completa y buscan la miniatura */
    public function __construct(private ProductoPresenter $imagenes)
    {
    }
    public function presentar(Usuario $usuario): array
    {
        $datos = [
            'id' => $usuario->getId(),
            'tipo' => $usuario instanceof Trabajador ? 'trabajador' : 'cliente',
            'nombre' => $usuario->getNombre(),
            'apellido1' => $usuario->getApellido1(),
            'apellido2' => $usuario->getApellido2(),
            'nombre_completo' => trim($usuario->getNombre() . ' ' . $usuario->getApellido1()),
            'iniciales' => mb_strtoupper(mb_substr((string) $usuario->getNombre(), 0, 1) . mb_substr((string) $usuario->getApellido1(), 0, 1)),
            'dni' => $usuario->getDni(),
            'email' => $usuario->getEmail(),
            'telefono' => $usuario->getTelefono(),
            'foto_perfil' => $usuario->getFotoPerfil(),
            'foto_perfil_url' => $this->imagenes->url($usuario->getFotoPerfil()),
            'foto_perfil_miniatura_url' => $this->imagenes->miniatura($usuario->getFotoPerfil()),
            'activo' => $usuario->isActivo(),
        ];

        if ($usuario instanceof Cliente) {
            $datos['fecha_registro'] = $usuario->getFechaRegistro()->format(DATE_ATOM);
        }

        if ($usuario instanceof Trabajador) {
            $datos['cargo'] = $usuario->getCargo();
            $datos['es_admin'] = $usuario->isEsAdmin();
            $datos['fecha_contratacion'] = $usuario->getFechaContratacion()?->format('Y-m-d');
        }

        return $datos;
    }
}
