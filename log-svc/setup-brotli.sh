#!/usr/bin/env bash
# 功能：安装 brotli 压缩工具
# 依赖：cmake（yum install -y cmake）

git clone --depth 1 https://github.com/google/brotli.git
cd brotli

./configure-cmake
make

mkdir -p ~/tools
mv brotli ~/tools

cd ..
rm -rf brotli