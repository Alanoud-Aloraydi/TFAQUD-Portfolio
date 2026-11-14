@echo off
REM The checks of docs/code-conventions.md, with their output in one place.
REM Step 1 takes out the imports a file no longer needs and step 2 lays the
REM code out, so steps 3 to 5 judge the finished state.
cd /d "%~dp0.."
echo === dart fix: unused imports === > tool\checks.txt
call dart fix --apply --code=unused_import --code=unnecessary_import >> tool\checks.txt 2>&1
echo. >> tool\checks.txt
echo === dart format === >> tool\checks.txt
call dart format lib test integration_test >> tool\checks.txt 2>&1
echo. >> tool\checks.txt
echo === flutter analyze === >> tool\checks.txt
call flutter analyze >> tool\checks.txt 2>&1
echo. >> tool\checks.txt
echo === structure === >> tool\checks.txt
call dart run tool\check_structure.dart >> tool\checks.txt 2>&1
echo. >> tool\checks.txt
echo === flutter test === >> tool\checks.txt
call flutter test >> tool\checks.txt 2>&1
echo Done. The output is in app\tool\checks.txt
pause
