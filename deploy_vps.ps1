param(
    [Parameter(Mandatory = $true)]
    [string]$Target  # Format: user@ip_address
)

$RemotePath = "~/gym_app"
$Branch = "test/ui-overhaul"
$ComposeFile = "infra/docker-compose.prod.yml"

Write-Host "🚀 Iniciando despliegue en $Target..." -ForegroundColor Cyan

# 1. Update Code
Write-Host "📥 Actualizando código desde github ($Branch)..." -ForegroundColor Yellow
ssh $Target "cd $RemotePath && git fetch && git checkout $Branch && git pull origin $Branch"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Error actualizando el código. Verifica la conexión y el path." -ForegroundColor Red
    exit 1
}

# 2. Rebuild and Restart
Write-Host "🐳 Reconstruyendo contenedores Docker..." -ForegroundColor Yellow
ssh $Target "cd $RemotePath && docker compose -f $ComposeFile up -d --build"

if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Error en Docker Compose." -ForegroundColor Red
    exit 1
}

# 3. Clean up (Optional Prune)
# ssh $Target "docker image prune -f"

Write-Host "✅ ¡Despliegue Finalizado con Éxito!" -ForegroundColor Green
