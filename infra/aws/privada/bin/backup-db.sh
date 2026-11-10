#!/bin/bash
# Copia del servidor. La contraseña de MariaDB va en la variable MARIADB_ROOT_PASSWORD (no se sube a git).
# Copia de seguridad de MariaDB (docker /opt/db) al bucket S3
set -euo pipefail
BUCKET="reto-backups-bd-654654468501"
FECHA=$(date +%Y-%m-%d_%H-%M-%S)
FICHERO=/tmp/mariadb-$FECHA.sql.gz

docker compose -f /opt/db/docker-compose.yml exec -T mysql \
  mariadb-dump -uroot -p"${MARIADB_ROOT_PASSWORD}" --all-databases --single-transaction --routines --events \
  | gzip > "$FICHERO"

/snap/bin/aws s3 cp "$FICHERO" "s3://$BUCKET/mariadb/mariadb-$FECHA.sql.gz" --only-show-errors
rm -f "$FICHERO"
echo "$(date -Is) OK -> s3://$BUCKET/mariadb/mariadb-$FECHA.sql.gz"
