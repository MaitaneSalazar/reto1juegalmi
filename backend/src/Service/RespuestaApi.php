<?php

namespace App\Service;

use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpKernel\Exception\BadRequestHttpException;
use Symfony\Component\Validator\ConstraintViolationListInterface;

/**
 * Utilidades comunes de la API: leer el JSON de la petición y devolver errores
 * siempre con el mismo formato: {error, codigo, mensaje, campos}.
 */
class RespuestaApi
{
    /** Lee el cuerpo JSON de la petición. Si no es un JSON válido, responde 400. */
    public static function leerJson(Request $request): array
    {
        $contenido = trim($request->getContent());
        if ($contenido === '') {
            return [];
        }

        try {
            $datos = json_decode($contenido, true, 512, JSON_THROW_ON_ERROR);
        } catch (\JsonException) {
            throw new BadRequestHttpException('El cuerpo de la petición no es un JSON válido');
        }

        if (!is_array($datos)) {
            throw new BadRequestHttpException('El cuerpo de la petición tiene que ser un objeto JSON');
        }

        return $datos;
    }

    /** Convierte los errores del validador en ['campo' => 'mensaje'] (un mensaje por campo) */
    public static function camposConError(ConstraintViolationListInterface $errores): array
    {
        $campos = [];
        foreach ($errores as $error) {
            $campo = self::aSnakeCase($error->getPropertyPath());
            $campos[$campo] ??= $error->getMessage();
        }

        return $campos;
    }

    /**
     * 422 con los errores de cada campo. En «mensaje» van los motivos concretos
     * (p. ej. «Ya existe un usuario con este DNI») para que las apps solo tengan que mostrarlo.
     */
    public static function errorValidacion(array $campos): JsonResponse
    {
        $motivos = array_unique(array_filter(array_values($campos), 'is_string'));
        $mensaje = $motivos === [] ? 'Los datos enviados no son válidos' : implode('. ', $motivos);

        return self::error(422, $mensaje, $campos);
    }

    public static function error(int $codigo, string $mensaje, array $campos = []): JsonResponse
    {
        $datos = ['error' => true, 'codigo' => $codigo, 'mensaje' => $mensaje];
        if ($campos !== []) {
            $datos['campos'] = $campos;
        }

        return new JsonResponse($datos, $codigo);
    }

    /** fotoPerfil -> foto_perfil (los campos del JSON van en snake_case, como en el E-R) */
    private static function aSnakeCase(string $texto): string
    {
        return strtolower(preg_replace('/(?<!^)[A-Z]/', '_$0', $texto));
    }
    /** Lee ?page= y ?limit= (por defecto 20, máximo 50). Devuelve [pagina, porPagina]. */
    public static function paginacion(Request $request): array
    {
        $pagina = max(1, $request->query->getInt('page', 1));
        $porPagina = min(50, max(1, $request->query->getInt('limit', 20)));

        return [$pagina, $porPagina];
    }

    /** Respuesta de un listado: {datos, paginacion} */
    public static function listado(array $datos, int $total, int $pagina, int $porPagina): JsonResponse
    {
        return new JsonResponse([
            'datos' => $datos,
            'paginacion' => [
                'pagina' => $pagina,
                'por_pagina' => $porPagina,
                'total' => $total,
                'paginas' => (int) ceil($total / $porPagina),
            ],
        ]);
    }
}
