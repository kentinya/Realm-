#!/bin/bash
red='\033[0;31m'
green='\033[0;32m'
plain='\033[0m'

num=$1
LOCAL_PORT=$2
FORWARD_IP=$3
FORWARD_PORT=$4
Listen_IP=$5

forward_l(){
if [ -z "$LOCAL_PORT" ]; then
    read -p "请输入本地IP (Listen_IP): " Listen_IP
    read -p "请输入本地端口 (LOCAL_PORT): " LOCAL_PORT
    read -p "请输入转发IP (FORWARD_IP): " FORWARD_IP
    read -p "请输入转发端口 (FORWARD_PORT): " FORWARD_PORT
fi

SERVICE_FILE="/etc/systemd/system/realm${LOCAL_PORT}.service"
cat <<EOL > $SERVICE_FILE
[Unit]
Description=realm${LOCAL_PORT}
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
ExecStart=/opt/realm/realm -l ${Listen_IP}:${LOCAL_PORT} -r ${FORWARD_IP}:${FORWARD_PORT} -a tls;servername=apple.com
ExecReload=/bin/kill -HUP 
ExecStop=/bin/kill 
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOL

# 重新加载 systemd 管理器配置
systemctl daemon-reload

# 启用并启动服务
systemctl enable realm${LOCAL_PORT}
systemctl start realm${LOCAL_PORT}

# 打印服务状态
systemctl status realm${LOCAL_PORT}
}

forward_r(){
if [ -z "$LOCAL_PORT" ]; then
    read -p "请输入本地IP (Listen_IP): " Listen_IP
    read -p "请输入本地端口 (LOCAL_PORT): " LOCAL_PORT
    read -p "请输入转发IP (FORWARD_IP): " FORWARD_IP
    read -p "请输入转发端口 (FORWARD_PORT): " FORWARD_PORT
fi

SERVICE_FILE="/etc/systemd/system/realm${LOCAL_PORT}.service"
cat <<EOL > $SERVICE_FILE
[Unit]
Description=realm${LOCAL_PORT}
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
ExecStart=/opt/realm/realm -l ${Listen_IP}:${LOCAL_PORT} -r ${FORWARD_IP}:${FORWARD_PORT} -b tls;sni=apple.com;insecure 
ExecReload=/bin/kill -HUP 
ExecStop=/bin/kill 
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOL

# 重新加载 systemd 管理器配置
systemctl daemon-reload

# 启用并启动服务
systemctl enable realm${LOCAL_PORT}
systemctl start realm${LOCAL_PORT}

# 打印服务状态
systemctl status realm${LOCAL_PORT}
}


del_realm(){
if [ -z "$LOCAL_PORT" ]; then
    read -p "请输入本地端口 (LOCAL_PORT): " LOCAL_PORT
fi
SERVICE_FILE="/etc/systemd/system/realm${LOCAL_PORT}.service"
systemctl stop realm${LOCAL_PORT}
systemctl disable realm${LOCAL_PORT}
rm -f $SERVICE_FILE
systemctl daemon-reload
}

show_menu() {    
    echo -e "
  ${green}realm直接转发${plain} 

  ${green}1.${plain}  添加 转发

  ${green}2.${plain}  删除 转发

  ${green}0.${plain} 退出脚本

    "
    echo && read -ep "请输入选择 [0-13]: " num
    case "${num}" in
        1)
            forward_l
            ;;
        2)
            forward_r
            ;;
        3)
            del_realm
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
        forward_l
    fi
    if [[ $num == 2 ]]; then
        forward_r
    fi
    if [[ $num == 3 ]]; then
        del_realm
    fi
fi


