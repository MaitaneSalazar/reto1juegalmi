<?php

declare(strict_types=1);

namespace App\Migrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * Auto-generated Migration: Please modify to your needs!
 */
final class Version20261103120411 extends AbstractMigration
{
    public function getDescription(): string
    {
        return '';
    }

    public function up(Schema $schema): void
    {
        // this up() migration is auto-generated, please modify it to your needs
        $this->addSql('CREATE TABLE direccion (id_direccion INT AUTO_INCREMENT NOT NULL, calle VARCHAR(100) NOT NULL, numero VARCHAR(10) NOT NULL, piso VARCHAR(20) DEFAULT NULL, codigo_postal VARCHAR(5) NOT NULL, ciudad VARCHAR(60) NOT NULL, provincia VARCHAR(60) NOT NULL, PRIMARY KEY (id_direccion)) DEFAULT CHARACTER SET utf8mb4');
        $this->addSql('CREATE TABLE domicilio (id_domicilio INT AUTO_INCREMENT NOT NULL, fecha_alta DATE NOT NULL, fecha_baja DATE DEFAULT NULL, id_cliente INT NOT NULL, id_direccion INT NOT NULL, INDEX IDX_9B942ED12A813255 (id_cliente), INDEX IDX_9B942ED173B102B2 (id_direccion), PRIMARY KEY (id_domicilio)) DEFAULT CHARACTER SET utf8mb4');
        $this->addSql('CREATE TABLE localizacion (id_localizacion INT AUTO_INCREMENT NOT NULL, latitud NUMERIC(9, 6) NOT NULL, longitud NUMERIC(9, 6) NOT NULL, fecha_hora DATETIME NOT NULL, id_cliente INT NOT NULL, INDEX idx_localizacion_fecha (fecha_hora), INDEX IDX_5512F0612A813255 (id_cliente), PRIMARY KEY (id_localizacion)) DEFAULT CHARACTER SET utf8mb4');
        $this->addSql('ALTER TABLE domicilio ADD CONSTRAINT FK_9B942ED12A813255 FOREIGN KEY (id_cliente) REFERENCES cliente (id_usuario) ON DELETE CASCADE');
        $this->addSql('ALTER TABLE domicilio ADD CONSTRAINT FK_9B942ED173B102B2 FOREIGN KEY (id_direccion) REFERENCES direccion (id_direccion)');
        $this->addSql('ALTER TABLE localizacion ADD CONSTRAINT FK_5512F0612A813255 FOREIGN KEY (id_cliente) REFERENCES cliente (id_usuario) ON DELETE CASCADE');
    }

    public function down(Schema $schema): void
    {
        // this down() migration is auto-generated, please modify it to your needs
        $this->addSql('ALTER TABLE domicilio DROP FOREIGN KEY FK_9B942ED12A813255');
        $this->addSql('ALTER TABLE domicilio DROP FOREIGN KEY FK_9B942ED173B102B2');
        $this->addSql('ALTER TABLE localizacion DROP FOREIGN KEY FK_5512F0612A813255');
        $this->addSql('DROP TABLE direccion');
        $this->addSql('DROP TABLE domicilio');
        $this->addSql('DROP TABLE localizacion');
    }
}
