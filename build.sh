#!/bin/bash
# SlowQuitApps Build Script
# Used to build a signed macOS .app bundle

set -e

# Configurations
APP_NAME="SlowQuitApps"
BUNDLE_ID="com.slowquitapps.app"
VERSION="1.0.0"
BUILD_DIR=".build/release"
APP_DIR="build/${APP_NAME}.app"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"

# Color outputs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}🔨 Starting build for ${APP_NAME}...${NC}"

# 1. Clean previous builds
echo -e "${YELLOW}📦 Cleaning old build artifacts...${NC}"
rm -rf build/
mkdir -p build/

# 2. Release build
echo -e "${YELLOW}⚙️  Compiling Release version...${NC}"
swift build -c release

# 3. Create .app directory structure
echo -e "${YELLOW}📁 Creating app bundle structure...${NC}"
mkdir -p "${APP_DIR}/Contents/MacOS"
mkdir -p "${APP_DIR}/Contents/Resources"

# 4. Copy executable
cp "${BUILD_DIR}/${APP_NAME}" "${APP_DIR}/Contents/MacOS/"

# 5. Create Info.plist (Critical: properly configure GUI app)
cat > "${APP_DIR}/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>Slow Quit Apps</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSAppleEventsUsageDescription</key>
    <string>Slow Quit Apps needs to control other apps to implement the delayed quit feature.</string>
</dict>
</plist>
EOF

# 6. Create PkgInfo
echo -n "APPL????" > "${APP_DIR}/Contents/PkgInfo"

# 7. Copy icon if it exists
if [ -f "BuildAssets/AppIcon.icns" ]; then
    cp "BuildAssets/AppIcon.icns" "${APP_DIR}/Contents/Resources/"
    echo -e "${GREEN}✓ Copied app icon${NC}"
fi

# 8. Ad-hoc signature (for local development)
echo -e "${YELLOW}🔐 Performing ad-hoc signature...${NC}"
codesign --force --deep --sign - "${APP_DIR}"

# 9. Verify signature
echo -e "${YELLOW}🔍 Verifying signature...${NC}"
codesign --verify --verbose=2 "${APP_DIR}" 2>&1 || true

# 10. Create DMG package (optional)
if command -v create-dmg &> /dev/null || command -v hdiutil &> /dev/null; then
    echo -e "${YELLOW}📀 Creating DMG package...${NC}"
    
    # Create temp directory
    DMG_TEMP="build/dmg_temp"
    mkdir -p "${DMG_TEMP}"
    cp -R "${APP_DIR}" "${DMG_TEMP}/"
    
    # Create symlink to Applications
    ln -s /Applications "${DMG_TEMP}/Applications"
    
    # Copy multilingual installation docs
    DOCS_DIR="BuildAssets/Docs"
    if [ -d "${DOCS_DIR}" ]; then
        echo -e "${YELLOW}📖 Copying installation docs...${NC}"
        mkdir -p "${DMG_TEMP}/Documentation"
        cp "${DOCS_DIR}/README-en.md" "${DMG_TEMP}/Documentation/README (English).md" 2>/dev/null || true
        cp "${DOCS_DIR}/README-zh-CN.md" "${DMG_TEMP}/Documentation/安装指南 (中文).md" 2>/dev/null || true
        cp "${DOCS_DIR}/README-zh-TW.md" "${DMG_TEMP}/Documentation/安裝指南 (繁體中文).md" 2>/dev/null || true
        cp "${DOCS_DIR}/README-ja.md" "${DMG_TEMP}/Documentation/インストールガイド (日本語).md" 2>/dev/null || true
        cp "${DOCS_DIR}/README-ru.md" "${DMG_TEMP}/Documentation/Руководство (Русский).md" 2>/dev/null || true
        echo -e "${GREEN}✓ Copied multilingual docs${NC}"
    fi
    
    # Use hdiutil to create DMG
    hdiutil create -volname "${APP_NAME}" \
        -srcfolder "${DMG_TEMP}" \
        -ov -format UDZO \
        "build/${DMG_NAME}"
    
    # Clean up temp directory
    rm -rf "${DMG_TEMP}"
    
    echo -e "${GREEN}✓ DMG created: build/${DMG_NAME}${NC}"
fi

# 11. Get final file size
SIZE=$(du -sh "${APP_DIR}" | cut -f1)

echo ""
echo -e "${GREEN}✅ Build complete!${NC}"
echo -e "   App location: ${APP_DIR}"
echo -e "   App size: ${SIZE}"
if [ -f "build/${DMG_NAME}" ]; then
    DMG_SIZE=$(du -sh "build/${DMG_NAME}" | cut -f1)
    echo -e "   DMG location: build/${DMG_NAME}"
    echo -e "   DMG size: ${DMG_SIZE}"
fi
echo ""
echo -e "${YELLOW}💡 Instructions:${NC}"
echo "   • Double-click ${APP_DIR} or install via DMG to run"
echo "   • First run requires granting Accessibility permission"
echo "   • App will show an icon in the menu bar"
echo ""

# Open build directory
open build/
