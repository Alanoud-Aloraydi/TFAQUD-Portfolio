@echo off
REM The design system's golden images, redrawn after a colour change.
cd /d "%~dp0\.."
flutter test --update-goldens test\core\design_system_visual_regression_test.dart
pause
