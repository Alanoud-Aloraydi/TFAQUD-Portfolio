# Runs every check .github/workflows/ci.yml runs, in the same order, so a
# red build is found here instead of on GitHub. Usage, from anywhere:
#
#   powershell -ExecutionPolicy Bypass -File ci.ps1
#   .\ci.ps1 -App         only the app job
#   .\ci.ps1 -Backend     only the backend job
#   .\ci.ps1 -Fix         format and fix instead of only reporting
#
# Close the watcher window first (tool\watch.bat). Two processes writing the
# same files is what makes "file is being used by another process".

[CmdletBinding()]
param(
  [switch]$App,
  [switch]$Backend,
  [switch]$Fix
)

$ErrorActionPreference = 'Continue'
$root = $PSScriptRoot
$results = [ordered]@{}
$failed = $false

function Step {
  param([string]$Name, [string]$Dir, [scriptblock]$Body)
  if ($script:failed) { $script:results[$Name] = 'skipped'; return }
  Write-Host ''
  Write-Host "=== $Name" -ForegroundColor Cyan
  Push-Location (Join-Path $root $Dir)
  try { & $Body } finally { Pop-Location }
  if ($LASTEXITCODE -ne 0) {
    $script:results[$Name] = 'FAILED'
    $script:failed = $true
    Write-Host "--- $Name FAILED (exit $LASTEXITCODE)" -ForegroundColor Red
  } else {
    $script:results[$Name] = 'passed'
  }
}

function Skip { param([string]$Name, [string]$Why)
  $script:results[$Name] = "skipped - $Why"
  Write-Host "=== $Name skipped - $Why" -ForegroundColor Yellow
}

if (-not $App -and -not $Backend) { $App = $true; $Backend = $true }

# ---------------------------------------------------------------- app job
if ($App) {
  if (-not (Test-Path (Join-Path $root 'app\.env'))) {
    Copy-Item (Join-Path $root 'app\.env.example') (Join-Path $root 'app\.env')
    Write-Host 'made app\.env from .env.example'
  }
  Step 'app: packages' 'app' { flutter pub get }
  if ($Fix) {
    Step 'app: format (rewriting)' 'app' { dart format lib test }
    Step 'app: dart fix' 'app' { dart fix --apply }
  } else {
    Step 'app: format' 'app' {
      dart format --output=none --set-exit-if-changed lib test
    }
  }
  Step 'app: analyze'   'app' { flutter analyze }
  Step 'app: structure' 'app' { dart run tool/check_structure.dart }
  Step 'app: tests'     'app' { flutter test }
}

# ------------------------------------------------------------ backend job
if ($Backend) {
  $py = $null
  foreach ($c in @('backend\.venv\Scripts\python.exe', 'python', 'py')) {
    $full = Join-Path $root $c
    if (Test-Path $full) { $py = $full; break }
    if (Get-Command $c -ErrorAction SilentlyContinue) { $py = $c; break }
  }
  if (-not $py) {
    Skip 'backend' 'no python found'
  } else {
    Write-Host "python: $py"
    Step 'backend: style' 'backend' {
      & $py -m pycodestyle app tests integration_tests migrations
    }
    # The unit tests need no database.
    Step 'backend: unit tests' 'backend' { & $py -m pytest tests -q }

    # The integration tests need PostgreSQL, and they refuse a database
    # whose name does not end in _test because they empty its tables. The
    # db service in docker-compose.yml is the development database named
    # tfaqud, so this uses a throwaway container of its own on 5433
    # instead of touching it.
    if (-not $env:TEST_DATABASE_URL) {
      if (Get-Command docker -ErrorAction SilentlyContinue) {
        $name = 'tfaqud-test-db'
        $existing = docker ps -aq -f "name=^$name$"
        if ($existing) {
          docker start $name | Out-Null
        } else {
          Write-Host "starting $name on 5433"
          docker run -d --name $name `
            -e POSTGRES_USER=tfaqud -e POSTGRES_PASSWORD=tfaqud `
            -e POSTGRES_DB=tfaqud_test -p 5433:5432 postgres:16 | Out-Null
        }
        $ready = $false
        foreach ($i in 1..30) {
          docker exec $name pg_isready -U tfaqud -d tfaqud_test 2>$null |
            Out-Null
          if ($LASTEXITCODE -eq 0) { $ready = $true; break }
          Start-Sleep -Seconds 2
        }
        if ($ready) {
          $env:TEST_DATABASE_URL =
            'postgresql+psycopg://tfaqud:tfaqud@localhost:5433/tfaqud_test'
        } else {
          Write-Host "$name did not become ready" -ForegroundColor Yellow
        }
      }
    }
    if ($env:TEST_DATABASE_URL) {
      Write-Host "database: $env:TEST_DATABASE_URL"
      Step 'backend: integration tests' 'backend' {
        & $py -m pytest integration_tests -q
      }
    } else {
      Skip 'backend: integration tests' 'no TEST_DATABASE_URL and no docker'
    }
  }
}

# ------------------------------------------------------------------ report
Write-Host ''
Write-Host '================ summary ================'
foreach ($k in $results.Keys) {
  $v = $results[$k]
  $colour = if ($v -eq 'passed') { 'Green' }
            elseif ($v -like 'skipped*') { 'Yellow' } else { 'Red' }
  Write-Host ("{0,-32} {1}" -f $k, $v) -ForegroundColor $colour
}
Write-Host '========================================='
if ($failed) {
  Write-Host 'RED - do not push.' -ForegroundColor Red
  exit 1
}
if (($results.Values | Where-Object { $_ -like 'skipped*' })) {
  Write-Host 'GREEN, but something was skipped - read the summary.' `
    -ForegroundColor Yellow
} else {
  Write-Host 'GREEN - everything CI runs passed here.' -ForegroundColor Green
}
exit 0
