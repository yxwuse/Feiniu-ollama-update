#!/bin/bash

set -e
set -o pipefail

# 飞牛OS Ollama 升级脚本（国内加速版）v2.1.2
# 配置网络代理（根据实际代理类型选择一种）
# 方案1：HTTP代理
# export https_proxy="http://127.0.0.1:7890"
# 方案2：SOCKS5代理
export all_proxy="socks5://127.0.0.1:1080"

# 配置国内镜像源
MIRROR_SOURCE="https://hub.fastgit.org"

# 查找Ollama安装路径
VOL_PREFIXES=(/vol1 /vol2 /vol3 /vol4 /vol5 /vol6 /vol7 /vol8 /vol9)
for vol in "${VOL_PREFIXES[@]}"; do
    if [ -d "$vol/@appcenter/ai_installer/ollama" ]; then
        AI_INSTALLER="$vol/@appcenter/ai_installer"
        echo "✅ 找到安装路径：$AI_INSTALLER"
        break
    fi
done

# 获取最新版本号（主用镜像源）
get_latest_tag() {
    curl -s --retry 3 "$MIRROR_SOURCE/ollama/ollama/releases/latest" \
    | grep -oP 'tag_name":\s*"\K[0-9]+\.[0-9]+\.[0-9]+' | head -n 1
}

LATEST_TAG=$(get_latest_tag)

# 备用获取方案
if [ -z "$LATEST_TAG" ]; then
    echo "⚠️ 主源不可用，尝试备用方案..."
    LATEST_TAG=$(curl -s --retry 3 \
        "https://github.com.cnpmjs.org/ollama/ollama/releases/latest" \
        | grep -oP 'tag_name":\s*"\K[0-9]+\.[0-9]+\.[0-9]+' | head -n 1)
fi

# 验证版本号
if [ -z "$LATEST_TAG" ]; then
    echo "❌ 无法获取版本号，请检查网络连接或代理设置"
    exit 1
fi

echo "📦 最新版本号：v$LATEST_TAG"

# 下载新版本（使用镜像源）
FILENAME="ollama-linux-amd64.tgz"
URL="$MIRROR_SOURCE/ollama/ollama/releases/download/v$LATEST_TAG/$FILENAME"

# 下载函数（带进度条）
download_with_progress() {
    if command -v aria2c >/dev/null; then
        aria2c -x 16 -s 16 -k 1M -o "$FILENAME" "$URL"
    else
        curl -C - -# -o "$FILENAME" "$URL"
    fi
}

# 执行下载
echo "🌐 开始下载版本 v$LATEST_TAG ..."
download_with_progress

# 验证下载文件
if [ ! -f "$FILENAME" ]; then
    echo "❌ 下载失败，请重试"
    exit 1
fi

# 后续安装步骤保持不变
cd "$AI_INSTALLER"
mv ollama "$BACKUP_NAME"
tar -xzf "$FILENAME" -C ollama

# 升级pip和open-webui
PYTHON_EXEC="/var/apps/ai_installer/target/python/bin/python3.12"
"$PYTHON_EXEC" -m pip install --upgrade pip
"$PYTHON_EXEC" -m pip install --upgrade open-webui

echo "🎉 升级完成！Ollama 已更新至 v$LATEST_TAG"
fi

echo "🎉 升级完成！Ollama 与 open-webui 均为最新版本。"
