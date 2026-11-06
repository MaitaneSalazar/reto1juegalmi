<?php

declare(strict_types=1);

namespace App\Migrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * Auto-generated Migration: Please modify to your needs!
 */
final class Version20261104072826 extends AbstractMigration
{
    public function getDescription(): string
    {
        return '';
    }

    public function up(Schema $schema): void
    {
        // this up() migration is auto-generated, please modify it to your needs
        $this->addSql('CREATE TABLE foto_reparacion (id_foto INT AUTO_INCREMENT NOT NULL, ruta VARCHAR(255) NOT NULL, fecha_subida DATETIME NOT NULL, id_reparacion INT NOT NULL, INDEX IDX_708436DE79BCE6C (id_reparacion), PRIMARY KEY (id_foto)) DEFAULT CHARACTER SET utf8mb4');
        $this->addSql('CREATE TABLE historial_estado (id_historial INT AUTO_INCREMENT NOT NULL, estado VARCHAR(20) NOT NULL, fecha_hora DATETIME NOT NULL, descripcion LONGTEXT DEFAULT NULL, id_reparacion INT NOT NULL, INDEX IDX_21C24561E79BCE6C (id_reparacion), PRIMARY KEY (id_historial)) DEFAULT CHARACTER SET utf8mb4');
        $this->addSql('CREATE TABLE reparacion (id_reparacion INT AUTO_INCREMENT NOT NULL, tipo_dispositivo VARCHAR(20) NOT NULL, marca VARCHAR(50) NOT NULL, modelo VARCHAR(100) NOT NULL, componente VARCHAR(100) DEFAULT NULL, descripcion_averia LONGTEXT NOT NULL, presupuesto NUMERIC(8, 2) DEFAULT NULL, id_cliente INT NOT NULL, INDEX IDX_42114EBB2A813255 (id_cliente), PRIMARY KEY (id_reparacion)) DEFAULT CHARACTER SET utf8mb4');
        $this->addSql('CREATE TABLE trabajador_reparacion (id_trabajador_reparacion INT AUTO_INCREMENT NOT NULL, fecha_inicio DATETIME NOT NULL, fecha_fin DATETIME DEFAULT NULL, id_trabajador INT NOT NULL, id_reparacion INT NOT NULL, INDEX IDX_DC670506E79FFC08 (id_trabajador), INDEX IDX_DC670506E79BCE6C (id_reparacion), PRIMARY KEY (id_trabajador_reparacion)) DEFAULT CHARACTER SET utf8mb4');
        $this->addSql('ALTER TABLE foto_reparacion ADD CONSTRAINT FK_708436DE79BCE6C FOREIGN KEY (id_reparacion) REFERENCES reparacion (id_reparacion) ON DELETE CASCADE');
        $this->addSql('ALTER TABLE historial_estado ADD CONSTRAINT FK_21C24561E79BCE6C FOREIGN KEY (id_reparacion) REFERENCES reparacion (id_reparacion) ON DELETE CASCADE');
        $this->addSql('ALTER TABLE reparacion ADD CONSTRAINT FK_42114EBB2A813255 FOREIGN KEY (id_cliente) REFERENCES cliente (id_usuario)');
        $this->addSql('ALTER TABLE trabajador_reparacion ADD CONSTRAINT FK_DC670506E79FFC08 FOREIGN KEY (id_trabajador) REFERENCES trabajador (id_usuario)');
        $this->addSql('ALTER TABLE trabajador_reparacion ADD CONSTRAINT FK_DC670506E79BCE6C FOREIGN KEY (id_reparacion) REFERENCES reparacion (id_reparacion) ON DELETE CASCADE');
    }

    public function down(Schema $schema): void
    {
        // this down() migration is auto-generated, please modify it to your needs
        $this->addSql('ALTER TABLE foto_reparacion DROP FOREIGN KEY FK_708436DE79BCE6C');
        $this->addSql('ALTER TABLE historial_estado DROP FOREIGN KEY FK_21C24561E79BCE6C');
        $this->addSql('ALTER TABLE reparacion DROP FOREIGN KEY FK_42114EBB2A813255');
        $this->addSql('ALTER TABLE trabajador_reparacion DROP FOREIGN KEY FK_DC670506E79FFC08');
        $this->addSql('ALTER TABLE trabajador_reparacion DROP FOREIGN KEY FK_DC670506E79BCE6C');
        $this->addSql('DROP TABLE foto_reparacion');
        $this->addSql('DROP TABLE historial_estado');
        $this->addSql('DROP TABLE reparacion');
        $this->addSql('DROP TABLE trabajador_reparacion');
    }
}
