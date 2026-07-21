#!/bin/zsh

set -euo pipefail

SCRIPT_DIR="${0:A:h}"
PROJECT_ROOT="${SCRIPT_DIR:h}"
SOURCE_ICON_PATH="${PROJECT_ROOT}/Resources/AppIcon.icns"

if [[ ! -f "${SOURCE_ICON_PATH}" ]]; then
    echo "缺少图标源文件：${SOURCE_ICON_PATH}" >&2
    exit 1
fi

ditto "${SOURCE_ICON_PATH}" "${PROJECT_ROOT}/Resources/FileStandby.icns"
echo "已生成：${PROJECT_ROOT}/Resources/FileStandby.icns"
