#!/usr/bin/env bash
# 一键部署脚本（在 VPS 项目根目录执行）
set -e

echo "==> 安装后端依赖"
cd backend && uv sync && cd ..

echo "==> 构建 Flutter Web"
flutter build web --release
rm -rf backend/static
cp -r build/web backend/static

echo "==> 重启服务"
sudo systemctl restart slim-coach

echo "==> 部署完成"
