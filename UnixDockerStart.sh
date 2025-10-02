#!/bin/bash

# Настройка кодировки
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Переменные для работы с путями
ORIGINAL_CONFIG_FILE="./conf_main/default.conf"
NEW_CONFIG_DIR="./conf"
NEW_CONFIG_FILE="$NEW_CONFIG_DIR/default.conf"
ORIGINAL_COMPOSE_FILE="./docker-compose.template.yml"
NEW_COMPOSE_FILE="./docker-compose.yml"

# Проверяем существование оригинальных файлов
if [[ ! -f "$ORIGINAL_CONFIG_FILE" ]]; then
    echo "Ошибка: Файл '$ORIGINAL_CONFIG_FILE' не найден."
    exit 1
fi

if [[ ! -f "$ORIGINAL_COMPOSE_FILE" ]]; then
    echo "Ошибка: Файл '$ORIGINAL_COMPOSE_FILE' не найден."
    exit 1
fi

# Запрашиваем новые значения server_name и порта
read -rp "Введите полный доменный адрес прокси-сервера (например, your-proxy-domain.example.com): " SERVER_NAME
read -rp "Введите номер порта (например, 80 или 443): " PORT_NUMBER

# Подтверждение введённых данных
echo "Ваш прокси-сервер будет настроен следующим образом:"
echo "Доменное имя: $SERVER_NAME"
echo "Порт: $PORT_NUMBER"

# Просим подтвердить изменения
read -rp "Подтвердите изменения? (Y/N): " CONFIRMATION
CONFIRMATION=${CONFIRMATION^^}
if [[ "$CONFIRMATION" != "Y" ]]; then
    echo "Отмена изменений."
    exit 0
fi

# Создаём директорию конфигов, если её нет
mkdir -p "$NEW_CONFIG_DIR"

# Копируем оригинал в новый каталог
cp "$ORIGINAL_CONFIG_FILE" "$NEW_CONFIG_FILE"

# Обновляем поля server_name и listen в скопированном файле конфигурации Nginx
sed -i "s|^ *listen.*|listen $PORT_NUMBER;|" "$NEW_CONFIG_FILE"
sed -i "s|^ *server_name.*|server_name $SERVER_NAME;|" "$NEW_CONFIG_FILE"

# Копируем шаблон docker-compose в рабочий файл
cp "$ORIGINAL_COMPOSE_FILE" "$NEW_COMPOSE_FILE"

# Обновляем порт в файле docker-compose.yml
sed -i "s|$[[:space:]]*-$ portNum|\1 $PORT_NUMBER:$PORT_NUMBER|" "$NEW_COMPOSE_FILE"

# Сообщаем об успешном завершении операции
echo "Конфигурация успешно обновлена!"

# Предложение запустить сборку docker-compose
read -rp "Хотите запустить сборку docker-compose? (Y/N): " RUN_DOCKER_COMPOSE
RUN_DOCKER_COMPOSE=${RUN_DOCKER_COMPOSE^^}
if [[ "$RUN_DOCKER_COMPOSE" == "Y" ]]; then
    # Запускаем сборку контейнеров
    docker-compose up --force-recreate --build -d
    echo "Docker compose запущен успешно!"
else
    echo "Сборка docker-compose отменена."
fi