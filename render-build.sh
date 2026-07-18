#!/usr/bin/env bash
set -e

echo "==> Installing Flutter SDK..."
git clone --depth 1 --branch stable https://github.com/flutter/flutter.git /opt/flutter

export PATH="/opt/flutter/bin:$PATH"

echo "==> Enabling web..."
flutter config --enable-web --quiet

echo "==> Building Flutter web..."
flutter build web

echo "==> Done!"
