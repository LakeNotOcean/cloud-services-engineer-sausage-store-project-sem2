ARG VERSION=${VERSION}

# установка зависимостей с помощью npm
FROM node:26-alpine AS base

WORKDIR /app

COPY package*.json ./
RUN npm ci && npm cache clean --force

# стенд для dev-сервера
FROM base AS dev

WORKDIR /app
COPY . .

EXPOSE 8080

CMD ["npx", "ng", "serve", "--host", "0.0.0.0", "--port", "8080"]

# сборка приложения для prod
FROM base AS builder

# для совместимости со старым Webpack
ENV NODE_OPTIONS=--openssl-legacy-provider

# установка git (может потребоваться)
RUN apk add --no-cache git ca-certificates

WORKDIR /app
COPY . .

RUN npm run build -- --prod


FROM nginxinc/nginx-unprivileged:1.29.8-alpine AS prod

USER root

LABEL maintainer="ch3shirsins@yandex.ru" \
    description="Cloud Services Engineer Docker Project Sem2 Angular-nginx Frontend" \
    version="1.0.0" \
    security.capabilities="minimal"

RUN apk add --no-cache wget

# запуск от пользователя appuser
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

COPY --from=builder --chown=appuser:appgroup /app/dist/frontend /usr/share/nginx/html
COPY --chown=appuser:appgroup nginx.conf /etc/nginx/conf.d/default.conf

RUN chmod -R 755 /usr/share/nginx/html

USER nginx

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost/ || exit 1

CMD ["nginx", "-g", "daemon off;"]