#!/bin/bash

# 设置 API 密钥
API_KEY="7F3F0DFD8E2BEC9B8A2310E6FBB80249"

# 获取本机外部 IP 地址
# 这里使用了一个免费的服务 "https://api.ipify.org"
# 你也可以使用其他类似的服务
IPV4=$(curl -4 ifconfig.me)
IPV6=$(curl -6 ifconfig.me)

# 检查是否成功获取 IP
if [[ -z "$IPV4" ]]; then
  echo "无法获取外部 IPV4 地址"
  exit 1
fi
if [[ -z "$IPV6" ]]; then
  echo "无法获取外部 IPV6 地址"
  exit 1
fi

# 调用 ip2location API 获取地理位置信息
RESPONSE_IPV4=$(curl -s "https://api.ip2location.io/?key=${API_KEY}&ip=${IPV4}")
RESPONSE_IPV6=$(curl -s "https://api.ip2location.io/?key=${API_KEY}&ip=${IPV6}")
# 检查 API 调用是否成功
if [[ -z "$RESPONSE_IPV4" ]]; then
  echo "无法从 ip2location API 获取V4信息"
  exit 1
fi
if [[ -z "$RESPONSE_IPV6" ]]; then
  echo "无法从 ip2location API 获取V6信息"
  exit 1
fi

# 使用 jq 解析 JSON 响应
# jq 是一个轻量级的命令行 JSON 处理工具
# 如果你的系统没有 jq，请先安装它 (例如: sudo apt-get install jq)
COUNTRY_4=$(echo "$RESPONSE_IPV4" | jq -r '.country_name')
REGION_4=$(echo "$RESPONSE_IPV4" | jq -r '.region_name')
CITY_4=$(echo "$RESPONSE_IPV4" | jq -r '.city_name')
ASN_4=$(echo "$RESPONSE_IPV4" | jq -r '.asn')
AS_4=$(echo "$RESPONSE_IPV4" | jq -r '.as')
Proxy_4=$(echo "$RESPONSE_IPV4" | jq -r '.is_proxy')

COUNTRY_6=$(echo "$RESPONSE_IPV6" | jq -r '.country_name')
REGION_6=$(echo "$RESPONSE_IPV6" | jq -r '.region_name')
CITY_6=$(echo "$RESPONSE_IPV6" | jq -r '.city_name')
ASN_6=$(echo "$RESPONSE_IPV6" | jq -r '.asn')
AS_6=$(echo "$RESPONSE_IPV6" | jq -r '.as')
Proxy_6=$(echo "$RESPONSE_IPV6" | jq -r '.is_proxy')

# 输出结果
echo "IP地址: $IPV4 
              $IPV6"
echo "国家: $COUNTRY_4
            $COUNTRY_6"
echo "地区: $REGION_4
            $REGION_6"
echo "城市: $CITY_4
            $CITY_6"
echo "ASN: $ASN_4
           $ASN_6"
echo "AS: $AS_4
          $AS_6"
echo "Proxy: $Proxy_4
             $Proxy_6"
