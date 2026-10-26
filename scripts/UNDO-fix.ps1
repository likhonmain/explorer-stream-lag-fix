# UNDO-fix.ps1
# Reverts APPLY-fix.ps1: removes the per-user block of the
# "DLNA Media Servers Data Source" shell folder, restoring default Windows behavior.
# No admin rights needed.

$ErrorActionPreference = 'Stop'
$bk = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked'
$id = '{289AF617-1CC3-42A6-926C-E6A863F0E3BA}'

try {
    if ((Test-Path $bk) -and ((Get-Item $bk).GetValueNames() -contains $id)) {
        Remove-ItemProperty -Path $bk -Name $id
        # Remove the Blocked key only if it is now empty (it does not exist by default).
        $k = Get-Item $bk
        if ($k.ValueCount -eq 0 -and $k.SubKeyCount -eq 0) { Remove-Item $bk }
        Write-Host '  [OK] Fix removed. Windows default behavior restored.' -ForegroundColor Green
        Write-Host '  Restart open apps (or sign out / restart Explorer) to be sure.'
    } else {
        Write-Host '  [OK] Fix was not applied - nothing to undo.' -ForegroundColor Yellow
    }
} catch {
    Write-Host "  [ERROR] $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
