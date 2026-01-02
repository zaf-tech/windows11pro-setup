# Replace the default LogPath in param() with a safer default:
# [string]$LogPath = "$env:ProgramData\DevWorkstationSetup\setup.log"
# -> change to:
# [string]$LogPath = "$env:Public\DevWorkstationSetup\setup.log"

function Initialize-Logging {
  # Preferred locations in order (first writable wins)
  $candidates = @(
    $LogPath, # user-specified or default
    (Join-Path $env:Public "DevWorkstationSetup\setup.log"),
    (Join-Path $env:TEMP   "DevWorkstationSetup-setup.log")
  )

  foreach ($candidate in $candidates) {
    try {
      $dir = Split-Path -Parent $candidate
      if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
      }

      # Test write
      "[$(Get-Date -Format o)] Starting setup" | Out-File -FilePath $candidate -Encoding UTF8 -Append -ErrorAction Stop

      # If successful, lock-in the chosen path
      $script:LogPath = $candidate
      Write-Host "Logging to: $script:LogPath" -ForegroundColor Cyan
      return
    } catch {
      # try next candidate
    }
  }

  throw "Unable to create a log file in any candidate location. Check folder permissions / Controlled Folder Access."
}

function Write-Log {
  param(
    [Parameter(Mandatory)][string]$Message,
    [ValidateSet("INFO","WARN","ERROR","OK")][string]$Level = "INFO"
  )

  $line = "[$(Get-Date -Format o)] [$Level] $Message"

  # Console output always
  switch ($Level) {
    "OK"    { Write-Host $Message -ForegroundColor Green }
    "WARN"  { Write-Host $Message -ForegroundColor Yellow }
    "ERROR" { Write-Host $Message -ForegroundColor Red }
    default { Write-Host $Message }
  }

  # File output best-effort (don’t crash setup if log write fails later)
  try {
    if ($script:LogPath) {
      $line | Out-File -FilePath $script:LogPath -Encoding UTF8 -Append -ErrorAction Stop
    }
  } catch {
    # If logging breaks mid-run, keep going but warn once
    if (-not $script:LoggingWriteFailed) {
      $script:LoggingWriteFailed = $true
      Write-Host "WARN: Unable to write to log file ($script:LogPath). Continuing without file logging." -ForegroundColor Yellow
    }
  }
}