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
if (Test-Path $Profile) {
    Move-Item -Path $Profile -Destination ($Profile + ".bak") -Force
} else {
    $profileDir = Split-Path $Profile
    if (-not (Test-Path $profileDir)) { New-Item -ItemType Directory -Path $profileDir -Force }
    New-Item -Path $Profile -ItemType File -Force | Out-Null
}

Invoke-WebRequest -Uri "https://github.com/Myles-Mattlock/ohmyposh/raw/main/Microsoft.PowerShell_profile.ps1" -OutFile $Profile
Write-Host "Installed PowerShell Profile" -ForegroundColor Green

# Use the directory of the profile for the JSON theme
$themePath = Join-Path (Split-Path $Profile) "myles.omp.json"
Invoke-WebRequest -Uri "https://github.com/Myles-Mattlock/ohmyposh/raw/main/myles.omp.json" -OutFile $themePath
Write-Host "Installed oh-my-posh theme" -ForegroundColor Green

# --- Font Installation ---
Write-Host "Installing fonts (overwriting if exists)..." -ForegroundColor Cyan

Invoke-WebRequest -Uri "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaMono.zip" -OutFile "CascadiaMono.zip"
Expand-Archive -Path "CascadiaMono.zip" -DestinationPath "CascadiaMono" -Force

$shellApp = New-Object -ComObject Shell.Application
$fontsFolder = $shellApp.Namespace(0x14)

Get-ChildItem CascadiaMono -Filter *.ttf -Recurse | ForEach-Object {
    try {
        # Flag 20 = 16 (Yes to all/Overwrite) + 4 (No progress UI)
        $fontsFolder.CopyHere($_.FullName, 20)
        Write-Host "Successfully installed: $($_.Name)" -ForegroundColor Gray
    } catch {
        Write-Host "Failed to install $($_.Name). It may be in use." -ForegroundColor Yellow
    }
}

# Cleanup zip and temp folder
Remove-Item -Path "CascadiaMono.zip" -Force
Remove-Item -Path "CascadiaMono" -Recurse -Force

# --- Dependencies ---
Write-Host "Installing dependencies..." -ForegroundColor Cyan

Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -ErrorAction SilentlyContinue | Out-Null
Install-Module -Name Terminal-Icons -Force -AllowClobber -Scope CurrentUser

# Winget install for OhMyPosh
Write-Host "Installing Oh My Posh via WinGet..."
winget install JanDeDobbeleer.OhMyPosh --source winget --silent --accept-source-agreements --accept-package-agreements

Write-Host "Installation Complete! Restart Windows Terminal to see changes." -ForegroundColor Green
