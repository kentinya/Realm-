#!/bin/bash
red='\033[0;31m'
green='\033[0;32m'
plain='\033[0m'

num=$1
LOCAL_PORT=$2
FORWARD_IP=$3
FORWARD_PORT=$4

encrypt(){
if [ -z "$LOCAL_PORT" ]; then
    read -p "请输入本地端口 (LOCAL_PORT): " LOCAL_PORT
    read -p "请输入转发IP (FORWARD_IP): " FORWARD_IP
    read -p "请输入转发端口 (FORWARD_PORT): " FORWARD_PORT
fi

SERVICE_FILE="/etc/systemd/system/gost${LOCAL_PORT}.service"
cat <<EOL > $SERVICE_FILE
[Unit]
Description=gost${LOCAL_PORT}
After=network.target
Wants=network.target

[Service]
Type=simple
StandardError=journal
User=root
LimitAS=infinity
LimitCORE=infinity
LimitNOFILE=102400
LimitNPROC=102400
TimeoutStartSec=5
ExecStart=/opt/gost/gost -L tcp://:${LOCAL_PORT} -L udp://:${LOCAL_PORT} -F relay+tls://${FORWARD_IP}:${FORWARD_PORT}
ExecReload=/bin/kill -HUP 
ExecStop=/bin/kill 
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOL

# 重新加载 systemd 管理器配置
systemctl daemon-reload

# 启用并启动服务
systemctl enable gost${LOCAL_PORT}
systemctl start gost${LOCAL_PORT}

# 打印服务状态
systemctl status gost${LOCAL_PORT}
}

decrypt(){
if [ -z "$LOCAL_PORT" ]; then
    read -p "请输入本地端口 (LOCAL_PORT): " LOCAL_PORT
    read -p "请输入转发IP (FORWARD_IP): " FORWARD_IP
    read -p "请输入转发端口 (FORWARD_PORT): " FORWARD_PORT
fi
SERVICE_FILE="/etc/systemd/system/gost${LOCAL_PORT}.service"

# 写入服务单元文件的内容
cat <<EOL > $SERVICE_FILE
[Unit]
Description=gost${LOCAL_PORT}
After=network.target
Wants=network.target

[Service]
Type=simple
StandardError=journal
User=root
LimitAS=infinity
LimitCORE=infinity
LimitNOFILE=102400
LimitNPROC=102400
TimeoutStartSec=5
ExecStart=/opt/gost/gost -L relay+tls://:${LOCAL_PORT}/${FORWARD_IP}:${FORWARD_PORT}
ExecReload=/bin/kill -HUP 
ExecStop=/bin/kill 
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOL

# 重新加载 systemd 管理器配置
systemctl daemon-reload

# 启用并启动服务
systemctl enable gost${LOCAL_PORT}
systemctl start gost${LOCAL_PORT}

# 打印服务状态
systemctl status gost${LOCAL_PORT}

}

del_gost(){
if [ -z "$LOCAL_PORT" ]; then
    read -p "请输入本地端口 (LOCAL_PORT): " LOCAL_PORT
fi
SERVICE_FILE="/etc/systemd/system/gost${LOCAL_PORT}.service"
systemctl stop gost${LOCAL_PORT}
systemctl disable gost${LOCAL_PORT}
rm -f $SERVICE_FILE
systemctl daemon-reload
}

show_menu() {    
    echo -e "
  ${green}gost更改配置脚本${plain} 

  ${green}1.${plain}  添加 tls加密

  ${green}2.${plain}  添加 tls解密

  ${green}3.${plain}  删除 gost规则

  ${green}0.${plain} 退出脚本

    "
    echo && read -ep "请输入选择 [0-13]: " num
    case "${num}" in
        1)
            encrypt
            ;;
        2)
            decrypt
            ;;
        3)
            del_gost
            ;;
        0)
            exit 0
            ;;
        *)
            echo -e "${red}请输入正确的数字 [0-2]${plain}"
            ;;
        esac
}

if [ ! -n "$num" ]; then
    show_menu
    else
    if [[ $num == 1 ]]; then
        encrypt
    fi
    if [[ $num == 2 ]]; then
        decrypt
    fi
    if [[ $num == 3 ]]; then
        del_gost
    fi
fi


