#!/bin/bash
set -e

# --- 1. fj (Forgejo CLI) の動的インストール ---
echo "Installing forgejo-cli (fj)..."
ARCH=$(uname -m)
FJ_URL=$(curl -s "https://codeberg.org/api/v1/repos/forgejo-contrib/forgejo-cli/releases/latest" | jq -r --arg arch "$ARCH" '.assets[] | select(.name | contains($arch) and contains("linux")) | .browser_download_url')

curl -L "$FJ_URL" -o /tmp/forgejo-cli.tar.gz
tar -xzf /tmp/forgejo-cli.tar.gz -C /usr/local/bin/ fj
chmod +x /usr/local/bin/fj
rm /tmp/forgejo-cli.tar.gz

# --- 2. fj の初期設定 ---
echo "Waiting for Forgejo to generate token..."
# Forgejoがトークンファイルを書き出すまでループで待機
while [ ! -f ${FORGEJO_TOKEN_PATH} ]; do
  sleep 2
done
# ファイルからトークンを読み込んで環境変数にセット
export FORGEJO_TOKEN=$(cat ${FORGEJO_TOKEN_PATH})
echo "Token loaded successfully!"

if [ -z "$FORGEJO_URL" ] || [ -z "$FORGEJO_TOKEN" ]; then
    echo "Error: FORGEJO_URL and FORGEJO_TOKEN must be set."
    exit 1
fi

fj login --url "$FORGEJO_URL" --token "$FORGEJO_TOKEN"

# --- 3. musuhi リポジトリの存在確認と作成 ---
REPO_NAME="musuhi"
echo "Checking if repository '$REPO_NAME' exists..."

if fj repo list --json | jq -e ".[] | select(.name == \"$REPO_NAME\")" > /dev/null 2>&1; then
    echo "Repository '$REPO_NAME' already exists. Skipping creation."
else
    echo "Repository '$REPO_NAME' not found. Creating it now..."
    fj repo create "$REPO_NAME" --private=false
    echo "Repository '$REPO_NAME' created successfully."
fi

# --- 4. jj (Jujutsu) の初期設定とリモートリポジトリの追加 ---
echo "Configuring jujutsu (jj)..."
jj git remote add origin ${FORGEJO_URL}/musuhi/${REPO_NAME}.git

# --- 5. 後続のCMD（./musuhi-api）を実行 ---
echo "Starting musuhi-api..."
exec "$@"
