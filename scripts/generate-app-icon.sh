#!/bin/zsh

set -euo pipefail

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
TEMP_DIRECTORY="$(mktemp -d "${TMPDIR:-/tmp}/FileStandbyIcon.XXXXXX")"
ICONSET_PATH="${TEMP_DIRECTORY}/FileStandby.iconset"
MODULE_CACHE_PATH="${TEMP_DIRECTORY}/ModuleCache"
SOURCE_PNG_PATH="${TEMP_DIRECTORY}/FileStandby.png"

cleanup() {
    rm -rf "${TEMP_DIRECTORY}"
}
trap cleanup EXIT

swift -module-cache-path "${MODULE_CACHE_PATH}" "${SCRIPT_DIR}/generate-app-icon.swift" "${SOURCE_PNG_PATH}"
mkdir -p "${ICONSET_PATH}"
sips -z 16 16 "${SOURCE_PNG_PATH}" --out "${ICONSET_PATH}/icon_16x16.png" >/dev/null
sips -z 32 32 "${SOURCE_PNG_PATH}" --out "${ICONSET_PATH}/icon_16x16@2x.png" >/dev/null
sips -z 32 32 "${SOURCE_PNG_PATH}" --out "${ICONSET_PATH}/icon_32x32.png" >/dev/null
sips -z 64 64 "${SOURCE_PNG_PATH}" --out "${ICONSET_PATH}/icon_32x32@2x.png" >/dev/null
sips -z 128 128 "${SOURCE_PNG_PATH}" --out "${ICONSET_PATH}/icon_128x128.png" >/dev/null
sips -z 256 256 "${SOURCE_PNG_PATH}" --out "${ICONSET_PATH}/icon_128x128@2x.png" >/dev/null
sips -z 256 256 "${SOURCE_PNG_PATH}" --out "${ICONSET_PATH}/icon_256x256.png" >/dev/null
sips -z 512 512 "${SOURCE_PNG_PATH}" --out "${ICONSET_PATH}/icon_256x256@2x.png" >/dev/null
sips -z 512 512 "${SOURCE_PNG_PATH}" --out "${ICONSET_PATH}/icon_512x512.png" >/dev/null
sips -z 1024 1024 "${SOURCE_PNG_PATH}" --out "${ICONSET_PATH}/icon_512x512@2x.png" >/dev/null
iconutil -c icns "${ICONSET_PATH}" -o "${PROJECT_ROOT}/Resources/FileStandby.icns"
echo "已生成：${PROJECT_ROOT}/Resources/FileStandby.icns"
