$ErrorActionPreference = 'Continue'
$pastaProjeto = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$pastaEvidencias = Join-Path $PSScriptRoot 'evidencias\tarefa6'
New-Item -ItemType Directory -Path $pastaEvidencias -Force | Out-Null
Push-Location $pastaProjeto

try {
    & docker info --format '{{.ServerVersion}}' *> $null
    if ($LASTEXITCODE -ne 0) { throw 'Docker Desktop indisponivel. Inicie o Docker e execute novamente.' }

    & docker compose up -d --build 2>&1 | Out-File -FilePath (Join-Path $pastaEvidencias '01-compose-up.txt') -Encoding utf8
    if ($LASTEXITCODE -ne 0) { throw 'Falha ao subir o ambiente. Consulte 01-compose-up.txt.' }

    $webIds = @(& docker compose ps -q web)
    $webId = $webIds[0]
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($webId)) { throw 'Container web nao encontrado.' }

    $nomesRede = @(& docker inspect --format '{{range $name, $network := .NetworkSettings.Networks}}{{println $name}}{{end}}' $webId)
    $nomeRede = $nomesRede[0].Trim()
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($nomeRede)) { throw 'Rede do container web nao encontrada.' }
    if ($nomeRede -notmatch 'rede_interna$') { throw "Rede inesperada: $nomeRede" }

    & docker network inspect $nomeRede 2>&1 | Out-File -FilePath (Join-Path $pastaEvidencias '02-docker-network-inspect.json') -Encoding utf8
    if ($LASTEXITCODE -ne 0) { throw 'Falha em docker network inspect.' }

    & docker image ls 2>&1 | Out-File -FilePath (Join-Path $pastaEvidencias '03-docker-image-ls.txt') -Encoding utf8
    if ($LASTEXITCODE -ne 0) { throw 'Falha em docker image ls.' }

    & docker compose images web 2>&1 | Out-File -FilePath (Join-Path $pastaEvidencias '04-compose-images-web.txt') -Encoding utf8
    if ($LASTEXITCODE -ne 0) { throw 'Falha ao identificar a imagem web.' }

    try {
        & docker compose up -d --scale web=3 2>&1 | Out-File -FilePath (Join-Path $pastaEvidencias '05-scale-web-3.txt') -Encoding utf8
        $codigoEscala = $LASTEXITCODE
    }
    finally {
        & docker compose up -d --scale web=1 2>&1 | Out-File -FilePath (Join-Path $pastaEvidencias '06-restaurar-web-1.txt') -Encoding utf8
        if ($LASTEXITCODE -ne 0) { Write-Warning 'Falha ao restaurar uma replica; confira docker compose ps.' }
    }

    & docker compose ps 2>&1 | Out-File -FilePath (Join-Path $pastaEvidencias '07-compose-ps-final.txt') -Encoding utf8
    if ($LASTEXITCODE -ne 0) { throw 'Falha ao consultar docker compose ps.' }

    & docker compose exec -T web whoami 2>&1 | Out-File -FilePath (Join-Path $pastaEvidencias '08-whoami.txt') -Encoding utf8
    if ($LASTEXITCODE -ne 0) { throw 'Falha ao consultar o usuario do container web.' }

    $resultado = @"
# TAREFA 6 - evidencias adicionais

| Evidencia | Legenda |
| --- | --- |
| [01-compose-up.txt](01-compose-up.txt) | Subida do ambiente antes da inspecao. |
| [02-docker-network-inspect.json](02-docker-network-inspect.json) | Inspecao da rede interna e dos conteineres conectados. |
| [03-docker-image-ls.txt](03-docker-image-ls.txt) | Lista de imagens do Docker com a coluna de tamanho. |
| [04-compose-images-web.txt](04-compose-images-web.txt) | Identificacao da imagem construida para o servico web. |
| [05-scale-web-3.txt](05-scale-web-3.txt) | Saida real da tentativa de tres replicas de web; codigo de saida: $codigoEscala. |
| [06-restaurar-web-1.txt](06-restaurar-web-1.txt) | Retorno do servico web a configuracao de uma replica. |
| [07-compose-ps-final.txt](07-compose-ps-final.txt) | Estado final dos servicos depois da tentativa de escala. |
| [08-whoami.txt](08-whoami.txt) | Usuario da aplicacao dentro do container web. |
"@
    Set-Content -LiteralPath (Join-Path $pastaEvidencias 'resultado.md') -Value $resultado -Encoding utf8
    Write-Host "Evidencias salvas em $pastaEvidencias"
    Write-Host "Tentativa de escala: codigo de saida $codigoEscala"
}
finally {
    Pop-Location
}
