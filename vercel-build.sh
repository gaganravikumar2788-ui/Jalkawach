#!/bin/bash
set -e

echo "=== Installing Flutter SDK for Vercel Web Build ==="
if [ -d "_flutter" ]; then
  echo "Flutter already cached"
else
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable _flutter
fi

export PATH="$PATH:$(pwd)/_flutter/bin"
flutter doctor -v

echo "=== Building JalKawach Flutter Web ==="
cd frontend
flutter pub get
flutter build web --release

echo "=== Build Complete ==="
