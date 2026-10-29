@echo off
cd /d "%~dp0"
set "PUB_HOSTED_URL=https://pub.flutter-io.cn"
echo Buka http://127.0.0.1:5080/ di Chrome.
flutter run -d web-server --web-hostname=127.0.0.1 --web-port=5080
