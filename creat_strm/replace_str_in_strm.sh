#!/bin/bash

# 读取用户输入
#echo "请输入目录路径:"
#read directory
#echo "请输入要替换的旧字符串:"
#read old_string
#echo "请输入新字符串:"
#read new_string

directory='/opt/media/'
old_string='/root/Downloads'
new_string="https://www.aster.love/d/115"
# 检查目录是否存在
if [ ! -d "$directory" ]; then
  echo "目录不存在: $directory"
  exit 1
fi

# 使用 "|" 作为分隔符来处理包含 "/" 的字符串
# 遍历目录下的所有 .strm 文件并替换字符串
find "$directory" -type f -name "*.strm" | while read file; do
  sed -i "s|$old_string|$new_string|g" "$file"
  echo "已处理文件: $file"
done

echo "完成所有替换。"