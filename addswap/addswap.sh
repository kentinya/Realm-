#!/bin/bash

# 检查脚本是否以 root 权限运行
if [ "$(id -u)" -ne 0 ]; then
  echo "此脚本需要以 root 权限运行"
  exit 1
fi

# 设置默认交换文件大小（以MB为单位）
DEFAULT_SWAP_SIZE=1024
# 设置默认交换文件路径
DEFAULT_SWAP_FILE="/swapfile"

# 读取用户输入的交换文件大小，如果没有输入则使用默认值
read -p "请输入交换文件大小 (MB) [默认: ${DEFAULT_SWAP_SIZE}MB]: " swap_size
swap_size=${swap_size:-$DEFAULT_SWAP_SIZE}

# 读取用户输入的交换文件路径，如果没有输入则使用默认路径
read -p "请输入交换文件路径 [默认: ${DEFAULT_SWAP_FILE}]: " swap_file
swap_file=${swap_file:-$DEFAULT_SWAP_FILE}

# 创建交换文件
echo "正在创建交换文件..."
dd if=/dev/zero of="$swap_file" bs=1M count=$swap_size status=progress

# 设置交换文件权限
chmod 600 "$swap_file"

# 设置交换空间
mkswap "$swap_file"

# 启用交换空间
swapon "$swap_file"

# 验证交换空间是否成功启用
swapon -s

# 将交换文件信息添加到 /etc/fstab 以便在系统重启后自动启用
echo "$swap_file none swap sw 0 0" >> /etc/fstab

echo "交换空间添加完成。"