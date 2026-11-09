<?php

declare(strict_types=1);

namespace App\Migrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * Auto-generated Migration: Please modify to your needs!
 */
final class Version20261106125256 extends AbstractMigration
{
    public function getDescription(): string
    {
        return '';
    }

    public function up(Schema $schema): void
    {
        // this up() migration is auto-generated, please modify it to your needs
        $this->addSql('ALTER TABLE foto_reparacion ADD del_taller TINYINT DEFAULT 0 NOT NULL');
        $this->addSql('ALTER TABLE reparacion ADD notas_internas LONGTEXT DEFAULT NULL, ADD presupuesto_aceptado TINYINT DEFAULT NULL, ADD avisado_en DATETIME DEFAULT NULL');
    }

    public function down(Schema $schema): void
    {
        // this down() migration is auto-generated, please modify it to your needs
        $this->addSql('ALTER TABLE foto_reparacion DROP del_taller');
        $this->addSql('ALTER TABLE reparacion DROP notas_internas, DROP presupuesto_aceptado, DROP avisado_en');
    }
}
