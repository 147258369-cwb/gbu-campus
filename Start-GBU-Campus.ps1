$ErrorActionPreference = 'Stop'
$campusRoot = $PSScriptRoot
[int]$campusPort = 5190
if ($null -ne $env:PORT) {
  if (-not [int]::TryParse($env:PORT, [ref]$campusPort) -or $campusPort -lt 1 -or $campusPort -gt 65535) {
    throw 'PORT must be an integer from 1 to 65535.'
  }
}
$env:PORT = [string]$campusPort
$campusUrl = 'http://127.0.0.1:{0}/' -f $campusPort
$campusNode = Join-Path $env:USERPROFILE '.cache\codex-runtimes\codex-primary-runtime\dependencies\node\bin\node.exe'
if (-not (Test-Path -LiteralPath $campusNode)) { $campusNode = (Get-Command node -ErrorAction Stop).Source }
try { $campusResponse = Invoke-WebRequest -Uri $campusUrl -TimeoutSec 2 -UseBasicParsing } catch { $campusResponse = $null }
if ($campusResponse -and $campusResponse.Content -notmatch 'GBU Campus') { throw "Port $campusPort is used by another app. Close that app or choose a different PORT before launching the campus." }
if (-not $campusResponse) {
  $env:HOST = '127.0.0.1'
  Start-Process -FilePath $campusNode -ArgumentList ('"' + (Join-Path $campusRoot 'server.mjs') + '"') -WorkingDirectory $campusRoot -WindowStyle Hidden
  for ($campusAttempt=0; $campusAttempt -lt 20; $campusAttempt++) {
    Start-Sleep -Milliseconds 250
    try { $campusResponse=Invoke-WebRequest -Uri $campusUrl -TimeoutSec 1 -UseBasicParsing; break } catch {}
  }
}
if (-not $campusResponse) { throw 'The campus could not start. Check that the dist directory is present.' }
Start-Process $campusUrl
