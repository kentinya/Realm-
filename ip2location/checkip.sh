#!/bin/bash

# 设置 API 密钥
API_KEY="7F3F0DFD8E2BEC9B8A2310E6FBB80249"

# 获取本机外部 IP 地址
# 这里使用了一个免费的服务 "https://api.ipify.org"
# 你也可以使用其他类似的服务
IP=$(curl -s https://api.ipify.org)

# 检查是否成功获取 IP
if [[ -z "$IP" ]]; then
  echo "无法获取外部 IP 地址"
  exit 1
fi

# 调用 ip2location API 获取地理位置信息
RESPONSE=$(curl -s "https://api.ip2location.io/?key=${API_KEY}&ip=${IP}")

# 检查 API 调用是否成功
if [[ -z "$RESPONSE" ]]; then
  echo "无法从 ip2location API 获取信息"
  exit 1
fi

# 使用 jq 解析 JSON 响应
# jq 是一个轻量级的命令行 JSON 处理工具
# 如果你的系统没有 jq，请先安装它 (例如: sudo apt-get install jq)
COUNTRY=$(echo "$RESPONSE" | jq -r '.country_name')
REGION=$(echo "$RESPONSE" | jq -r '.region_name')
CITY=$(echo "$RESPONSE" | jq -r '.city_name')
ISP=$(echo "$RESPONSE" | jq -r '.isp')

# 输出结果
echo "IP 地址: $IP"
echo "国家: $COUNTRY"
echo "地区: $REGION"
echo "城市: $CITY"
echo "ISP: $ISP"