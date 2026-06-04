FROM golang:1.23-alpine AS builder
WORKDIR /app
COPY src/go.mod src/go.sum ./
RUN go mod download
COPY src/. .
RUN go build -o musuhi-api .

FROM alpine:3.19
RUN apk add --no-cache ca-certificates wget curl jq git bash git-lfs \
    && apk add --no-cache --repository http://alpinelinux.org jujutsu \
    && git lfs install

ARG FORGEJO_USER=musuhi
ARG FORGEJO_PASSWORD=musuhi
ARG FORGEJO_EMAIL=musuhi@example.com
RUN jj config set --user user.name  "${FORGEJO_USER}}" \
    && jj config set --user user.password "${FORGEJO_PASSWORD}" \
    && jj config set --user user.email "${FORGEJO_EMAIL}"

WORKDIR /
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /app
COPY --from=builder /app/musuhi-api .
RUN chmod +x ./musuhi-api
ARG MUSUHI_API_PORT=8080
EXPOSE ${MUSUHI_API_PORT:-8080}
ENTRYPOINT ["/entrypoint.sh"]
CMD ["./musuhi-api"]
