@echo off
REM What CI needs after a merge or a colour change:
REM   1. the structure baseline, so the files that already broke a rule are
REM      listed again with their current size (a NEW violation still fails),
REM   2. the golden images, redrawn when the palette changes.
cd /d "%~dp0\.."
echo == structure baseline ==
dart run tool\check_structure.dart --update-baseline
echo == golden images ==
flutter test --update-goldens test\core\design_system_visual_regression_test.dart
echo.
echo Done. Run "flutter test" to confirm, then commit.
pause
