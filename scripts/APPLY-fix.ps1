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
    Write-Host ''
    Write-Host '  IMPORTANT: programs that are already running keep the old component loaded.'
    Write-Host '  Explorer (taskbar + file windows) runs all the time, so it MUST be restarted.'
    Write-Host '  Other open apps (browser, Office...) need a restart for THEIR file pickers.'
    Write-Host '  Restarting the PC or signing out covers everything.'
    Write-Host ''
    $a = Read-Host '  Restart Windows Explorer now? Taskbar disappears for ~3 seconds (Y/N)'
    if ($a -match '^[Yy]') {
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 3
        if (-not (Get-Process explorer -ErrorAction SilentlyContinue)) { Start-Process explorer.exe }
        Write-Host '  [OK] Explorer restarted.' -ForegroundColor Green
    } else {
        Write-Host '  Skipped. Restart Explorer (Task Manager > Windows Explorer > Restart) or the PC later.' -ForegroundColor Yellow
    }
    Write-Host '  Undo any time with UNDO-fix.bat'
} catch {
    Write-Host "  [ERROR] $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
