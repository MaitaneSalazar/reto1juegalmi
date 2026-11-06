<?php

declare(strict_types=1);

namespace App\Migrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * Auto-generated Migration: Please modify to your needs!
 */
final class Version20261104072409 extends AbstractMigration
{
    public function getDescription(): string
    {
        return '';
    }

    public function up(Schema $schema): void
    {
        // this up() migration is auto-generated, please modify it to your needs
        $this->addSql('CREATE TABLE alquiler (id_alquiler INT AUTO_INCREMENT NOT NULL, fecha_inicio DATE NOT NULL, fecha_fin_prevista DATE NOT NULL, id_cliente INT NOT NULL, INDEX IDX_655BED392A813255 (id_cliente), PRIMARY KEY (id_alquiler)) DEFAULT CHARACTER SET utf8mb4');
        $this->addSql('CREATE TABLE alquiler_videojuego (id_alquiler_videojuego INT AUTO_INCREMENT NOT NULL, precio NUMERIC(6, 2) NOT NULL, fecha_devolucion DATE DEFAULT NULL, id_alquiler INT NOT NULL, id_videojuego INT NOT NULL, UNIQUE INDEX uniq_alquiler_videojuego (id_alquiler, id_videojuego), INDEX IDX_30221FAE358001AC (id_alquiler), INDEX IDX_30221FAEFD4ED2D (id_videojuego), PRIMARY KEY (id_alquiler_videojuego)) DEFAULT CHARACTER SET utf8mb4');
        $this->addSql('ALTER TABLE alquiler ADD CONSTRAINT FK_655BED392A813255 FOREIGN KEY (id_cliente) REFERENCES cliente (id_usuario)');
        $this->addSql('ALTER TABLE alquiler_videojuego ADD CONSTRAINT FK_30221FAE358001AC FOREIGN KEY (id_alquiler) REFERENCES alquiler (id_alquiler) ON DELETE CASCADE');
        $this->addSql('ALTER TABLE alquiler_videojuego ADD CONSTRAINT FK_30221FAEFD4ED2D FOREIGN KEY (id_videojuego) REFERENCES videojuego (id_producto)');
    }

    public function down(Schema $schema): void
    {
        // this down() migration is auto-generated, please modify it to your needs
        $this->addSql('ALTER TABLE alquiler DROP FOREIGN KEY FK_655BED392A813255');
        $this->addSql('ALTER TABLE alquiler_videojuego DROP FOREIGN KEY FK_30221FAE358001AC');
        $this->addSql('ALTER TABLE alquiler_videojuego DROP FOREIGN KEY FK_30221FAEFD4ED2D');
        $this->addSql('DROP TABLE alquiler');
        $this->addSql('DROP TABLE alquiler_videojuego');
    }
}
