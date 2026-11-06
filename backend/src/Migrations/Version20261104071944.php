<?php

declare(strict_types=1);

namespace App\Migrations;

use Doctrine\DBAL\Schema\Schema;
use Doctrine\Migrations\AbstractMigration;

/**
 * Auto-generated Migration: Please modify to your needs!
 */
final class Version20261104071944 extends AbstractMigration
{
    public function getDescription(): string
    {
        return '';
    }

    public function up(Schema $schema): void
    {
        // this up() migration is auto-generated, please modify it to your needs
        $this->addSql('CREATE TABLE pedido (id_pedido INT AUTO_INCREMENT NOT NULL, fecha DATETIME NOT NULL, estado VARCHAR(20) DEFAULT \'pendiente\' NOT NULL, id_domicilio INT NOT NULL, INDEX IDX_C4EC16CE1BA192F6 (id_domicilio), PRIMARY KEY (id_pedido)) DEFAULT CHARACTER SET utf8mb4');
        $this->addSql('CREATE TABLE pedido_producto (id_pedido_producto INT AUTO_INCREMENT NOT NULL, cantidad INT NOT NULL, precio_unitario NUMERIC(8, 2) NOT NULL, id_pedido INT NOT NULL, id_producto INT NOT NULL, UNIQUE INDEX uniq_pedido_producto (id_pedido, id_producto), INDEX IDX_DD333C2E2DBA323 (id_pedido), INDEX IDX_DD333C2F760EA80 (id_producto), PRIMARY KEY (id_pedido_producto)) DEFAULT CHARACTER SET utf8mb4');
        $this->addSql('ALTER TABLE pedido ADD CONSTRAINT FK_C4EC16CE1BA192F6 FOREIGN KEY (id_domicilio) REFERENCES domicilio (id_domicilio)');
        $this->addSql('ALTER TABLE pedido_producto ADD CONSTRAINT FK_DD333C2E2DBA323 FOREIGN KEY (id_pedido) REFERENCES pedido (id_pedido) ON DELETE CASCADE');
        $this->addSql('ALTER TABLE pedido_producto ADD CONSTRAINT FK_DD333C2F760EA80 FOREIGN KEY (id_producto) REFERENCES producto (id_producto)');
    }

    public function down(Schema $schema): void
    {
        // this down() migration is auto-generated, please modify it to your needs
        $this->addSql('ALTER TABLE pedido DROP FOREIGN KEY FK_C4EC16CE1BA192F6');
        $this->addSql('ALTER TABLE pedido_producto DROP FOREIGN KEY FK_DD333C2E2DBA323');
        $this->addSql('ALTER TABLE pedido_producto DROP FOREIGN KEY FK_DD333C2F760EA80');
        $this->addSql('DROP TABLE pedido');
        $this->addSql('DROP TABLE pedido_producto');
    }
}
