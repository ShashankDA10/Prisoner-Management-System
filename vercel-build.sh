#!/bin/bash
set -e

FLUTTER_VERSION="3.41.4"

# Vercel runs as root; git refuses to operate on directories owned by another user.
# Allow all directories so Flutter's internal git calls don't fail.
git config --global --add safe.directory '*'

echo "Downloading Flutter $FLUTTER_VERSION..."
curl -s -L \
  "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
  -o flutter.tar.xz
tar xf flutter.tar.xz
rm flutter.tar.xz

export PATH="$PATH:$(pwd)/flutter/bin"
flutter config --enable-web --no-analytics

echo "Installing dependencies..."
flutter pub get

echo "Building for web..."
flutter build web --release

echo "Build complete."
