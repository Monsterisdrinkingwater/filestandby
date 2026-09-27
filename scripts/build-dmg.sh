#!/bin/zsh

set -euo pipefail

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
CONFIGURATION="${1:-release}"
PLIST_PATH="${PROJECT_ROOT}/Resources/Info.plist"
APP_PATH="${PROJECT_ROOT}/.build/FileStandby.app"
BUILD_ROOT="${PROJECT_ROOT}/.build/FileStandby-dmg-build"

cd "${PROJECT_ROOT}"

if ! command -v hdiutil >/dev/null 2>&1; then
    echo "找不到 hdiutil。请在 macOS 上运行此脚本。" >&2
    exit 1
fi

VERSION="$(plutil -extract CFBundleShortVersionString raw -o - "${PLIST_PATH}")"
DMG_PATH="${PROJECT_ROOT}/.build/FileStandby-${VERSION}.dmg"

ARM64_BIN=""
X86_64_BIN=""
for ARCHITECTURE in arm64 x86_64; do
    SCRATCH_PATH="${BUILD_ROOT}/${ARCHITECTURE}"
    TARGET_TRIPLE="${ARCHITECTURE}-apple-macosx14.0"

    swift build \
        -c "${CONFIGURATION}" \
        --scratch-path "${SCRATCH_PATH}" \
        --triple "${TARGET_TRIPLE}"

    BIN_DIRECTORY="$(swift build \
        -c "${CONFIGURATION}" \
        --scratch-path "${SCRATCH_PATH}" \
        --triple "${TARGET_TRIPLE}" \
        --show-bin-path)"
    EXECUTABLE_PATH="${BIN_DIRECTORY}/FileStandby"

    if [[ ! -x "${EXECUTABLE_PATH}" ]]; then
        echo "找不到 ${ARCHITECTURE} 编译产物：${EXECUTABLE_PATH}" >&2
        exit 1
    fi

    if [[ "${ARCHITECTURE}" == arm64 ]]; then
        ARM64_BIN="${EXECUTABLE_PATH}"
    else
        X86_64_BIN="${EXECUTABLE_PATH}"
    fi
done

if [[ ! -f "${PLIST_PATH}" || ! -f "${PROJECT_ROOT}/Resources/FileStandby.icns" ]]; then
    echo "缺少应用资源文件，无法创建应用包。" >&2
    exit 1
fi

STAGING_DIR="$(mktemp -d /private/tmp/filestandby-dmg.XXXXXX)"
cleanup_staging_dir() {
    if [[ "${STAGING_DIR}" == /private/tmp/filestandby-dmg.* ]]; then
        rm -rf "${STAGING_DIR}"
    fi
}
trap cleanup_staging_dir EXIT

# The Applications alias gives users the familiar drag-to-install DMG flow.
STAGED_APP_PATH="${STAGING_DIR}/FileStandby.app"
mkdir -p "${STAGED_APP_PATH}/Contents/MacOS" "${STAGED_APP_PATH}/Contents/Resources"
lipo -create "${ARM64_BIN}" "${X86_64_BIN}" \
    -output "${STAGED_APP_PATH}/Contents/MacOS/FileStandby"
ditto "${PLIST_PATH}" "${STAGED_APP_PATH}/Contents/Info.plist"
ditto "${PROJECT_ROOT}/Resources/FileStandby.icns" \
    "${STAGED_APP_PATH}/Contents/Resources/FileStandby.icns"
printf 'APPL????' > "${STAGED_APP_PATH}/Contents/PkgInfo"
ln -s /Applications "${STAGING_DIR}/Applications"
xattr -cr "${STAGING_DIR}"
codesign --force --deep --sign - "${STAGED_APP_PATH}" >/dev/null

rm -rf "${APP_PATH}"
cp -R -X "${STAGED_APP_PATH}" "${APP_PATH}"
codesign --verify --deep --strict "${APP_PATH}"

rm -f "${DMG_PATH}"
hdiutil create \
    -volname "File Standby ${VERSION}" \
    -srcfolder "${STAGING_DIR}" \
    -ov \
    -format UDZO \
    "${DMG_PATH}" >/dev/null
hdiutil verify "${DMG_PATH}" >/dev/null

echo "已生成并验证：${DMG_PATH}"
