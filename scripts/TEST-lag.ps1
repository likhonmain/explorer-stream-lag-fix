# TEST-lag.ps1
# Read-only diagnostic. Pings your default gateway (router) while a separate process
# enumerates "This PC" - exactly what File Explorer and every Open/Save dialog do.
# If the max ping jumps to hundreds of ms, you have this problem.
# Changes nothing on your system.

$ErrorActionPreference = 'SilentlyContinue'
$gw = (Get-NetRoute -DestinationPrefix '0.0.0.0/0' | Sort-Object RouteMetric | Select-Object -First 1).NextHop
if (-not $gw) { Write-Host '  No default gateway found (are you connected?).' -ForegroundColor Red; exit 1 }

$bk = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Shell Extensions\Blocked'
$fixed = (Test-Path $bk) -and ((Get-Item $bk).GetValueNames() -contains '{289AF617-1CC3-42A6-926C-E6A863F0E3BA}')
Write-Host ("  Router: {0}    Fix currently applied: {1}" -f $gw, $fixed)

function Measure-Ping([string]$label, [bool]$enumerate) {
    $job = Start-Job -ArgumentList $gw { param($g) ping.exe -n 12 -w 1000 $g }
    Start-Sleep -Milliseconds 1500
    if ($enumerate) {
        # fresh process each time, so nothing is cached
        Start-Process powershell.exe -WindowStyle Hidden -Wait -ArgumentList '-NoProfile', '-Command',
            '@((New-Object -ComObject Shell.Application).Namespace(17).Items()).Count | Out-Null'
    }
    $out = $job | Wait-Job | Receive-Job; $job | Remove-Job
    $ms = $out | ForEach-Object { if ($_ -match '[=<](\d+)ms') { [int]$matches[1] } elseif ($_ -match 'timed out|unreachable') { 999 } }
    $max = ($ms | Measure-Object -Maximum).Maximum
    $color = if ($max -ge 150) { 'Red' } elseif ($max -ge 60) { 'Yellow' } else { 'Green' }
    Write-Host ("  {0,-28} max {1,4} ms  | {2}" -f $label, $max, ($ms -join ' ')) -ForegroundColor $color
    return $max
}

Write-Host ''
$base = Measure-Ping 'Idle (baseline)' $false
$test = Measure-Ping 'While loading "This PC"' $true
Write-Host ''
if ($test -ge 150 -and $test -gt ($base * 3)) {
    if ($fixed) { Write-Host '  Spike still present with the fix applied - your cause may be different (see README).' -ForegroundColor Yellow }
    else        { Write-Host '  Spike detected. You likely have this problem - run APPLY-fix.bat' -ForegroundColor Red }
} else {
    Write-Host '  No significant spike detected.' -ForegroundColor Green
}
Write-Host '  (Wi-Fi results vary; run it 2-3 times for a reliable picture.)'
