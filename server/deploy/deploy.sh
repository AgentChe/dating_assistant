#!/usr/bin/env bash
# Сборка и выкладка сервера Cue на машину с nginx и certbot. Запуск из папки server:
#
#   ./deploy/deploy.sh                     — собрать, выложить и перезапустить службу
#   ./deploy/deploy.sh --domain api.example.com — то же и сайт nginx с HTTPS для домена
#
# В первый раз скрипт заводит пользователя cue и кладёт ключ Gemini из server/.env в /etc/cue-server.env.
set -euo pipefail

TARGET="${TARGET:-dev@192.81.217.92}"
PORT=8401
DOMAIN=""
if [[ "${1:-}" == "--domain" ]]; then DOMAIN="${2:?domain is required}"; fi

cd "$(dirname "$0")/.."
BUILD="$(mktemp -d)"
trap 'rm -rf "$BUILD"' EXIT

echo "→ Сборка под Linux"
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -trimpath -ldflags="-s -w" -o "$BUILD/cue-server" .

echo "→ Выкладка на $TARGET"
scp -q "$BUILD/cue-server" deploy/cue-server.service "$TARGET:/tmp/"
ssh "$TARGET" "set -e
  id cue >/dev/null 2>&1 || sudo useradd --system --no-create-home --shell /usr/sbin/nologin cue
  sudo mkdir -p /opt/cue-server
  sudo install -m 755 -o root -g root /tmp/cue-server /opt/cue-server/cue-server
  sudo install -m 644 -o root -g root /tmp/cue-server.service /etc/systemd/system/cue-server.service
  rm -f /tmp/cue-server /tmp/cue-server.service"

# Ключ уходит по ssh через stdin: ни в аргументах команды, ни в логах его нет.
if ! ssh "$TARGET" "test -f /etc/cue-server.env"; then
  echo "→ Ключ Gemini в /etc/cue-server.env"
  grep '^GEMINI_API_KEY=.' .env | ssh "$TARGET" "set -e
    sudo install -m 640 -o root -g cue /dev/null /etc/cue-server.env
    sudo tee /etc/cue-server.env >/dev/null
    printf 'HOST=127.0.0.1\nPORT=$PORT\nGIN_MODE=release\n' | sudo tee -a /etc/cue-server.env >/dev/null"
fi

echo "→ Перезапуск службы"
ssh "$TARGET" "set -e
  sudo systemctl daemon-reload
  sudo systemctl enable --quiet cue-server
  sudo systemctl restart cue-server
  # Служба поднимается за доли секунды: ждём её молча и только потом проверяем с выводом ошибки.
  for attempt in \$(seq 1 20); do curl -fs http://127.0.0.1:$PORT/healthz >/dev/null && break; sleep 0.5; done
  curl -fsS http://127.0.0.1:$PORT/healthz >/dev/null
  echo '  служба работает'"

if [[ -n "$DOMAIN" ]]; then
  echo "→ Сайт nginx и HTTPS для $DOMAIN"
  sed "s/DOMAIN/$DOMAIN/g" deploy/nginx-site.conf | ssh "$TARGET" "set -e
    if [ ! -f /etc/nginx/sites-available/$DOMAIN ]; then
      sudo tee /etc/nginx/sites-available/$DOMAIN >/dev/null
      sudo ln -sf /etc/nginx/sites-available/$DOMAIN /etc/nginx/sites-enabled/$DOMAIN
      sudo nginx -t
      sudo systemctl reload nginx
    fi
    sudo certbot --nginx --non-interactive --keep-until-expiring --redirect -d $DOMAIN
    curl -fsS https://$DOMAIN/healthz >/dev/null
    echo '  https://$DOMAIN работает'"
fi
