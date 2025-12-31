param(
    [Parameter(Mandatory = $true)]
    [string]$Target,  # Format: user@ip_address or host alias

    [Parameter(Mandatory = $false)]
    [string]$Branch = "main"
)

$RemotePath = "/root/gym-app"
$ComposeFile = "infra/docker-compose.prod.yml"
$EnvFile = ".env.prod"

Write-Host "Starting deployment to $Target on branch $Branch..." -ForegroundColor Cyan

# 1. Update Code
Write-Host "Updating code from GitHub..." -ForegroundColor Yellow
$updateCmd = "cd $RemotePath && git fetch origin && git checkout $Branch && git pull origin $Branch"
ssh $Target $updateCmd

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error updating code. Check connection and path." -ForegroundColor Red
    exit 1
}

# 2. Rebuild and Restart
Write-Host "Rebuilding Docker containers..." -ForegroundColor Yellow
# Ensure we use the prod env file and prod compose file
$deployCmd = "cd $RemotePath && docker compose --env-file $EnvFile -f $ComposeFile up -d --build"
ssh $Target $deployCmd

if ($LASTEXITCODE -ne 0) {
    Write-Host "Error in Docker Compose." -ForegroundColor Red
    exit 1
}

# 3. Clean up (Optional)
# ssh $Target "docker image prune -f"

Write-Host "Deployment Completed Successfully!" -ForegroundColor Green
