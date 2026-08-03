#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
APP_NAME="QuickCommit"
BUNDLE_ID="com.bravenewdesign.QuickCommit"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DERIVED_DATA="$ROOT_DIR/.build/DerivedData"
PACKAGE_CACHE="$ROOT_DIR/.build/SourcePackages"
APP_BUNDLE="$DERIVED_DATA/Build/Products/Debug/$APP_NAME.app"

pkill -x "$APP_NAME" >/dev/null 2>&1 || true
mkdir -p "$PACKAGE_CACHE"
xcodebuild -project "$ROOT_DIR/QuickCommit.xcodeproj" -scheme "$APP_NAME" -configuration Debug -derivedDataPath "$DERIVED_DATA" -clonedSourcePackagesDirPath "$PACKAGE_CACHE" build

case "$MODE" in
  run)
    /usr/bin/open -n "$APP_BUNDLE"
    ;;
  --debug|debug)
    lldb -- "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
    ;;
  --logs|logs)
    /usr/bin/open -n "$APP_BUNDLE"
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    /usr/bin/open -n "$APP_BUNDLE"
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    /usr/bin/open -n "$APP_BUNDLE"
    sleep 1
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
