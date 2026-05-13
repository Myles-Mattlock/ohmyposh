if (-Not ($Env:WT_SESSION)) {
    Write-Host "Windows Terminal is required to install this PowerShell profile" -ForegroundColor Red
    return
}

if ($PSVersionTable.PSVersion.Major -ne 7) {
    Write-Host "PowerShell 7 is required to install this PowerShell profile" -ForegroundColor Red
    return
}

if (-Not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "You must run this script as administrator" -ForegroundColor Red
    return
}

if (-Not (Test-Connection 8.8.8.8 -Count 1 -TimeoutSeconds 1 -Quiet)) { 
    Write-Host "Internet connection required to proceed" -ForegroundColor Red
    return
}

# --- Profile Setup ---
Write-Host "Setting up PowerShell Profile..." -ForegroundColor Cyan
if (Test-Path $Profile) {
    Move-Item -Path $Profile -Destination ($Profile + ".bak") -Force
} else {
    $profileDir = Split-Path $Profile
    if (-not (Test-Path $profileDir)) { New-Item -ItemType Directory -Path $profileDir -Force }
    New-Item -Path $Profile -ItemType File -Force | Out-Null
}

Invoke-WebRequest -Uri "https://github.com/Myles-Mattlock/ohmyposh/raw/main/Microsoft.PowerShell_profile.ps1" -OutFile $Profile
Write-Host "Installed PowerShell Profile" -ForegroundColor Green

$themePath = Join-Path (Split-Path $Profile) "myles.omp.json"
Invoke-WebRequest -Uri "https://github.com/Myles-Mattlock/ohmyposh/raw/main/myles.omp.json" -OutFile $themePath
Write-Host "Installed oh-my-posh theme" -ForegroundColor Green

# --- Font Installation (Silent Overwrite) ---
Write-Host "Downloading and installing fonts..." -ForegroundColor Cyan

$zipUrl = "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaMono.zip"
$zipFile = "CascadiaMono.zip"
$tempFolder = "CascadiaMono_Temp"

Invoke-WebRequest -Uri $zipUrl -OutFile $zipFile
if (Test-Path $tempFolder) { Remove-Item $tempFolder -Recurse -Force }
Expand-Archive -Path $zipFile -DestinationPath $tempFolder -Force

$FontFolder = Join-Path $env:windir "Fonts"
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"

Get-ChildItem $tempFolder -Filter *.ttf -Recurse | ForEach-Object {
    $DestinationPath = Join-Path $FontFolder $_.Name
    
    try {
        # Delete first to prevent the Windows 'Replace' popup
        if (Test-Path $DestinationPath) {
            Remove-Item $DestinationPath -Force -ErrorAction Stop
        }
        
        Copy-Item $_.FullName -Destination $DestinationPath -Force
        
        # Register in Registry
        $FontName = $_.BaseName
        New-ItemProperty -Path $RegPath -Name "$FontName (TrueType)" -Value $_.Name -PropertyType String -Force | Out-Null
        
        Write-Host "Successfully installed: $($_.Name)" -ForegroundColor Gray
    }
    catch {
        Write-Host "Skipped: $($_.Name) (File is currently in use by Windows)" -ForegroundColor Yellow
    }
}

# Cleanup
Remove-Item -Path $zipFile -Force
Remove-Item -Path $tempFolder -Recurse -Force

# --- Dependencies ---
Write-Host "Installing dependencies..." -ForegroundColor Cyan

Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ErrorAction SilentlyContinue | Out-Null
Install-Module -Name Terminal-Icons -Force -AllowClobber -Scope CurrentUser

Write-Host "Installing Oh My Posh via WinGet..."
winget install JanDeDobbeleer.OhMyPosh --source winget --silent --accept-source-agreements --accept-package-agreements

Write-Host "`nInstallation Complete!" -ForegroundColor Green
Write-Host "Note: If any fonts were skipped, close all Terminal windows and run again." -ForegroundColor Yellow
