# 1. ビルド用ステージ
FROM node:20-slim AS builder

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates git && \
    rm -rf /var/lib/apt/lists/* && \
    git clone https://github.com/aliasaria/scrumblr.git . && \
    npm ci --only=production

# 【ポイント】server.js を「環境変数を読み込むコード」に書き換える
RUN sed -i "s|url: 'redis://127.0.0.1:6379'|url: process.env.REDIS_URL|g" server.js


# 2. 実行用ステージ
FROM node:20-slim

ENV NODE_ENV=production

# --- ここで docker-compose から受け取る ARG を定義 ---
ARG REDIS_URL=redis://redis:6379
ARG SCRUMBLR_PORT=8080
# ARG の値を ENV（環境変数）に代入する
ENV REDIS_URL=${REDIS_URL}
ENV SCRUMBLR_PORT=${SCRUMBLR_PORT}
# --------------------------------------------------

WORKDIR /app

COPY --from=builder /app /app

USER node
EXPOSE ${SCRUMBLR_PORT}
CMD ["npm", "start"]