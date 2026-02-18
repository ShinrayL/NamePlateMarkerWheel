#!/bin/bash
# NamePlateMarkerWheel - Sync to WoW Addon Directory (Auto-detect)

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 源目录：脚本所在目录下的 src 文件夹
SRC="$SCRIPT_DIR/src"

# 自动检测 WoW 安装路径（按优先级尝试）
DETECTED_DEST=""

# 常见 WoW 安装路径列表（支持 WSL/Git Bash/MinGW 路径格式）
POSSIBLE_PATHS=(
    # WSL 路径格式
    "/mnt/c/Program Files/World of Warcraft/_retail_/Interface/AddOns/NamePlateMarkerWheel"
    "/mnt/c/Program Files (x86)/World of Warcraft/_retail_/Interface/AddOns/NamePlateMarkerWheel"
    "/mnt/d/World of Warcraft/_retail_/Interface/AddOns/NamePlateMarkerWheel"
    "/mnt/d/Games/World of Warcraft/_retail_/Interface/AddOns/NamePlateMarkerWheel"
    "/mnt/e/World of Warcraft/_retail_/Interface/AddOns/NamePlateMarkerWheel"
    "/mnt/f/World of Warcraft/_retail_/Interface/AddOns/NamePlateMarkerWheel"
    "/mnt/g/World of Warcraft/_retail_/Interface/AddOns/NamePlateMarkerWheel"
    # MinGW/Git Bash 路径格式
    "/c/Program Files/World of Warcraft/_retail_/Interface/AddOns/NamePlateMarkerWheel"
    "/c/Program Files (x86)/World of Warcraft/_retail_/Interface/AddOns/NamePlateMarkerWheel"
    "/d/World of Warcraft/_retail_/Interface/AddOns/NamePlateMarkerWheel"
    "/d/Games/World of Warcraft/_retail_/Interface/AddOns/NamePlateMarkerWheel"
    "/e/World of Warcraft/_retail_/Interface/AddOns/NamePlateMarkerWheel"
    "/f/World of Warcraft/_retail_/Interface/AddOns/NamePlateMarkerWheel"
    "/g/World of Warcraft/_retail_/Interface/AddOns/NamePlateMarkerWheel"
    # Cygwin 路径格式
    "/cygdrive/c/Program Files/World of Warcraft/_retail_/Interface/AddOns/NamePlateMarkerWheel"
    "/cygdrive/d/World of Warcraft/_retail_/Interface/AddOns/NamePlateMarkerWheel"
)

# 尝试自动检测
for path in "${POSSIBLE_PATHS[@]}"; do
    if [ -d "$(dirname "$path")" ] || [ -d "$path" ]; then
        DETECTED_DEST="$path"
        break
    fi
done

# 如果环境变量设置了 WoW 路径，优先使用
if [ -n "$WOW_ADDON_PATH" ]; then
    DETECTED_DEST="$WOW_ADDON_PATH/NamePlateMarkerWheel"
    echo "[INFO] 使用环境变量 WOW_ADDON_PATH: $WOW_ADDON_PATH"
fi

# 如果没有检测到，使用默认路径（并提示用户）
if [ -z "$DETECTED_DEST" ]; then
    # 尝试使用 Windows 用户目录下的默认位置
    if [ -d "$USERPROFILE" ]; then
        # 从 Windows 路径转换为 Unix 路径
        WIN_PATH=$(echo "$USERPROFILE" | sed 's/\\/\//g' | sed 's/C:/\/mnt\/c/g' | sed 's/D:/\/mnt\/d/g')
        DETECTED_DEST="$WIN_PATH/../Program Files/World of Warcraft/_retail_/Interface/AddOns/NamePlateMarkerWheel"
    else
        DETECTED_DEST="/mnt/c/Program Files/World of Warcraft/_retail_/Interface/AddOns/NamePlateMarkerWheel"
    fi
fi

DEST="$DETECTED_DEST"

echo "=========================================="
echo " NamePlateMarkerWheel - Sync to WoW"
echo "=========================================="
echo ""
echo "[INFO] Source: $SRC"
echo "[INFO] Destination: $DEST"
echo ""

# 检查源目录
if [ ! -d "$SRC" ]; then
    echo "[ERROR] Source directory not found: $SRC"
    echo "[HINT] Make sure you're running this script from the project root"
    exit 1
fi

# 检查是否有文件需要同步
if [ ! "$(ls -A "$SRC"/*.lua 2>/dev/null)" ] && [ ! "$(ls -A "$SRC"/*.toc 2>/dev/null)" ]; then
    echo "[ERROR] No .lua or .toc files found in $SRC"
    exit 1
fi

# Create destination if needed
if [ ! -d "$DEST" ]; then
    echo "[INFO] Creating destination directory..."
    mkdir -p "$DEST"
    if [ $? -ne 0 ]; then
        echo "[ERROR] Failed to create destination directory!"
        echo "[HINT] Check if the WoW installation path is correct"
        echo "[HINT] You can set custom path via environment variable:"
        echo "       export WOW_ADDON_PATH='/path/to/World of Warcraft/_retail_/Interface/AddOns'"
        exit 1
    fi
fi

echo "[SYNC] Copying files..."
echo ""

# Copy Lua and TOC files
copied=0
failed=0

for file in "$SRC"/*.lua "$SRC"/*.toc; do
    if [ -f "$file" ]; then
        cp -v "$file" "$DEST/"
        if [ $? -eq 0 ]; then
            ((copied++))
        else
            ((failed++))
        fi
    fi
done

echo ""
echo "=========================================="
echo " Sync completed!"
echo " Files copied: $copied"
if [ $failed -gt 0 ]; then
    echo " Files failed: $failed"
fi
echo " Destination: $DEST"
echo "=========================================="
