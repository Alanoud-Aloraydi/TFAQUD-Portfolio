# Watches lib, test and integration_test and checks the app whenever a file
# changes, writing everything to tool\checks.txt.
#
# Start it once and leave the window open:
#   tool\watch.bat
#
# The order matters:
#   1. dart format   - fast, and it fails loudly on a syntax error
#   2. dart fix      - only when the code parses. Run on a file it cannot
#                      parse, dart fix deletes imports it cannot prove are
#                      used, which turns one mistake into ten.
#   3. flutter analyze
#   4. flutter test  - only when analyze found nothing, so the ten minutes
#                      are never spent on code that is already broken.

Set-Location (Split-Path $PSScriptRoot -Parent)
$out = "tool\checks.txt"
$last = ""

function Get-Fingerprint {
    Get-ChildItem -Recurse -Include *.dart -Path lib, test, integration_test -ErrorAction SilentlyContinue |
        ForEach-Object { "$($_.FullName)|$($_.LastWriteTimeUtc.Ticks)" } |
        Out-String
}

function Write-Section([string]$name) {
    "" | Out-File -Encoding utf8 -Append $out
    "=== $name ===" | Out-File -Encoding utf8 -Append $out
}

function Invoke-Checks {
    $started = Get-Date -Format "HH:mm:ss"
    "=== run at $started ===" | Out-File -Encoding utf8 $out

    Write-Section "dart format"
    $fmt = dart format lib test integration_test 2>&1
    $fmt | Select-Object -Last 4 | Out-File -Encoding utf8 -Append $out
    $broken = $fmt | Select-String -Pattern "Could not format|error on line|^Error" -Quiet

    if ($broken) {
        Write-Section "stopped"
        "A file does not parse. dart fix was skipped on purpose." |
            Out-File -Encoding utf8 -Append $out
        $fmt | Select-String -Pattern "Could not format|error on line|^Error" |
            Out-File -Encoding utf8 -Append $out
    } else {
        Write-Section "dart fix"
        dart fix --apply --code=unused_import --code=unnecessary_import 2>&1 |
            Select-Object -Last 20 | Out-File -Encoding utf8 -Append $out
    }

    Write-Section "flutter analyze"
    $analyze = flutter analyze 2>&1
    $analyze | Out-File -Encoding utf8 -Append $out

    Write-Section "structure"
    dart run tool\check_structure.dart 2>&1 | Out-File -Encoding utf8 -Append $out

    $clean = $analyze | Select-String -Pattern "No issues found" -Quiet
    if ($clean -and -not $broken) {
        Write-Section "flutter test"
        Write-Host "  analyze clean - running the tests (a few minutes)"
        # The compact reporter prints one line per failure; the whole
        # output goes to tests.txt, the failures and the count here.
        flutter test --reporter expanded 2>&1 |
            Out-File -Encoding utf8 "tool\tests.txt"
        Get-Content "tool\tests.txt" |
            Select-String -Pattern "\[E\]|Some tests failed|All tests passed|Expected:|Actual:|Which:|^  package:app|_test\.dart [0-9]+" |
            Select-Object -Last 150 | Out-File -Encoding utf8 -Append $out
    } else {
        Write-Section "flutter test"
        "Skipped: analyze is not clean yet." | Out-File -Encoding utf8 -Append $out
    }

    "=== done $(Get-Date -Format "HH:mm:ss") ===" | Out-File -Encoding utf8 -Append $out
    Write-Host "checked at $started"
}

Write-Host "Watching. Ctrl+C to stop. Output: $out"
while ($true) {
    $now = Get-Fingerprint
    if ($now -ne $last) {
        $last = $now
        Start-Sleep -Seconds 3
        $last = Get-Fingerprint
        Invoke-Checks
    }
    Start-Sleep -Seconds 5
}
