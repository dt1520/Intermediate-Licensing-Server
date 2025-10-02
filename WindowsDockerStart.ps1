# Настройка кодировки консоли
$OutputEncoding = [System.Text.Encoding]::UTF8

# Переменные для работы с путями
$originalConfigFile = ".\conf_main\default.conf"
$newConfigDir = ".\conf"
$newConfigFile = Join-Path $newConfigDir "default.conf"
$originalComposeFile = ".\docker-compose.template.yml"
$newComposeFile = ".\docker-compose.yml"

# Проверяем существование оригинальных файлов
if (-not(Test-Path $originalConfigFile)) {
    Write-Host "Ошибка: Файл '$originalConfigFile' не найден."
    exit
}

if (-not(Test-Path $originalComposeFile)) {
    Write-Host "Ошибка: Файл '$originalComposeFile' не найден."
    exit
}

# Запрашиваем новые значения server_name и порта
$serverName = Read-Host "Введите полный доменный адрес прокси-сервера (например, your-proxy-domain.example.com)"
$portNumber = Read-Host "Введите номер порта (например, 80 или 443)"

# Подтверждение введённых данных
Write-Host "Ваш прокси-сервер будет настроен следующим образом:"
Write-Host "Доменное имя: $serverName"
Write-Host "Порт: $portNumber"

# Просим подтвердить изменения
$confirmation = Read-Host "Подтвердите изменения? (Y/N)"
if ($confirmation.ToUpper() -ne "Y") {
    Write-Host "Отмена изменений."
    exit
}

# Создаём директорию конфигов, если её нет
if (-not(Test-Path $newConfigDir)) {
    New-Item -ItemType Directory -Path $newConfigDir | Out-Null
}

# Копируем оригинал в новый каталог
Copy-Item $originalConfigFile $newConfigFile -Force

# Обновляем поля server_name и listen в скопированном файле конфигурации Nginx
(Get-Content $newConfigFile) |
ForEach-Object {
    if ($_ -match "^(\s*)listen\s+\S+;") {
        "$($matches[1])listen $portNumber;"
    }
    elseif ($_ -match "^(\s*)server_name\s+\S+;") {
        "$($matches[1])server_name $serverName;"
    }
    else {
        $_ # Оставляем строку неизменённой
    }
} | Set-Content $newConfigFile

Copy-Item $originalComposeFile $newComposeFile -Force

# Обновляем порт в файле docker-compose.yml
(Get-Content $newComposeFile) |
ForEach-Object {
    if ($_ -match '^(\s*)- portNum') {
        # Группа (\s*) сохраняет все ведущие пробелы
        "$($matches[1])- ${portNumber}:${portNumber}"
    }
    else {
        $_ # Оставляем остальные строки без изменений
    }
} | Set-Content $newComposeFile

# Сообщаем об успешном завершении операции
Write-Host "Конфигурация успешно обновлена!"

# Предлагают запустить сборку docker-compose
$runDockerCompose = Read-Host "Хотите запустить сборку docker-compose? (Y/N)"
if ($runDockerCompose.ToUpper() -eq "Y") {
    try {
        & docker-compose up --force-recreate --build -d
        Write-Host "Docker compose запущен успешно!"
    }
    catch {
        Write-Error "Ошибка запуска docker-compose: $($_.Exception.Message)"
    }
} else {
    Write-Host "Сборка docker-compose отменена."
}