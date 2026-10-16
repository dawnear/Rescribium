#!/bin/bash
# 安装 OCR 后端：项目内 .venv + ocrmypdf + ocrmypdf-appleocr
# 前置条件：brew install python@3.13 ghostscript qpdf
set -euo pipefail
cd "$(dirname "$0")/.."

PY=/opt/homebrew/opt/python@3.13/bin/python3.13
if [ ! -x "$PY" ]; then
    echo "未找到 python@3.13，请先执行：brew install python@3.13" >&2
    exit 1
fi

"$PY" -m venv .venv
./.venv/bin/pip install --upgrade pip
./.venv/bin/pip install ocrmypdf ocrmypdf-appleocr

# 让打包后的 App 也能自动找到后端（GUI 进程不读取项目目录）
mkdir -p ~/.local/bin
ln -sf "$PWD/.venv/bin/ocrmypdf" ~/.local/bin/ocrmypdf

echo "后端安装完成：$(./.venv/bin/ocrmypdf --version)"
