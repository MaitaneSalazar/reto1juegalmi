<?php

declare(strict_types=1);

namespace App\Migrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * Auto-generated Migration: Please modify to your needs!
 */
final class Version20261106124050 extends AbstractMigration
{
    public function getDescription(): string
    {
        return '';
    }

    public function up(Schema $schema): void
    {
        // this up() migration is auto-generated, please modify it to your needs
        $this->addSql('CREATE TABLE entrada_stock (id_entrada INT AUTO_INCREMENT NOT NULL, cantidad INT NOT NULL, nota VARCHAR(120) DEFAULT NULL, fecha_hora DATETIME NOT NULL, id_producto INT NOT NULL, id_trabajador INT DEFAULT NULL, INDEX IDX_233883A5F760EA80 (id_producto), INDEX IDX_233883A5E79FFC08 (id_trabajador), PRIMARY KEY (id_entrada)) DEFAULT CHARACTER SET utf8mb4');
        $this->addSql('ALTER TABLE entrada_stock ADD CONSTRAINT FK_233883A5F760EA80 FOREIGN KEY (id_producto) REFERENCES producto (id_producto) ON DELETE CASCADE');
        $this->addSql('ALTER TABLE entrada_stock ADD CONSTRAINT FK_233883A5E79FFC08 FOREIGN KEY (id_trabajador) REFERENCES trabajador (id_usuario) ON DELETE SET NULL');
    }

    public function down(Schema $schema): void
    {
        // this down() migration is auto-generated, please modify it to your needs
        $this->addSql('ALTER TABLE entrada_stock DROP FOREIGN KEY FK_233883A5F760EA80');
        $this->addSql('ALTER TABLE entrada_stock DROP FOREIGN KEY FK_233883A5E79FFC08');
        $this->addSql('DROP TABLE entrada_stock');
    }
}
