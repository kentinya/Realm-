## Realm转发脚本使用
### 功能
- 一键添加配置
- 一键安装、更新、删除Realm
- 支持安装包本地安装
- 查看存在的配置规则
- 支持tls,ws,wss加密
- 支持证书配置
- 启动与查看日志
### 安装脚本使用
``` bash
wget -N https://raw.githubusercontent.com/kentinya/Script-repository/refs/heads/main/Realm/realm_install.sh && chmod +x realm_install.sh
```
``` bash
bash realm_install.sh
```
### 添加tls
```bash
wget -N https://raw.githubusercontent.com/kentinya/Script-repository/refs/heads/main/Realm/realm_tls.sh && chmod +x realm_tls.sh
```
``` bash
bash realm_tls.sh
```
## 增加虚拟内存脚本
### 功能
- 增加VPS虚拟内存
### 使用
```bash
wget -N https://raw.githubusercontent.com/kentinya/Script-repository/main/addswap/addswap.sh && chmod +x addswap.sh
```
``` bash
bash addswap.sh
```

## ip2location判断ip
### 功能
- 判断ip

### 使用
```bash
wget -N https://raw.githubusercontent.com/kentinya/Script-repository/main/ip2location/checkip.sh && chmod +x checkip.sh
```
``` bash
bash checkip.sh
```
## 生成strm文件

### 功能
- 根据分类、文件路径和根路径自动生成strm文件到指定文件夹

### 使用
```bash
wget -N https://raw.githubusercontent.com/kentinya/Script-repository/main/creat_strm/create_strm.py && chmod +x create_strm.py
```
``` bash
python3 create_strm.py "保存路径" "内容路径" "分类"
```

## 修改strm内容

### 功能

-  修改strm文件内的路径

### 使用

```bash
wget -N https://raw.githubusercontent.com/kentinya/Script-repository/main/creat_strm/replace_str_in_strm.sh && chmod +x replace_str_in_strm.sh
```
```bash
bash replace_str_in_strm.sh
```

## gost转发脚本使用

### 安装
``` bash
wget -N https://raw.githubusercontent.com/kentinya/Script-repository/refs/heads/main/gost/gost_install.sh && chmod +x gost_install.sh
```
``` bash
bash gost_install.sh
```

### 节点

``` bash
wget -N https://raw.githubusercontent.com/kentinya/Script-repository/refs/heads/main/gost/add_gost.sh && chmod +x add_gost.sh
```
``` bash
bash add_gost.sh
```
