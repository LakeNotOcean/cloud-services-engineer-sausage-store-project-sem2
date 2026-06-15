#!/usr/bin/env bash
set -euo pipefail

# ---------- Параметры ----------
usage() {
    echo "Использование: $0 -u DOCKER_USER -v VERSION -p PASSWORD [-h]"
    echo "  -u DOCKER_USER   Имя пользователя Docker Hub"
    echo "  -v VERSION       Версия для тега"
    echo "  -p PASSWORD      Пароль Docker Hub"
    exit 1
}

DOCKER_USER=""
VERSION=""
PASSWORD=""

while getopts "u:v:p:h" opt; do
    case "$opt" in
        u) DOCKER_USER="$OPTARG" ;;
        v) VERSION="$OPTARG" ;;
        p) PASSWORD="$OPTARG" ;;
        h) usage ;;
        *) usage ;;
    esac
done

if [[ -z "$DOCKER_USER" || -z "$VERSION" || -z "$PASSWORD" ]]; then
    echo "Ошибка: необходимо указать -u, -v, -p."
    usage
fi

echo "$PASSWORD" | docker login -u "$DOCKER_USER" --password-stdin

build_and_push() {
    local IMAGE_NAME="$1"
    local CONTEXT_DIR="$2"
    local BUILD_ARGS=("${@:3}")

    echo "========================================="
    echo "Сборка образа: $IMAGE_NAME:$VERSION"
    echo "Контекст: $CONTEXT_DIR"
    echo "Дополнительные аргументы: ${BUILD_ARGS[*]:-нет}"\

    CONTEXT_DIR="../${CONTEXT_DIR}"

    docker build \
        "${BUILD_ARGS[@]}" \
        -t "$IMAGE_NAME:$VERSION" \
        -t "$IMAGE_NAME:latest" \
        "$CONTEXT_DIR"

    echo "Публикация $IMAGE_NAME:$VERSION и $IMAGE_NAME:latest"
    docker push "$IMAGE_NAME:$VERSION"
    docker push "$IMAGE_NAME:latest"
}

build_and_push \
    "$DOCKER_USER/sausage-backend" \
    "backend" \
    --build-arg "VERSION=$VERSION"

build_and_push \
    "$DOCKER_USER/sausage-frontend" \
    "frontend" \
    --build-arg "VERSION=$VERSION"

build_and_push \
    "$DOCKER_USER/sausage-backend-report" \
    "backend-report" \
    --build-arg "VERSION=$VERSION"

echo "Образы опубликованы!"