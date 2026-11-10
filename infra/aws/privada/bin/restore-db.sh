#!/bin/bash
# Copia del servidor. La contraseña de MariaDB va en la variable MARIADB_ROOT_PASSWORD (no se sube a git).
# Uso: sudo restore-db.sh mariadb-AAAA-MM-DD_HH-MM-SS.sql.gz
set -euo pipefail
BUCKET="reto-backups-bd-654654468501"
[ $# -eq 1 ] || { echo "Uso: $0 <fichero>   (ver: aws s3 ls s3://$BUCKET/mariadb/)"; exit 1; }
/snap/bin/aws s3 cp "s3://$BUCKET/mariadb/$1" - | gunzip \
  | docker compose -f /opt/db/docker-compose.yml exec -T mysql mariadb -uroot -p"${MARIADB_ROOT_PASSWORD}"
echo "Restaurado $1"
