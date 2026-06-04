# Forgejo Dockerfile (rootless, PostgreSQL利用)
FROM codeberg.org/forgejo/forgejo:15

# 例: 設定ファイルや初期スクリプトの追加
ARG APP_INI_PATH=/data/forgejo/conf/app.ini
COPY conf/app.ini ${APP_INI_PATH}

# デフォルトCMD/ENTRYPOINTは公式イメージのまま
