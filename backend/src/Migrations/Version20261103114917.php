<?php

declare(strict_types=1);

namespace App\Migrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * Auto-generated Migration: Please modify to your needs!
 */
final class Version20261103114917 extends AbstractMigration
{
    public function getDescription(): string
    {
        return '';
    }

    public function up(Schema $schema): void
    {
        // this up() migration is auto-generated, please modify it to your needs
        $this->addSql('CREATE TABLE cliente (fecha_registro DATETIME NOT NULL, id_usuario INT NOT NULL, PRIMARY KEY (id_usuario)) DEFAULT CHARACTER SET utf8mb4');
        $this->addSql('CREATE TABLE trabajador (cargo VARCHAR(50) NOT NULL, es_admin TINYINT DEFAULT 0 NOT NULL, fecha_contratacion DATE NOT NULL, id_usuario INT NOT NULL, PRIMARY KEY (id_usuario)) DEFAULT CHARACTER SET utf8mb4');
        $this->addSql('CREATE TABLE usuario (id_usuario INT AUTO_INCREMENT NOT NULL, nombre VARCHAR(50) NOT NULL, apellido1 VARCHAR(50) NOT NULL, apellido2 VARCHAR(50) DEFAULT NULL, dni VARCHAR(9) NOT NULL, email VARCHAR(180) NOT NULL, password_hash VARCHAR(255) NOT NULL, telefono VARCHAR(15) DEFAULT NULL, foto_perfil VARCHAR(255) DEFAULT NULL, activo TINYINT DEFAULT 1 NOT NULL, tipo VARCHAR(20) NOT NULL, UNIQUE INDEX UNIQ_2265B05D7F8F253B (dni), UNIQUE INDEX UNIQ_2265B05DE7927C74 (email), PRIMARY KEY (id_usuario)) DEFAULT CHARACTER SET utf8mb4');
        $this->addSql('ALTER TABLE cliente ADD CONSTRAINT FK_F41C9B25FCF8192D FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario) ON DELETE CASCADE');
        $this->addSql('ALTER TABLE trabajador ADD CONSTRAINT FK_42157CDFFCF8192D FOREIGN KEY (id_usuario) REFERENCES usuario (id_usuario) ON DELETE CASCADE');
    }

    public function down(Schema $schema): void
    {
        // this down() migration is auto-generated, please modify it to your needs
        $this->addSql('ALTER TABLE cliente DROP FOREIGN KEY FK_F41C9B25FCF8192D');
        $this->addSql('ALTER TABLE trabajador DROP FOREIGN KEY FK_42157CDFFCF8192D');
        $this->addSql('DROP TABLE cliente');
        $this->addSql('DROP TABLE trabajador');
        $this->addSql('DROP TABLE usuario');
    }
}
