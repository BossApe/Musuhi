#!/bin/sh
# gitea CLIはroot実行を拒否するため、gitea呼び出しはsu-exec経由でgitユーザとして実行する
# ファイル書き込みはroot権限で行う
set -eu

APP_INI="/data/gitea/conf/app.ini"
USER_NAME="musuhi"
GITEA="su-exec git /usr/local/bin/gitea"

printf '%s\n' "Creating admin user..."
if ! $GITEA admin user list --config "$APP_INI" 2>/dev/null | grep -q "$USER_NAME"; then
  $GITEA admin user create \
    --admin \
    --username "$USER_NAME" \
    --password musuhi \
    --email musuhi@example.com \
    --must-change-password=false \
    --config "$APP_INI"
else
  printf '%s\n' "Admin user $USER_NAME already exists"
fi

printf '%s\n' "Verifying admin user..."
if ! $GITEA admin user list --config "$APP_INI" 2>/dev/null | grep -q "$USER_NAME"; then
  printf '%s\n' "ERROR: user $USER_NAME was not found after init"
  exit 1
fi

printf '%s\n' "Generating access token..."
TOKEN_DIR="/shared/forgejo_token"
mkdir -p "$TOKEN_DIR"
$GITEA admin user generate-access-token \
  --username "$USER_NAME" \
  --token-name musuhi-api-token \
  --scopes all \
  --raw \
  --config "$APP_INI" > "$TOKEN_DIR/token.txt"
printf '%s\n' "Token saved to $TOKEN_DIR/token.txt"
