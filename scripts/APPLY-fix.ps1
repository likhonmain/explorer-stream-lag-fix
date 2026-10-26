# APPLY-fix.ps1
# Stops Windows File Explorer / Open-Save file dialogs from freezing your network
# (lag spikes, stream stutter, "slow connection" warnings).
#
# What it does: blocks, for the CURRENT USER ONLY, the shell folder
#   {289AF617-1CC3-42A6-926C-E6A863F0E3BA}  "DLNA Media Servers Data Source"
# which Explorer loads under "This PC" every time a window or file picker opens.
#
# Registry value written:
#   HKCU\Software\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked
#     {289AF617-1CC3-42A6-926C-E6A863F0E3BA} = "DLNA Media Servers Data Source (...)"
#
# No admin rights. No services, drivers, network settings or files are changed.
# Fully reversible with UNDO-fix.ps1 / UNDO-fix.bat.

$ErrorActionPreference = 'Stop'
$bk = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked'
$id = '{289AF617-1CC3-42A6-926C-E6A863F0E3BA}'

try {
    if (-not (Test-Path $bk)) { New-Item -Path $bk -Force | Out-Null }
    New-ItemProperty -Path $bk -Name $id `
        -Value 'DLNA Media Servers Data Source (blocked by ExplorerStreamLagFix)' `
        -PropertyType String -Force | Out-Null
    Write-Host '  [OK] Fix applied.' -ForegroundColor Green
    Write-Host '  New Explorer windows and file dialogs use it immediately.'
    Write-Host '  For already-open apps, restart them (or sign out / restart Explorer).'
    Write-Host '  Undo any time with UNDO-fix.bat'
} catch {
    Write-Host "  [ERROR] $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
