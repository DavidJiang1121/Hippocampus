#!/bin/bash
set -euo pipefail
ORIGINAL_PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_DIR="${1:-$(dirname "$ORIGINAL_PROJECT_DIR")}"
SCRATCH="$(mktemp -d "${TMPDIR:-/tmp}/Hippocampus-build.XXXXXX")"
trap 'rm -rf "$SCRATCH"' EXIT
# Compile a stable snapshot outside iCloud/File Provider managed folders.
ditto --norsrc "$ORIGINAL_PROJECT_DIR" "$SCRATCH/Source"
PROJECT_DIR="$SCRATCH/Source"
BUILD_DIR="${2:-$SCRATCH/Build}"
APP="$SCRATCH/Hippocampus.app"
mkdir -p "$BUILD_DIR/ModuleCache" "$APP/Contents/MacOS" "$APP/Contents/Resources"
SWIFTC="$(xcrun --find swiftc)"
SDK="$(xcrun --sdk macosx --show-sdk-path)"
echo "Compiling Hippocampus…"
"$SWIFTC" -swift-version 5 -O -sdk "$SDK" -target arm64-apple-macosx13.0 -module-cache-path "$BUILD_DIR/ModuleCache" \
    "$PROJECT_DIR"/Sources/*.swift -o "$APP/Contents/MacOS/Hippocampus" \
    -framework AppKit -framework SwiftUI -framework ServiceManagement -framework CryptoKit -framework ImageIO
"$SWIFTC" -swift-version 5 -O -sdk "$SDK" -target arm64-apple-macosx13.0 -module-cache-path "$BUILD_DIR/ModuleCache" \
    "$PROJECT_DIR/Sources/Icon.swift" "$PROJECT_DIR/Tools/main.swift" -o "$BUILD_DIR/make-icon" -framework AppKit
"$BUILD_DIR/make-icon" "$BUILD_DIR/AppIcon.iconset"
python3 "$PROJECT_DIR/Tools/icns.py" "$BUILD_DIR/AppIcon.iconset" "$APP/Contents/Resources/AppIcon.icns"
cp "$BUILD_DIR/AppIcon.iconset/icon_512x512@2x.png" "$OUTPUT_DIR/Hippocampus-Icon.png"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleName</key><string>Hippocampus</string>
<key>CFBundleDisplayName</key><string>Hippocampus</string>
<key>CFBundleIdentifier</key><string>local.hippocampus.app</string>
<key>CFBundleExecutable</key><string>Hippocampus</string>
<key>CFBundleIconFile</key><string>AppIcon</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>1.1.0</string>
<key>CFBundleVersion</key><string>2</string>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>LSUIElement</key><true/>
<key>NSHighResolutionCapable</key><true/>
<key>NSPrincipalClass</key><string>NSApplication</string>
<key>NSDesktopFolderUsageDescription</key><string>收纳系统保存在桌面的截图，保存最近 30 张的独立副本。</string>
<key>NSDocumentsFolderUsageDescription</key><string>收纳你选择的截图文件夹中的截图。</string>
<key>NSDownloadsFolderUsageDescription</key><string>收纳你设定在下载文件夹中的截图。</string>
</dict></plist>
PLIST
xattr -dr com.apple.FinderInfo "$APP" 2>/dev/null || true
xattr -dr com.apple.ResourceFork "$APP" 2>/dev/null || true
codesign --force --sign - --identifier local.hippocampus.app "$APP"
codesign --verify --deep --strict "$APP"
"$SWIFTC" -swift-version 5 -O -sdk "$SDK" -target arm64-apple-macosx13.0 -module-cache-path "$BUILD_DIR/ModuleCache" \
    "$PROJECT_DIR/Sources/Library.swift" "$PROJECT_DIR/Tests/main.swift" -o "$BUILD_DIR/library-tests" -framework AppKit -framework CryptoKit -framework ImageIO
"$BUILD_DIR/library-tests" "$BUILD_DIR/test-data"
"$SWIFTC" -swift-version 5 -sdk "$SDK" -target arm64-apple-macosx13.0 -module-cache-path "$BUILD_DIR/ModuleCache" \
    "$PROJECT_DIR/Sources/Library.swift" "$PROJECT_DIR/Sources/Icon.swift" "$PROJECT_DIR/Sources/Monitor.swift" \
    "$PROJECT_DIR/Sources/Views.swift" "$PROJECT_DIR/InteractionTests/main.swift" -o "$BUILD_DIR/interaction-tests" \
    -framework AppKit -framework SwiftUI -framework ServiceManagement -framework CryptoKit -framework ImageIO
HIPPOCAMPUS_TEST_MODE=1 HIPPOCAMPUS_DATA_DIR="$BUILD_DIR/interaction-library" "$BUILD_DIR/interaction-tests" "$APP/Contents/Resources/AppIcon.icns"
ditto --norsrc "$APP" "$OUTPUT_DIR/Hippocampus.app"
ditto -c -k --norsrc --keepParent "$APP" "$OUTPUT_DIR/Hippocampus.zip"
echo "Built: $OUTPUT_DIR/Hippocampus.app"
