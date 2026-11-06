<?php

declare(strict_types=1);

namespace App\Migrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * Auto-generated Migration: Please modify to your needs!
 */
final class Version20261104070836 extends AbstractMigration
{
    public function getDescription(): string
    {
        return '';
    }

    public function up(Schema $schema): void
    {
        // this up() migration is auto-generated, please modify it to your needs
        $this->addSql('CREATE TABLE departamento (id_departamento INT AUTO_INCREMENT NOT NULL, nombre VARCHAR(60) NOT NULL, descripcion LONGTEXT DEFAULT NULL, telefono VARCHAR(15) DEFAULT NULL, activo TINYINT DEFAULT 1 NOT NULL, id_tienda INT NOT NULL, INDEX IDX_40E497EBE6F150D3 (id_tienda), PRIMARY KEY (id_departamento)) DEFAULT CHARACTER SET utf8mb4');
        $this->addSql('CREATE TABLE foto_tienda (id_foto INT AUTO_INCREMENT NOT NULL, ruta VARCHAR(255) NOT NULL, titulo VARCHAR(100) DEFAULT NULL, id_tienda INT NOT NULL, INDEX IDX_F3174F67E6F150D3 (id_tienda), PRIMARY KEY (id_foto)) DEFAULT CHARACTER SET utf8mb4');
        $this->addSql('CREATE TABLE tienda (id_tienda INT AUTO_INCREMENT NOT NULL, nombre VARCHAR(100) NOT NULL, telefono VARCHAR(15) NOT NULL, email VARCHAR(180) NOT NULL, latitud NUMERIC(9, 6) NOT NULL, longitud NUMERIC(9, 6) NOT NULL, historia LONGTEXT DEFAULT NULL, id_direccion INT NOT NULL, INDEX IDX_C0C6E53E73B102B2 (id_direccion), PRIMARY KEY (id_tienda)) DEFAULT CHARACTER SET utf8mb4');
        $this->addSql('CREATE TABLE trabajador_departamento (id_trabajador_departamento INT AUTO_INCREMENT NOT NULL, fecha_inicio DATE NOT NULL, fecha_fin DATE DEFAULT NULL, id_trabajador INT NOT NULL, id_departamento INT NOT NULL, INDEX IDX_F0814170E79FFC08 (id_trabajador), INDEX IDX_F08141706325E299 (id_departamento), PRIMARY KEY (id_trabajador_departamento)) DEFAULT CHARACTER SET utf8mb4');
        $this->addSql('ALTER TABLE departamento ADD CONSTRAINT FK_40E497EBE6F150D3 FOREIGN KEY (id_tienda) REFERENCES tienda (id_tienda)');
        $this->addSql('ALTER TABLE foto_tienda ADD CONSTRAINT FK_F3174F67E6F150D3 FOREIGN KEY (id_tienda) REFERENCES tienda (id_tienda) ON DELETE CASCADE');
        $this->addSql('ALTER TABLE tienda ADD CONSTRAINT FK_C0C6E53E73B102B2 FOREIGN KEY (id_direccion) REFERENCES direccion (id_direccion)');
        $this->addSql('ALTER TABLE trabajador_departamento ADD CONSTRAINT FK_F0814170E79FFC08 FOREIGN KEY (id_trabajador) REFERENCES trabajador (id_usuario) ON DELETE CASCADE');
        $this->addSql('ALTER TABLE trabajador_departamento ADD CONSTRAINT FK_F08141706325E299 FOREIGN KEY (id_departamento) REFERENCES departamento (id_departamento)');
    }

    public function down(Schema $schema): void
    {
        // this down() migration is auto-generated, please modify it to your needs
        $this->addSql('ALTER TABLE departamento DROP FOREIGN KEY FK_40E497EBE6F150D3');
        $this->addSql('ALTER TABLE foto_tienda DROP FOREIGN KEY FK_F3174F67E6F150D3');
        $this->addSql('ALTER TABLE tienda DROP FOREIGN KEY FK_C0C6E53E73B102B2');
        $this->addSql('ALTER TABLE trabajador_departamento DROP FOREIGN KEY FK_F0814170E79FFC08');
        $this->addSql('ALTER TABLE trabajador_departamento DROP FOREIGN KEY FK_F08141706325E299');
        $this->addSql('DROP TABLE departamento');
        $this->addSql('DROP TABLE foto_tienda');
        $this->addSql('DROP TABLE tienda');
        $this->addSql('DROP TABLE trabajador_departamento');
    }
}
