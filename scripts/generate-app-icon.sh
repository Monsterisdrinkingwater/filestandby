#!/bin/zsh

set -euo pipefail

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
ICONSET_PATH="${PROJECT_ROOT}/Resources/AppIcon.iconset"

if [[ ! -d "${ICONSET_PATH}" ]]; then
    echo "缺少图标源文件：${ICONSET_PATH}" >&2
    exit 1
fi

iconutil -c icns "${ICONSET_PATH}" -o "${PROJECT_ROOT}/Resources/FileStandby.icns"
echo "已生成：${PROJECT_ROOT}/Resources/FileStandby.icns"
