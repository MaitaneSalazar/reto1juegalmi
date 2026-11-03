#!/usr/bin/env bash
# Copia de seguridad de JuegAlmi: base de datos + imágenes subidas.
# Guarda las 7 últimas copias y borra las más antiguas.
# Las credenciales de MySQL se leen de ~/.my.cnf (no están en este archivo).
set -euo pipefail

PROYECTO="$(cd "$(dirname "$0")/.." && pwd)"     # carpeta backend/
DESTINO="${BACKUP_DIR:-$HOME/backups/juegalmi}"  # dónde se guardan las copias
BD="${BACKUP_DB:-juegalmi}"                      # nombre de la base de datos
MANTENER=7
FECHA="$(date +%Y-%m-%d_%H-%M)"

mkdir -p "$DESTINO"

# 1. Base de datos: estructura y datos, comprimida
mysqldump --no-tablespaces --single-transaction --triggers "$BD" \
  | gzip > "$DESTINO/bd_${FECHA}.sql.gz"

# 2. Imágenes subidas (soporte, productos, tienda)
tar -czf "$DESTINO/uploads_${FECHA}.tar.gz" -C "$PROYECTO/public" uploads

# 3. Borrar las copias antiguas, dejando las $MANTENER más recientes
ls -1t "$DESTINO"/bd_*.sql.gz      | tail -n +$((MANTENER + 1)) | xargs -r rm --
ls -1t "$DESTINO"/uploads_*.tar.gz | tail -n +$((MANTENER + 1)) | xargs -r rm --

echo "$(date '+%F %T') Copia creada: bd_${FECHA}.sql.gz y uploads_${FECHA}.tar.gz"
