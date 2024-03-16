#!/bin/bash

# 安装编译Python所需的依赖
sudo apt-get update -y
sudo apt-get install -y wget build-essential libncursesw5-dev libssl-dev libsqlite3-dev tk-dev libgdbm-dev libc6-dev libbz2-dev libffi-dev zlib1g-dev 

# 创建临时目录用于下载和编译Python
mkdir ~/python-compile
cd ~/python-compile

# 获取最新版本的Python源码下载链接
PYTHON_URL="https://www.python.org/ftp/python/3.12.2/Python-3.12.2.tgz"

# 下载最新版本的Python源码
wget $PYTHON_URL

# 解压源码
tar -xvf Python-3.12.2.tgz

# 进入解压后的目录
cd Python-3.12.2

# 配置Python源码
./configure --enable-optimizations

# 编译并安装
make -j $(nproc)  # 使用所有可用的核心进行编译
sudo make altinstall  # 使用altinstall避免替换默认python命令

# 返回到家目录并清理临时文件
cd ~
rm -rf ~/python-compile

# 创建软链接
# 请根据需要调整以下命令。这里以Python 3.x为例，创建python3和python链接到新安装的版本
# 检测安装的Python版本并创建软链接
PYTHON_VERSION=$(echo $PYTHON_LATEST | grep -oP '\d+\.\d+')

sudo ln -sf /usr/local/bin/python3.12 /usr/local/bin/python

echo "Python 3.12 安装完成。已创建软链接。"
