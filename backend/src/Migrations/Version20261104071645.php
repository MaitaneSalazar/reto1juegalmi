<?php

declare(strict_types=1);

namespace App\Migrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * Auto-generated Migration: Please modify to your needs!
 */
final class Version20261104071645 extends AbstractMigration
{
    public function getDescription(): string
    {
        return '';
    }

    public function up(Schema $schema): void
    {
        // this up() migration is auto-generated, please modify it to your needs
        $this->addSql('CREATE TABLE consola (almacenamiento_gb SMALLINT NOT NULL, color VARCHAR(30) NOT NULL, edicion VARCHAR(50) DEFAULT NULL, id_producto INT NOT NULL, PRIMARY KEY (id_producto)) DEFAULT CHARACTER SET utf8mb4');
        $this->addSql('CREATE TABLE empresa (id_empresa INT AUTO_INCREMENT NOT NULL, nombre VARCHAR(60) NOT NULL, UNIQUE INDEX UNIQ_B8D75A503A909126 (nombre), PRIMARY KEY (id_empresa)) DEFAULT CHARACTER SET utf8mb4');
        $this->addSql('CREATE TABLE movil (pantalla_pulgadas NUMERIC(3, 1) NOT NULL, ram_gb SMALLINT NOT NULL, almacenamiento_gb SMALLINT NOT NULL, sistema_operativo VARCHAR(30) NOT NULL, bateria_mah INT NOT NULL, id_producto INT NOT NULL, PRIMARY KEY (id_producto)) DEFAULT CHARACTER SET utf8mb4');
        $this->addSql('CREATE TABLE producto (id_producto INT AUTO_INCREMENT NOT NULL, nombre VARCHAR(120) NOT NULL, descripcion LONGTEXT DEFAULT NULL, precio_venta NUMERIC(8, 2) NOT NULL, stock INT DEFAULT 0 NOT NULL, imagen VARCHAR(255) DEFAULT NULL, activo TINYINT DEFAULT 1 NOT NULL, id_empresa INT NOT NULL, tipo VARCHAR(20) NOT NULL, INDEX IDX_A7BB0615664AF320 (id_empresa), PRIMARY KEY (id_producto)) DEFAULT CHARACTER SET utf8mb4');
        $this->addSql('CREATE TABLE tablet (pantalla_pulgadas NUMERIC(3, 1) NOT NULL, almacenamiento_gb SMALLINT NOT NULL, sistema_operativo VARCHAR(30) NOT NULL, conectividad VARCHAR(10) NOT NULL, id_producto INT NOT NULL, PRIMARY KEY (id_producto)) DEFAULT CHARACTER SET utf8mb4');
        $this->addSql('CREATE TABLE videojuego (plataforma VARCHAR(30) NOT NULL, genero VARCHAR(30) NOT NULL, pegi SMALLINT NOT NULL, precio_alquiler_dia NUMERIC(6, 2) NOT NULL, copias_alquiler INT DEFAULT 0 NOT NULL, id_producto INT NOT NULL, PRIMARY KEY (id_producto)) DEFAULT CHARACTER SET utf8mb4');
        $this->addSql('ALTER TABLE consola ADD CONSTRAINT FK_316E0BAFF760EA80 FOREIGN KEY (id_producto) REFERENCES producto (id_producto) ON DELETE CASCADE');
        $this->addSql('ALTER TABLE movil ADD CONSTRAINT FK_64824ACBF760EA80 FOREIGN KEY (id_producto) REFERENCES producto (id_producto) ON DELETE CASCADE');
        $this->addSql('ALTER TABLE producto ADD CONSTRAINT FK_A7BB0615664AF320 FOREIGN KEY (id_empresa) REFERENCES empresa (id_empresa)');
        $this->addSql('ALTER TABLE tablet ADD CONSTRAINT FK_1A239782F760EA80 FOREIGN KEY (id_producto) REFERENCES producto (id_producto) ON DELETE CASCADE');
        $this->addSql('ALTER TABLE videojuego ADD CONSTRAINT FK_AA5E6DFAF760EA80 FOREIGN KEY (id_producto) REFERENCES producto (id_producto) ON DELETE CASCADE');
    }

    public function down(Schema $schema): void
    {
        // this down() migration is auto-generated, please modify it to your needs
        $this->addSql('ALTER TABLE consola DROP FOREIGN KEY FK_316E0BAFF760EA80');
        $this->addSql('ALTER TABLE movil DROP FOREIGN KEY FK_64824ACBF760EA80');
        $this->addSql('ALTER TABLE producto DROP FOREIGN KEY FK_A7BB0615664AF320');
        $this->addSql('ALTER TABLE tablet DROP FOREIGN KEY FK_1A239782F760EA80');
        $this->addSql('ALTER TABLE videojuego DROP FOREIGN KEY FK_AA5E6DFAF760EA80');
        $this->addSql('DROP TABLE consola');
        $this->addSql('DROP TABLE empresa');
        $this->addSql('DROP TABLE movil');
        $this->addSql('DROP TABLE producto');
        $this->addSql('DROP TABLE tablet');
        $this->addSql('DROP TABLE videojuego');
    }
}
