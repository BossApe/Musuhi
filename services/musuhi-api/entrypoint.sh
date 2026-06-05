#!/bin/bash
set -e

FJ_AVAILABLE=0
FJ_RELEASE_API="https://codeberg.org/api/v1/repos/forgejo-contrib/forgejo-cli/releases/latest"
FJ_TOKEN_WAIT_TIMEOUT="${FORGEJO_TOKEN_WAIT_TIMEOUT:-90}"

warn() {
    echo "[WARN] $1"
}

install_fj() {
    echo "Installing forgejo-cli (fj)..."
    local arch fj_url
    arch=$(uname -m)

    if ! fj_url=$(curl -fsS --connect-timeout 5 --max-time 20 "$FJ_RELEASE_API" | jq -r --arg arch "$arch" '.assets[] | select(.name | contains($arch) and contains("linux")) | .browser_download_url' | head -n 1); then
        warn "Failed to fetch fj release metadata. Forgejo bootstrap will be skipped."
        return 1
    fi

    if [ -z "$fj_url" ] || [ "$fj_url" = "null" ]; then
        warn "No matching fj artifact found for arch=$arch. Forgejo bootstrap will be skipped."
        return 1
    fi

    if ! curl -fL --connect-timeout 10 --max-time 120 "$fj_url" -o /tmp/forgejo-cli.tar.gz; then
        warn "Timed out or failed while downloading fj. Forgejo bootstrap will be skipped."
        return 1
    fi

    if ! tar -xzf /tmp/forgejo-cli.tar.gz -C /usr/local/bin/ fj; then
        warn "Failed to extract fj archive. Forgejo bootstrap will be skipped."
        rm -f /tmp/forgejo-cli.tar.gz
        return 1
    fi

    chmod +x /usr/local/bin/fj
    rm -f /tmp/forgejo-cli.tar.gz
    FJ_AVAILABLE=1
    return 0
}

wait_for_token_file() {
    echo "Waiting for Forgejo to generate token..."
    local elapsed=0

    while [ ! -f "${FORGEJO_TOKEN_PATH}" ]; do
        sleep 2
        elapsed=$((elapsed + 2))
        if [ "$elapsed" -ge "$FJ_TOKEN_WAIT_TIMEOUT" ]; then
            warn "Token file was not created within ${FJ_TOKEN_WAIT_TIMEOUT}s."
            return 1
        fi
    done

    return 0
}

bootstrap_forgejo() {
    local repo_name
    repo_name="musuhi"

    if [ "$FJ_AVAILABLE" -ne 1 ]; then
        warn "fj is unavailable. Skip Forgejo bootstrap and continue API startup."
        return 0
    fi

    if ! wait_for_token_file; then
        warn "Skip Forgejo bootstrap and continue API startup."
        return 0
    fi

    export FORGEJO_TOKEN
    FORGEJO_TOKEN=$(cat "${FORGEJO_TOKEN_PATH}")
    echo "Token loaded successfully!"

    if [ -z "$FORGEJO_URL" ] || [ -z "$FORGEJO_TOKEN" ]; then
        warn "FORGEJO_URL or FORGEJO_TOKEN is empty. Skip Forgejo bootstrap."
        return 0
    fi

    if ! fj login --url "$FORGEJO_URL" --token "$FORGEJO_TOKEN"; then
        warn "fj login failed. Skip Forgejo bootstrap."
        return 0
    fi

    echo "Checking if repository '$repo_name' exists..."
    if fj repo list --json | jq -e ".[] | select(.name == \"$repo_name\")" > /dev/null 2>&1; then
        echo "Repository '$repo_name' already exists. Skipping creation."
    else
        echo "Repository '$repo_name' not found. Creating it now..."
        if ! fj repo create "$repo_name" --private=false; then
            warn "Failed to create repository '$repo_name'. Continue API startup."
            return 0
        fi
        echo "Repository '$repo_name' created successfully."
    fi

    echo "Configuring jujutsu (jj)..."
    if jj git remote list | grep -q '^origin '; then
        if ! jj git remote set-url origin "${FORGEJO_URL}/musuhi/${repo_name}.git"; then
            warn "Failed to update jj remote origin. Continue API startup."
        fi
    else
        if ! jj git remote add origin "${FORGEJO_URL}/musuhi/${repo_name}.git"; then
            warn "Failed to add jj remote origin. Continue API startup."
        fi
    fi
}

install_fj || true
bootstrap_forgejo || true

echo "Starting musuhi-api..."
exec "$@"
