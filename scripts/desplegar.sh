#!/bin/bash
# Sube el último commit de backend/ a AWS en un solo paso: ./scripts/desplegar.sh
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

if [ -n "$(git status --porcelain backend)" ]; then
    echo "✗ Hay cambios en backend/ sin commit. Haz primero el commit."; exit 1
fi
git fetch -q
if [ -n "$(git log --oneline HEAD..@{u})" ]; then
    echo "✗ Hay commits nuevos en GitHub. Haz primero: git pull --rebase"; exit 1
fi

git push
echo "→ Subiendo $(git log --oneline -1) a AWS…"
git archive --format=tar HEAD backend | ssh juegalmi-aws 'tar -x -C ~/juegalmi'
ssh juegalmi-aws 'cd ~/juegalmi/backend \
  && composer install --no-dev -o --no-interaction --quiet \
  && php bin/console doctrine:migrations:migrate --no-interaction --allow-no-migration \
  && php bin/console cache:clear --quiet \
  && sudo systemctl restart symfony juegalmi-worker && sleep 3 \
  && systemctl is-active symfony juegalmi-worker \
  && curl -s -o /dev/null -w "API: %{http_code}\n" http://localhost:8000/api/estado'
echo "✓ Desplegado en https://symfony.44-219-6-54.sslip.io"
