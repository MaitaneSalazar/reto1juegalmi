<?php

namespace App\Command;

use App\Service\CargadorImagenes;
use Symfony\Component\Console\Attribute\AsCommand;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Input\InputOption;
use Symfony\Component\Console\Output\OutputInterface;
use Symfony\Component\Console\Style\SymfonyStyle;

#[AsCommand(
    name: 'app:cargar-imagenes',
    description: 'Pone las imágenes de fixtures/imagenes a los productos y fotos de la tienda que ya existen (no borra nada)',
)]
class CargarImagenesCommand extends Command
{
    public function __construct(private CargadorImagenes $cargador)
    {
        parent::__construct();
    }

    protected function configure(): void
    {
        $this->addOption('simular', null, InputOption::VALUE_NONE, 'Solo enseña lo que haría, sin cambiar nada');
    }

    protected function execute(InputInterface $input, OutputInterface $output): int
    {
        $io = new SymfonyStyle($input, $output);
        $simular = (bool) $input->getOption('simular');

        $io->title($simular ? 'Simulación (no se cambia nada)' : 'Cargando imágenes');
        $io->table(['Tipo', 'Nombre', 'Resultado'], $this->cargador->cargar($simular));

        if ($simular) {
            $io->note('Para hacerlo de verdad, ejecuta el comando sin --simular.');
        } else {
            $io->success('Hecho. El worker está haciendo las miniaturas.');
        }

        return Command::SUCCESS;
    }
}
