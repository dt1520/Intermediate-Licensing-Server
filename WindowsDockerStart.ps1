# ��������� ��������� �������
$OutputEncoding = [System.Text.Encoding]::UTF8

# ���������� ��� ������ � ������
$originalConfigFile = ".\conf_main\default.conf"
$newConfigDir = ".\conf"
$newConfigFile = Join-Path $newConfigDir "default.conf"
$originalComposeFile = ".\docker-compose.template.yml"
$newComposeFile = ".\docker-compose.yml"

# ��������� ������������� ������������ ������
if (-not(Test-Path $originalConfigFile)) {
    Write-Host "������: ���� '$originalConfigFile' �� ������."
    exit
}

if (-not(Test-Path $originalComposeFile)) {
    Write-Host "������: ���� '$originalComposeFile' �� ������."
    exit
}

# ����������� ����� �������� server_name � �����
$serverName = Read-Host "������� ������ �������� ����� ������-������� (��������, your-proxy-domain.example.com)"
$portNumber = Read-Host "������� ����� ����� (��������, 80 ��� 443)"

# ������������� �������� ������
Write-Host "��� ������-������ ����� �������� ��������� �������:"
Write-Host "�������� ���: $serverName"
Write-Host "����: $portNumber"

# ������ ����������� ���������
$confirmation = Read-Host "����������� ���������? (Y/N)"
if ($confirmation.ToUpper() -ne "Y") {
    Write-Host "������ ���������."
    exit
}

# ������ ���������� ��������, ���� � ���
if (-not(Test-Path $newConfigDir)) {
    New-Item -ItemType Directory -Path $newConfigDir | Out-Null
}

# �������� �������� � ����� �������
Copy-Item $originalConfigFile $newConfigFile -Force

# ��������� ���� server_name � listen � ������������� ����� ������������ Nginx
(Get-Content $newConfigFile) |
ForEach-Object {
    if ($_ -match "^(\s*)listen\s+\S+;") {
        "$($matches[1])listen $portNumber;"
    }
    elseif ($_ -match "^(\s*)server_name\s+\S+;") {
        "$($matches[1])server_name $serverName;"
    }
    else {
        $_ # ��������� ������ �����������
    }
} | Set-Content $newConfigFile

Copy-Item $originalComposeFile $newComposeFile -Force

# ��������� ���� � ����� docker-compose.yml
(Get-Content $newComposeFile) |
ForEach-Object {
    if ($_ -match '^(\s*)- portNum') {
        # ������ (\s*) ��������� ��� ������� �������
        "$($matches[1])- ${portNumber}:${portNumber}"
    }
    else {
        $_ # ��������� ��������� ������ ��� ���������
    }
} | Set-Content $newComposeFile

# �������� �� �������� ���������� ��������
Write-Host "������������ ������� ���������!"

# ���������� ��������� ������ docker-compose
$runDockerCompose = Read-Host "������ ��������� ������ docker-compose? (Y/N)"
if ($runDockerCompose.ToUpper() -eq "Y") {
    try {
        & docker-compose up --force-recreate --build -d
        Write-Host "Docker compose ������� �������!"
    }
    catch {
        Write-Error "������ ������� docker-compose: $($_.Exception.Message)"
    }
} else {
    Write-Host "������ docker-compose ��������."
}