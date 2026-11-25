#!/usr/bin/env bash
# Opens the release app on the emulator and fails if it stops within
# 30 seconds, printing the crash log.
set -u
PACKAGE=com.tfaqud.tfaqud
if ! adb install -r build/app/outputs/flutter-apk/app-release.apk; then
  echo "::error::The APK did not install on the emulator."
  exit 1
fi
adb logcat -c
adb shell monkey -p "$PACKAGE" -c android.intent.category.LAUNCHER 1
sleep 30
adb logcat -d | grep -E "flutter|AndroidRuntime|FATAL" | tail -n 150
if adb shell pidof "$PACKAGE" > /dev/null; then
  echo "The app is still running after 30 seconds."
  exit 0
fi
echo "::error::The app stopped on start. The crash log is above."
adb logcat -d -b crash
exit 1
