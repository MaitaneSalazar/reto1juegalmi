#!/bin/bash
# Copia (espejo) de las imágenes de JuegAlmi en S3
set -euo pipefail
BUCKET="reto-backups-bd-654654468501"
/snap/bin/aws s3 sync /home/ubuntu/juegalmi/backend/public/uploads "s3://$BUCKET/uploads/" --delete --only-show-errors
echo "$(date -Is) OK -> s3://$BUCKET/uploads/"
