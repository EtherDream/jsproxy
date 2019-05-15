#!/usr/bin/env bash
# 功能：安装 brotli 压缩工具

git clone --depth 1 https://github.com/google/brotli.git
cd brotli

make
mv bin/brotli ~

cd ..
rm -rf brotli