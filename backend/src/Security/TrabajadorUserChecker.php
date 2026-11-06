<?php

namespace App\Security;

use App\Entity\Trabajador;
use Symfony\Component\Security\Core\Authentication\Token\TokenInterface;
use Symfony\Component\Security\Core\Exception\CustomUserMessageAccountStatusException;
use Symfony\Component\Security\Core\User\UserCheckerInterface;
use Symfony\Component\Security\Core\User\UserInterface;

/**
 * Comprobador del login de la WEB: además de lo del UserChecker general
 * (cuenta desactivada), solo deja entrar a trabajadores.
 */
class TrabajadorUserChecker implements UserCheckerInterface
{
    public function __construct(private UserChecker $general)
    {
    }

    public function checkPreAuth(UserInterface $user): void
    {
        $this->general->checkPreAuth($user);
    }

    /** Se ejecuta después de comprobar la contraseña: no revela qué emails existen */
    public function checkPostAuth(UserInterface $user, ?TokenInterface $token = null): void
    {
        if (!$user instanceof Trabajador) {
            throw new CustomUserMessageAccountStatusException('Solo los trabajadores pueden entrar en la web.');
        }
    }
}
