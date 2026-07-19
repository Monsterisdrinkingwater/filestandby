#!/bin/zsh

set -euo pipefail

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
CONFIGURATION="${1:-release}"
APP_PATH="${PROJECT_ROOT}/.build/FileStandby.app"

cd "${PROJECT_ROOT}"

swift build -c "${CONFIGURATION}"
BIN_DIRECTORY="$(swift build -c "${CONFIGURATION}" --show-bin-path)"
EXECUTABLE_PATH="${BIN_DIRECTORY}/FileStandby"

if [[ ! -x "${EXECUTABLE_PATH}" ]]; then
    echo "找不到编译产物：${EXECUTABLE_PATH}" >&2
    exit 1
fi

if [[ "${APP_PATH}" != "${PROJECT_ROOT}/.build/FileStandby.app" ]]; then
    echo "拒绝清理意外路径：${APP_PATH}" >&2
    exit 1
fi

STAGING_DIR="$(mktemp -d /private/tmp/filestandby-build.XXXXXX)"
STAGED_APP_PATH="${STAGING_DIR}/FileStandby.app"
cleanup_staging_dir() {
    if [[ "${STAGING_DIR}" == /private/tmp/filestandby-build.* ]]; then
        rm -rf "${STAGING_DIR}"
    fi
}
trap cleanup_staging_dir EXIT

# Assemble and sign outside Documents so iCloud File Provider cannot race the
# signing or strict-verification steps by attaching Finder metadata.
mkdir -p "${STAGED_APP_PATH}/Contents/MacOS" "${STAGED_APP_PATH}/Contents/Resources"
ditto "${EXECUTABLE_PATH}" "${STAGED_APP_PATH}/Contents/MacOS/FileStandby"
ditto "${PROJECT_ROOT}/Resources/Info.plist" "${STAGED_APP_PATH}/Contents/Info.plist"
ditto "${PROJECT_ROOT}/Resources/FileStandby.icns" "${STAGED_APP_PATH}/Contents/Resources/FileStandby.icns"
printf 'APPL????' > "${STAGED_APP_PATH}/Contents/PkgInfo"
xattr -cr "${STAGED_APP_PATH}"
codesign --force --deep --sign - "${STAGED_APP_PATH}" >/dev/null
codesign --verify --deep --strict "${STAGED_APP_PATH}"

# Publish only after the staged app has passed signature verification. `-X`
# prevents copying extended attributes into the final app bundle.
rm -rf "${APP_PATH}"
cp -R -X "${STAGED_APP_PATH}" "${APP_PATH}"
cleanup_staging_dir
trap - EXIT

echo "已生成：${APP_PATH}"
