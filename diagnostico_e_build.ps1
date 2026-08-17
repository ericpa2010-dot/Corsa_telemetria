Clear-Host
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "   DIAGNOSTICO E AUTOMACAO DE BUILD DO APK (CORSA)  " -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[1/5] Testando instalacao do Git..." -ForegroundColor Yellow
try {
    $gitVersion = git --version
    Write-Host " -> Sucesso: $gitVersion" -ForegroundColor Green
} catch {
    Write-Host " -> ERRO CRITICO: O Git nao foi encontrado no PATH!" -ForegroundColor Red
    Read-Host "Pressione ENTER para sair"
    exit
}

Write-Host ""
Write-Host "[2/5] Verificando arquivos do projeto..." -ForegroundColor Yellow
if (Test-Path "pubspec.yaml") {
    Write-Host " -> Arquivo pubspec.yaml encontrado!" -ForegroundColor Green
} else {
    Write-Host " -> AVISO: pubspec.yaml nao localizado na pasta atual." -ForegroundColor Red
}

Write-Host ""
Write-Host "[3/5] Configurando repositorio local..." -ForegroundColor Yellow
if (-not (Test-Path ".git")) {
    git init
    git branch -M main
}

git remote remove origin 2>$null
git remote add origin https://github.com/ericpa2010-dot/Corsa_telemetria.git
Write-Host " -> Repositorio vinculado!" -ForegroundColor Green

Write-Host ""
Write-Host "[4/5] Adicionando arquivos e preparando o commit..." -ForegroundColor Yellow
git add .
git commit -m "Auto-build via script PowerShell" 2>$null

Write-Host ""
Write-Host "[5/5] Subindo arquivos para o GitHub..." -ForegroundColor Yellow
$pushResult = git push -u origin main --force 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "===================================================" -ForegroundColor Green
    Write-Host "   ARQUIVOS ENVIADOS COM SUCESSO AO GITHUB!        " -ForegroundColor Green
    Write-Host "===================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Abrindo a aba do GitHub Actions..." -ForegroundColor Cyan
    Start-Process "https://github.com/ericpa2010-dot/Corsa_telemetria/actions"
} else {
    Write-Host ""
    Write-Host "===================================================" -ForegroundColor Red
    Write-Host "   FALHA NO ENVIO PARA O GITHUB                    " -ForegroundColor Red
    Write-Host "===================================================" -ForegroundColor Red
    Write-Host $pushResult -ForegroundColor Yellow
}
