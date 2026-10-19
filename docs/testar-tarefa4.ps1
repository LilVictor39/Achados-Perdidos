# Execute na raiz do projeto: powershell -NoProfile -ExecutionPolicy Bypass -File .\docs\testar-tarefa4.ps1
param([switch]$ApenasLogs)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$evidenceDir = Join-Path $PSScriptRoot 'evidencias/tarefa4'
New-Item -ItemType Directory -Force -Path $evidenceDir | Out-Null

function Save-Text([string]$name, [object]$value) {
    $value | Out-File -LiteralPath (Join-Path $evidenceDir $name) -Encoding utf8
}

function Run-Docker([string]$name, [string[]]$arguments) {
    Write-Host "Executando: docker $($arguments -join ' ')"
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = @()
        & docker @arguments 2>&1 | ForEach-Object { $_.ToString() } | Tee-Object -Variable output | Out-Host
        $code = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousPreference
    }
    Save-Text $name $output
    if ($code -ne 0) { throw "docker $($arguments -join ' ') falhou (codigo $code). Veja $name." }
    return $output
}

function Run-Http([string]$name, [string]$url, [string[]]$extra = @(), [string]$extension = 'json') {
    Write-Host "Testando: $url"
    $bodyPath = Join-Path $evidenceDir "$name.$extension"
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $status = & curl.exe -sS -o $bodyPath -w '%{http_code}' @extra $url 2>&1
        $code = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousPreference
    }
    Save-Text "$name.status.txt" $status
    if ($code -ne 0) { throw "curl falhou em $url (codigo $code)." }
    if ([string]$status -notmatch '^2\d\d$') { throw "HTTP $status em $url. Veja $name.$extension." }
    return $bodyPath
}

if ($ApenasLogs) {
    Push-Location $projectRoot
    try {
        if (-not (Test-Path -LiteralPath (Join-Path $evidenceDir '09-estatisticas.json'))) {
            throw 'As evidencias dos testes HTTP ainda nao existem.'
        }
        Run-Docker '10-logs-web.txt' @('compose', 'logs', 'web', '--tail', '20') | Out-Null
        if ((Get-Item -LiteralPath (Join-Path $evidenceDir '10-logs-web.txt')).Length -eq 0) {
            throw 'O arquivo de logs veio vazio.'
        }
        $previous = Get-Content -LiteralPath (Join-Path $evidenceDir 'resultado.md')
        $updated = @($previous | Where-Object {
            $_ -notmatch '^- PENDENTE: registrar docker compose logs' -and
            $_ -notmatch '^- O roteiro PowerShell foi corrigido' -and
            $_ -notmatch '^- PASSOU: logs da aplicacao'
        })
        $updated += '- PASSOU: logs da aplicacao registrados (10).'
        Save-Text 'resultado.md' $updated
        Write-Host 'TAREFA 4 concluida. Veja docs/evidencias/tarefa4/resultado.md.'
    } catch {
        Write-Host "PENDENTE: $($_.Exception.Message)"
        exit 1
    } finally {
        Pop-Location
    }
    exit 0
}

$summary = @('# TAREFA 4 - testes funcionais', '')
Push-Location $projectRoot
try {
    Run-Docker '01-compose-up.txt' @('compose', 'up', '-d', '--build') | Out-Null
    Run-Docker '02-compose-ps.txt' @('compose', 'ps') | Out-Null
    $running = @(Run-Docker '02-servicos-running.txt' @('compose', 'ps', '--status', 'running', '--services'))
    if ($running -notcontains 'db' -or $running -notcontains 'web') { throw 'Os servicos db e web nao estao ambos em execucao.' }

    $healthPath = Run-Http '03-health' 'http://localhost:8080/health'
    $health = Get-Content -Raw -LiteralPath $healthPath | ConvertFrom-Json
    if ($health.status -ne 'ok' -or $health.banco -ne 'conectado') { throw 'GET /health nao confirmou a conexao com o banco.' }

    $itemsPath = Run-Http '04-itens' 'http://localhost:8080/itens'
    $itemsBefore = Get-Content -Raw -LiteralPath $itemsPath | ConvertFrom-Json
    if ($itemsBefore.Count -lt 3) { throw 'GET /itens retornou menos de tres objetos.' }

    $filterPath = Run-Http '05-filtro-biblio' 'http://localhost:8080/itens?local=biblio'
    $filtered = Get-Content -Raw -LiteralPath $filterPath | ConvertFrom-Json
    if ($filtered.Count -lt 1 -or @($filtered | Where-Object { $_.local -notmatch 'biblio' }).Count -gt 0) {
        throw 'O filtro por local nao retornou apenas objetos da Biblioteca.'
    }

    $photoPath = Join-Path $evidenceDir 'foto-teste.png'
    $pngBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/pXcAAAAASUVORK5CYII='
    [IO.File]::WriteAllBytes($photoPath, [Convert]::FromBase64String($pngBase64))
    $postPath = Run-Http '06-cadastro' 'http://localhost:8080/itens' @('-F', 'descricao=Oculos de grau', '-F', 'local=Bloco B', '-F', "foto=@$photoPath")
    $post = Get-Content -Raw -LiteralPath $postPath | ConvertFrom-Json
    if (-not $post.id -or -not $post.foto) { throw 'POST /itens nao retornou id e nome da foto.' }

    $itemsAfterPath = Run-Http '07-itens-apos-cadastro' 'http://localhost:8080/itens'
    $itemsAfter = Get-Content -Raw -LiteralPath $itemsAfterPath | ConvertFrom-Json
    $newItem = @($itemsAfter | Where-Object { $_.id -eq $post.id })
    if ($newItem.Count -ne 1 -or $newItem[0].foto -ne "/fotos/$($post.foto)") {
        throw 'O item cadastrado ou a URL da foto nao apareceu em GET /itens.'
    }

    $photoUrl = "http://localhost:8080$($newItem[0].foto)"
    $downloadPath = Run-Http '08-foto-baixada' $photoUrl @() 'png'
    if ((Get-FileHash -LiteralPath $photoPath -Algorithm SHA256).Hash -ne (Get-FileHash -LiteralPath $downloadPath -Algorithm SHA256).Hash) {
        throw 'A foto baixada e diferente da foto enviada.'
    }

    $statsPath = Run-Http '09-estatisticas' 'http://localhost:8080/estatisticas'
    $stats = Get-Content -Raw -LiteralPath $statsPath | ConvertFrom-Json
    if ($stats.itens_no_banco -lt ($itemsBefore.Count + 1) -or $stats.fotos_no_volume -lt 1) {
        throw 'As estatisticas nao refletem o novo item e a foto.'
    }

    Run-Docker '10-logs-web.txt' @('compose', 'logs', 'web', '--tail', '20') | Out-Null
    $summary += '- PASSOU: dois servicos em execucao; banco acessivel por /health.'
    $summary += '- PASSOU: listagem, filtro por local e cadastro com foto.'
    $summary += '- PASSOU: foto acessivel e identica ao arquivo enviado.'
    $summary += "- PASSOU: estatisticas ($($stats.itens_no_banco) itens; $($stats.fotos_no_volume) fotos)."
    $summary += '- Saidas e respostas: arquivos numerados nesta pasta.'
} catch {
    $summary += "- PENDENTE: $($_.Exception.Message)"
    $summary += '- Os testes seguintes nao foram executados depois dessa falha.'
    Save-Text 'resultado.md' $summary
    Write-Output "PENDENTE: $($_.Exception.Message)"
    exit 1
} finally {
    Pop-Location
}
Save-Text 'resultado.md' $summary
Write-Output 'TAREFA 4 concluida. Evidencias em docs/evidencias/tarefa4/resultado.md.'
