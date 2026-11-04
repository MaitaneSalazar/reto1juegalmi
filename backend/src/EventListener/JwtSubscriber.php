<?php

namespace App\EventListener;

use App\Entity\Usuario;
use App\Service\RespuestaApi;
use App\Service\UsuarioPresenter;
use Lexik\Bundle\JWTAuthenticationBundle\Event\AuthenticationFailureEvent;
use Lexik\Bundle\JWTAuthenticationBundle\Event\AuthenticationSuccessEvent;
use Lexik\Bundle\JWTAuthenticationBundle\Event\JWTExpiredEvent;
use Lexik\Bundle\JWTAuthenticationBundle\Event\JWTInvalidEvent;
use Lexik\Bundle\JWTAuthenticationBundle\Event\JWTNotFoundEvent;
use Lexik\Bundle\JWTAuthenticationBundle\Events;
use Symfony\Component\EventDispatcher\EventSubscriberInterface;
use Symfony\Component\Security\Core\Exception\CustomUserMessageAccountStatusException;

/**
 * Adapta las respuestas del login y de los tokens al formato de nuestra API.
 */
class JwtSubscriber implements EventSubscriberInterface
{
    public function __construct(private UsuarioPresenter $presenter)
    {
    }

    public static function getSubscribedEvents(): array
    {
        return [
            Events::AUTHENTICATION_SUCCESS => 'alEntrar',
            Events::AUTHENTICATION_FAILURE => 'alFallarLogin',
            Events::JWT_NOT_FOUND => 'sinToken',
            Events::JWT_EXPIRED => 'tokenCaducado',
            Events::JWT_INVALID => 'tokenInvalido',
        ];
    }

    /** Login correcto: además del token, devuelve los datos del usuario */
    public function alEntrar(AuthenticationSuccessEvent $event): void
    {
        $usuario = $event->getUser();
        if (!$usuario instanceof Usuario) {
            return;
        }

        $datos = $event->getData();
        $datos['usuario'] = $this->presenter->presentar($usuario);
        $event->setData($datos);
    }

    public function alFallarLogin(AuthenticationFailureEvent $event): void
    {
        $error = $event->getException();
        $mensaje = $error instanceof CustomUserMessageAccountStatusException
            ? $error->getMessageKey()            // cuenta desactivada (UserChecker)
            : 'Email o contraseña incorrectos';

        $event->setResponse(RespuestaApi::error(401, $mensaje));
    }

    public function sinToken(JWTNotFoundEvent $event): void
    {
        $event->setResponse(RespuestaApi::error(401, 'Tienes que iniciar sesión'));
    }

    public function tokenCaducado(JWTExpiredEvent $event): void
    {
        $event->setResponse(RespuestaApi::error(401, 'La sesión ha caducado. Vuelve a iniciar sesión'));
    }

    public function tokenInvalido(JWTInvalidEvent $event): void
    {
        $event->setResponse(RespuestaApi::error(401, 'La sesión no es válida. Vuelve a iniciar sesión'));
    }
}
