# Execute na raiz: powershell -NoProfile -ExecutionPolicy Bypass -File .\docs\testar-tarefa5.ps1 -RemoverVolumes
param([switch]$RemoverVolumes)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$evidenceDir = Join-Path $PSScriptRoot 'evidencias/tarefa5'
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
    if ($code -ne 0) { throw "Docker falhou (codigo $code). Veja $name." }
    return $output
}

function Run-Http([string]$name, [string]$url, [string[]]$extra = @(), [string]$extension = 'json') {
    Write-Host "Testando: $url"
    $bodyPath = Join-Path $evidenceDir "$name.$extension"
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $status = & curl.exe -sS --max-time 20 -o $bodyPath -w '%{http_code}' @extra $url 2>&1
        $code = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $previousPreference
    }
    Save-Text "$name.status.txt" $status
    if ($code -ne 0 -or [string]$status -notmatch '^2\d\d$') {
        throw "Requisicao falhou ($status). Veja $name.status.txt."
    }
    return $bodyPath
}

function Wait-Health {
    $tempPath = Join-Path $evidenceDir 'aguardando-health.json'
    for ($attempt = 1; $attempt -le 30; $attempt++) {
        $previousPreference = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        try {
            $status = & curl.exe -s --max-time 2 -o $tempPath -w '%{http_code}' 'http://localhost:8080/health' 2>$null
            $code = $LASTEXITCODE
        } finally {
            $ErrorActionPreference = $previousPreference
        }
        if ($code -eq 0 -and [string]$status -eq '200') {
            $health = Get-Content -Raw -LiteralPath $tempPath | ConvertFrom-Json
            if ($health.status -eq 'ok' -and $health.banco -eq 'conectado') { return }
        }
        Start-Sleep -Seconds 2
    }
    throw 'A aplicacao nao ficou saudavel em 60 segundos.'
}

$summary = @('# TAREFA 5 - prova de persistencia', '')
Push-Location $projectRoot
try {
    Run-Docker '00-compose-up.txt' @('compose', 'up', '-d', '--build') | Out-Null
    Wait-Health

    # O teste com down -v so deve apagar os dados de exemplo e de teste.
    $initialItemsPath = Run-Http '00-itens-iniciais' 'http://localhost:8080/itens'
    $initialItems = Get-Content -Raw -LiteralPath $initialItemsPath | ConvertFrom-Json
    $allowedDescriptions = @('Garrafa termica azul', 'Carregador de notebook USB-C', 'Casaco preto com capuz', 'Oculos de grau')
    $unexpected = @($initialItems | Where-Object {
        $_.descricao -notin $allowedDescriptions -and $_.descricao -notmatch '^Teste persistencia [AB] '
    })
    if ($unexpected.Count -gt 0) {
        throw 'Existem itens fora dos exemplos e testes. Preserve esses dados antes de executar down -v.'
    }

    # 1. Dois novos cadastros com foto; depois recriacao dos conteineres.
    $statsInitialPath = Run-Http '01-estatisticas-iniciais' 'http://localhost:8080/estatisticas'
    $statsInitial = Get-Content -Raw -LiteralPath $statsInitialPath | ConvertFrom-Json
    $photoPath = Join-Path $evidenceDir 'foto-teste.png'
    $pngBase64 = 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/pXcAAAAASUVORK5CYII='
    [IO.File]::WriteAllBytes($photoPath, [Convert]::FromBase64String($pngBase64))
    $stamp = Get-Date -Format 'yyyyMMddHHmmss'
    $created = @()
    foreach ($letter in @('A', 'B')) {
        $description = "Teste persistencia $letter $stamp"
        $path = Run-Http "01-cadastro-$letter" 'http://localhost:8080/itens' @('-F', "descricao=$description", '-F', 'local=Laboratorio de teste', '-F', "foto=@$photoPath")
        $post = Get-Content -Raw -LiteralPath $path | ConvertFrom-Json
        if (-not $post.id -or -not $post.foto) { throw "Cadastro $letter nao retornou id e foto." }
        $created += [pscustomobject]@{ id = $post.id; foto = $post.foto; descricao = $description }
    }
    $created | ConvertTo-Json | Out-File -LiteralPath (Join-Path $evidenceDir '01-ids-criados.json') -Encoding utf8
    $statsBeforeRecreatePath = Run-Http '01-estatisticas-antes-down' 'http://localhost:8080/estatisticas'
    $statsBeforeRecreate = Get-Content -Raw -LiteralPath $statsBeforeRecreatePath | ConvertFrom-Json
    if ($statsBeforeRecreate.itens_no_banco -lt ($statsInitial.itens_no_banco + 2) -or
        $statsBeforeRecreate.fotos_no_volume -lt ($statsInitial.fotos_no_volume + 2)) {
        throw 'Os dois cadastros com foto nao apareceram nas estatisticas.'
    }
    Run-Docker '01-compose-down.txt' @('compose', 'down') | Out-Null
    Run-Docker '01-compose-up-novamente.txt' @('compose', 'up', '-d') | Out-Null
    Wait-Health
    $statsAfterRecreatePath = Run-Http '01-estatisticas-apos-up' 'http://localhost:8080/estatisticas'
    $statsAfterRecreate = Get-Content -Raw -LiteralPath $statsAfterRecreatePath | ConvertFrom-Json
    $itemsAfterRecreatePath = Run-Http '01-itens-apos-up' 'http://localhost:8080/itens'
    $itemsAfterRecreate = Get-Content -Raw -LiteralPath $itemsAfterRecreatePath | ConvertFrom-Json
    if ($statsAfterRecreate.itens_no_banco -ne $statsBeforeRecreate.itens_no_banco -or
        $statsAfterRecreate.fotos_no_volume -ne $statsBeforeRecreate.fotos_no_volume) {
        throw 'As contagens mudaram apos docker compose down/up.'
    }
    foreach ($item in $created) {
        $match = @($itemsAfterRecreate | Where-Object { $_.id -eq $item.id -and $_.foto -eq "/fotos/$($item.foto)" })
        if ($match.Count -ne 1) { throw "Item $($item.id) desapareceu apos a recriacao." }
        $download = Run-Http "01-foto-$($item.id)-apos-up" "http://localhost:8080/fotos/$($item.foto)" @() 'png'
        if ((Get-FileHash -LiteralPath $photoPath -Algorithm SHA256).Hash -ne
            (Get-FileHash -LiteralPath $download -Algorithm SHA256).Hash) {
            throw "Foto do item $($item.id) mudou apos a recriacao."
        }
    }
    $summary += '- PASSOU: dois itens com foto sobreviveram a docker compose down/up.'
    Save-Text 'resultado.md' $summary

    # 2. Inspecao dos volumes e do diretorio de fotos.
    Run-Http '02-estatisticas-antes-inspecao' 'http://localhost:8080/estatisticas' | Out-Null
    Run-Docker '02-docker-volume-ls.txt' @('volume', 'ls') | Out-Null
    $dbId = ((Run-Docker '02-db-container-id.txt' @('compose', 'ps', '-q', 'db')) | Out-String).Trim()
    $webId = ((Run-Docker '02-web-container-id.txt' @('compose', 'ps', '-q', 'web')) | Out-String).Trim()
    $dbMounts = ((Run-Docker '02-db-mounts.json' @('inspect', '--format', '{{json .Mounts}}', $dbId)) | Out-String) | ConvertFrom-Json
    $webMounts = ((Run-Docker '02-web-mounts.json' @('inspect', '--format', '{{json .Mounts}}', $webId)) | Out-String) | ConvertFrom-Json
    $dbVolume = @($dbMounts | Where-Object { $_.Type -eq 'volume' -and $_.Destination -eq '/var/lib/postgresql/data' })[0]
    $photoVolume = @($webMounts | Where-Object { $_.Type -eq 'volume' -and $_.Destination -eq '/app/uploads' })[0]
    if (-not $dbVolume.Name -or -not $photoVolume.Name) { throw 'Nao foi possivel identificar os dois volumes nomeados.' }
    $dbInfo = ((Run-Docker '02-inspect-dados-banco.json' @('volume', 'inspect', $dbVolume.Name)) | Out-String) | ConvertFrom-Json
    $photoInfo = ((Run-Docker '02-inspect-fotos.json' @('volume', 'inspect', $photoVolume.Name)) | Out-String) | ConvertFrom-Json
    $photoListing = @(Run-Docker '02-ls-uploads.txt' @('compose', 'exec', '-T', 'web', 'ls', '-l', '/app/uploads'))
    foreach ($item in $created) {
        if (($photoListing -join "`n") -notmatch [regex]::Escape($item.foto)) {
            throw "Foto $($item.foto) nao apareceu em /app/uploads."
        }
    }
    @(
        '# Localizacao dos volumes',
        '',
        "- Banco: $($dbVolume.Name) -> $($dbInfo.Mountpoint) -> /var/lib/postgresql/data",
        "- Fotos: $($photoVolume.Name) -> $($photoInfo.Mountpoint) -> /app/uploads",
        '',
        'No Docker Desktop, os Mountpoints pertencem ao ambiente Linux do Docker, e nao a uma pasta comum do projeto no Windows.'
    ) | Out-File -LiteralPath (Join-Path $evidenceDir '02-localizacao.md') -Encoding utf8
    $summary += '- PASSOU: volumes inspecionados e fotos listadas em /app/uploads.'
    Save-Text 'resultado.md' $summary

    # 3. A remocao dos volumes apaga os itens cadastrados e as fotos.
    if ($RemoverVolumes) {
        Run-Http '03-estatisticas-antes-remocao' 'http://localhost:8080/estatisticas' | Out-Null
        Run-Http '03-itens-antes-remocao' 'http://localhost:8080/itens' | Out-Null
        Run-Docker '03-compose-down-v.txt' @('compose', 'down', '-v') | Out-Null
        $remaining = @(Run-Docker '03-volumes-apos-down-v.txt' @('volume', 'ls', '--format', '{{.Name}}'))
        if ($remaining -contains $dbVolume.Name -or $remaining -contains $photoVolume.Name) {
            throw 'Um dos volumes ainda existe apos docker compose down -v.'
        }
        Run-Docker '03-compose-up-apos-remocao.txt' @('compose', 'up', '-d') | Out-Null
        Wait-Health
        $statsAfterRemovalPath = Run-Http '03-estatisticas-apos-remocao' 'http://localhost:8080/estatisticas'
        $statsAfterRemoval = Get-Content -Raw -LiteralPath $statsAfterRemovalPath | ConvertFrom-Json
        $itemsAfterRemovalPath = Run-Http '03-itens-apos-remocao' 'http://localhost:8080/itens'
        $itemsAfterRemoval = Get-Content -Raw -LiteralPath $itemsAfterRemovalPath | ConvertFrom-Json
        if ($statsAfterRemoval.itens_no_banco -ne 3 -or $statsAfterRemoval.fotos_no_volume -ne 0 -or $itemsAfterRemoval.Count -ne 3) {
            throw 'O novo ambiente nao retornou aos tres itens de exemplo e zero fotos.'
        }
        foreach ($item in $created) {
            if (@($itemsAfterRemoval | Where-Object { $_.descricao -eq $item.descricao }).Count -gt 0) {
                throw "O item de teste $($item.id) ainda aparece apos a remocao dos volumes."
            }
        }
        $summary += '- PASSOU: down -v apagou itens cadastrados e fotos; init.sql recriou os tres itens de exemplo.'
        $summary += '- Explicacao: down preserva volumes; down -v remove volumes nomeados. O PostgreSQL inicializa o novo volume executando init.sql.'
    } else {
        $summary += '- PENDENTE: remocao dos volumes. Execute o roteiro com -RemoverVolumes para completar a TAREFA 5.'
    }
    Save-Text 'resultado.md' $summary
    Write-Host 'Veja docs/evidencias/tarefa5/resultado.md.'
} catch {
    $summary += "- PENDENTE: $($_.Exception.Message)"
    Save-Text 'resultado.md' $summary
    Write-Host "PENDENTE: $($_.Exception.Message)"
    exit 1
} finally {
    Pop-Location
}
