# сборка Golang приложения
FROM golang:1.26-alpine AS builder

# установка git и сертификатов (может потребоваться)
RUN apk add --no-cache git ca-certificates

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY . .

# аргументы для кросс-компиляции (при необходимости)
ARG TARGETOS=linux
ARG TARGETARCH=amd64

# компиляция статического бинарника
RUN CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} \
    go build -ldflags="-w -s" -o /api .

# финальный этап, запуск основного приложения
FROM alpine:3.22.4

RUN apk add --no-cache wget

LABEL maintainer="ch3shirsins@yandex.ru" \
    description="Cloud Services Engineer Docker Project Sem2 Golang Backend-Report" \
    version="1.0.0" \
    security.capabilities="minimal"

# переменные окружения приложения (можно переопределить)
ENV PORT=8080 \
    DB=mongodb://localhost:27017/reports

# создаём непривилегированного пользователя
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# копируем корневые сертификаты и бинарник
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --chown=appuser:appgroup --from=builder /api /api

USER appuser
WORKDIR /app

EXPOSE 8080

# проверка готовности через health-эндпоинт
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 -O /dev/null http://localhost:8080/api/v1/health || exit 1

CMD ["/api"]