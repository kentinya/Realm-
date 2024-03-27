#!/bin/bash

red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'
RM_BASE_PATH="/opt/realm"
os_arch="unknown"
status="未安装"

install_base() {
    (command -v git >/dev/null 2>&1 && command -v curl >/dev/null 2>&1 && command -v wget >/dev/null 2>&1 && command -v unzip >/dev/null 2>&1 && command -v getenforce >/dev/null 2>&1 && command -v python3 >/dev/null 2>&1 && command -v jq >/dev/null 2>&1 && command -v tar >/dev/null 2>&1) ||
        (install_soft curl wget git unzip python3 jq tar )
}


pre_check() {
    ! command -v systemctl >/dev/null 2>&1 && echo "不支持此系统：未找到 systemctl 命令" && exit 1
    ! command -v yum >/dev/null 2>&1 && ! command -v apt >/dev/null 2>&1 && ! command -v apt-get >/dev/null 2>&1 && echo "不支持此系统：未找到 apt/yum 命令" && exit 1
    # check root
    [[ $EUID -ne 0 ]] && echo -e "${red}错误: ${plain} 必须使用root用户运行此脚本！\n" && exit 1
    ## os_arch
    if [[ $(uname -m | grep 'x86_64') != "" ]]; then
        os_arch="x86_64"
    elif [[ $(uname -m | grep 'aarch64\|armv8b\|armv8l') != "" ]]; then
        os_arch="aarch64"
    elif [[ $(uname -m | grep 'arm') != "" ]]; then
        os_arch="arm"
    fi
    if [ ! -d "$RM_BASE_PATH" ];then
        exixt="${red}未安装${plain}"
        local_version=""
        else
        if [ ! -f "$RM_BASE_PATH/realm" ];then
            exixt="${red}未安装${plain}"
            local_version=""
            else
            local_version="$(/opt/realm/realm -v | awk -F " " '{print $2}')"
            exixt="${green}$(/opt/realm/realm -v | awk -F " " '{print $2}')${plain}"
        fi
    fi
    if systemctl is-active --quiet realm.service; then
        status="${green}已运行${plain}"
        else
        status="${red}未运行${plain}"
    fi
    if [ ! -f "$RM_BASE_PATH/add_config.py" ];then
        add_add_config_py
    fi
    if [ ! -f "$RM_BASE_PATH/show_config.py" ];then
        add_show_config_py
    fi
    if [ ! -f "$RM_BASE_PATH/del_config.py" ];then
        add_del_config_py
    fi
}


before_show_menu() {
    echo && echo -n -e "${yellow}* 按回车返回主菜单 *${plain}" && read temp
    show_menu
}


install_soft() {
    (command -v yum >/dev/null 2>&1 && yum makecache && yum install $* selinux-policy -y) ||
        (command -v apt >/dev/null 2>&1 && apt update && apt install $* selinux-utils -y) ||
        (command -v apt-get >/dev/null 2>&1 && apt-get update && apt-get install $* selinux-utils -y)
}


change_config(){
    if [ ! -f "${RM_BASE_PATH}/config.json" ]; then
        echo -e "Realm可能未安装或不存在配置文件"
        echo && echo -n -e "${yellow}* 按回车返回主菜单 *${plain}" && read temp
        else
        nano ${RM_BASE_PATH}/config.json
    fi
    show_menu
}


install_realm(){
    install_base
    if [[ ${os_arch} == "unknown" ]];then
        echo -e "${red}暂不支持此架构二进制安装，请使用源码编译安装到${RM_BASE_PATH}目录${plain}"
        else
        if [[ $local_version != "" ]]; then
            echo -e "${red}您可能已经安装过Realm，当前版本为：${local_version}${plain}"
            echo "退出安装"
            else
            echo -e "> 安装Realm"
            install_base
            new_version=$(curl -sL --retry 2 --connect-timeout 2 https://api.github.com/repos/zhboner/realm/releases/latest | jq -r '.tag_name')
            if [ ! -n "$new_version" ]; then
                echo -e "${red}最新版本获取失败，请检查本机能否链接 api.github.com${plain}"
                read -e -r -p "请手动指定最新版本：" input
                new_version="${input}"
            fi
            echo -e "当前最新版本为: ${new_version}"
            mkdir $RM_BASE_PATH
            cd $RM_BASE_PATH
            if [[ ${os_arch} == "arm" ]];then
                path="realm.tar.gz"
                wget -t 1 -T 10 https://github.com/zhboner/realm/releases/download/${new_version}/realm-${os_arch}-unknown-linux-gnueabihf.tar.gz -O realm.tar.gz
                if [[ $? != 0 ]]; then
                    echo -e "${red}文件下载失败，请检查本机能否连接 ${GITHUB_RAW_URL}${plain}"
                    read -e -r -p "请手动文件路径(完整路径)：" input
                    path="${input}"
                fi
                else
                path="realm.tar.gz"
                wget -t 1 -T 10 https://github.com/zhboner/realm/releases/download/${new_version}/realm-${os_arch}-unknown-linux-gnu.tar.gz -O realm.tar.gz
                if [[ $? != 0 ]]; then
                    echo -e "${red}文件下载失败，请检查本机能否连接 ${GITHUB_RAW_URL}${plain}"
                    read -e -r -p "请手动文件路径(完整路径)：" input
                    path="${input}"
                fi
            fi
            tar -zxf "${path}" 
            if [[ $? != 0 ]]; then
                echo -e "${red}安装失败，检查安装包是否存在 ${GITHUB_RAW_URL}${plain}"
                else
                rm -rf "${path}"
                chmod +x realm
                touch config.json
                config_content='{
                "log": {
                    "level": "warn",
                    "output": "/opt/realm/realm.log"
                },
                "network": {
                    "no_tcp": false,
                    "use_udp": true
                },
                "endpoints": []
                }'
                echo "$config_content" > 'config.json'
                servce_config='[Unit]
                Description=realm
                After=network.target
                
                [Service]
                Type=simple
                User=root
                Restart=on-failure
                RestartSec=5s
                DynamicUser=no
                ExecStart=/opt/realm/realm -c /opt/realm/config.json
                
                [Install]
                WantedBy=multi-user.target'
                echo "$servce_config" > '/etc/systemd/system/realm.service'
                systemctl daemon-reload
                systemctl enable realm
                echo -e "${green}realm安装完成,并设置开机自启${plain}"
            fi
        fi
    fi
    before_show_menu
}


update_realm(){
    if [ ! -d "$RM_BASE_PATH" ];then
        echo -e "${red}realm未安装，请先安装realm${plain}"
        else
        if [ ! -f "$RM_BASE_PATH/realm" ];then
            echo -e "${red}realm未安装，请先安装realm${plain}"
            else
            echo "获取版本信息"
            new_version=$(curl -sL --retry 2 --connect-timeout 2 https://api.github.com/repos/zhboner/realm/releases/latest | jq -r '.tag_name')
            if [ ! -n "$new_version" ]; then
                echo -e "${red}最新版本获取失败，请检查本机能否链接 api.github.com${plain}"
                read -e -r -p "请手动指定最新版本：" input
                new_version="${input}"
            fi
            local_version=$(/opt/realm/realm -v | awk -F " " '{print $2}')
            echo -e "当前realm版本为：${green}v${local_version}${plain}，最新realm版本为：${green}${new_version}${plain}"
            if [[ $new_version == "v${local_version}" ]]; then
                echo -e "${green}当前已是最新版本，无需更新${plain}"
                else
                if systemctl is-active --quiet realm.service; then
                    echo "停止realm程序" && systemctl stop realm
                fi
                cd $RM_BASE_PATH
                echo "删除realm" && rm realm
                if [[ ${os_arch} == "arm" ]];then
                    path="realm.tar.gz"
                    wget -t 1 -T 10 https://github.com/zhboner/realm/releases/download/${new_version}/realm-${os_arch}-unknown-linux-gnueabihf.tar.gz -O realm.tar.gz
                    if [[ $? != 0 ]]; then
                        echo -e "${red}文件下载失败，请检查本机能否连接 ${GITHUB_RAW_URL}${plain}"
                        read -e -r -p "请手动文件路径(完整路径)：" input
                        path="${input}"
                    fi
                    else
                    path="realm.tar.gz"
                    wget -t 1 -T 10 https://github.com/zhboner/realm/releases/download/${new_version}/realm-${os_arch}-unknown-linux-gnu.tar.gz -O realm.tar.gz
                    if [[ $? != 0 ]]; then
                        echo -e "${red}文件下载失败，请检查本机能否连接 ${GITHUB_RAW_URL}${plain}"
                        read -e -r -p "请手动文件路径(完整路径)：" input
                        path="${input}"
                    fi
                fi
                tar -zxf "${path}" 
                if [[ $? != 0 ]]; then
                    echo -e "${red}安装失败，检查安装包是否存在 ${GITHUB_RAW_URL}${plain}"
                    else
                    rm "${path}"
                    chmod +x realm
                    systemctl start realm
                    if systemctl is-active --quiet realm.service; then
                        echo -e "${green}realm 更新完成，已自动启动${plain}"
                        else
                        echo -e "${red}realm 更新完成，启动失败${plain}"
                    fi
                fi
            fi
        fi
    fi
    before_show_menu
}


uninstall_realm(){
    if [ ! -d "$RM_BASE_PATH" ];then
        echo -e "${red}realm未安装，请先安装realm${plain}"
        else
        if systemctl is-active --quiet realm.service; then
            echo -e "${red}停止realm${plain}"
            systemctl stop realm
            else
            echo -e "${red}realm未运行${plain}"
        fi
        systemctl disable realm
        rm '/etc/systemd/system/realm.service'
        systemctl daemon-reload
        rm -rf $RM_BASE_PATH
        echo -e "${red}realm卸载完毕${plain}"
    fi
    before_show_menu
}

stop_realm(){
    if [ ! -d "$RM_BASE_PATH" ];then
        echo -e "${red}realm未安装，请先安装realm${plain}"
        else
        if systemctl is-active --quiet realm.service; then
            echo -e "${red}停止realm${plain}"
            systemctl stop realm
            else
            echo -e "${red}realm未运行${plain}"
        fi
    fi
    before_show_menu
}


start_realm(){
    if [ ! -d "$RM_BASE_PATH" ];then
        echo -e "${red}realm未安装，请先安装realm${plain}"
        else
        if systemctl is-active --quiet realm.service; then
            echo -e "realm 已在运行"
            else
            systemctl start realm
            if systemctl is-active --quiet realm.service; then
                echo -e "${green}realm 启动成功${plain}"
                else
                echo -e "${red}realm 启动失败${plain}"
            fi    
        fi
    fi
    before_show_menu
}

restart_realm(){
    if [ ! -d "$RM_BASE_PATH" ];then
        echo -e "${red}realm未安装，请先安装realm${plain}"
        else
        if systemctl is-active --quiet realm.service; then
            systemctl restart realm
            if systemctl is-active --quiet realm.service; then
                echo -e "${green}realm 重启成功${plain}"
                else
                echo -e "${red}realm 重启失败${plain}"
            fi
            else
            echo -e "${red}realm未运行${plain}"
        fi
    fi
    before_show_menu
}


show_realm_status(){
    if [ ! -d "$RM_BASE_PATH" ];then
        echo -e "${red}realm未安装，请先安装realm${plain}"
        else
        systemctl status realm.service
    fi
    before_show_menu
}

add_add_config_py(){
    cat << 'EOF' >$RM_BASE_PATH/add_config.py
import json

def main():
    local_ip = input("请输入监听IP(默认为[::]):")
    if local_ip == "":
        local_ip = "[::]"
    local_port = input("请输入监听端口:")
    listen = f"{local_ip}:{local_port}" 
    remote_ip = input("请输入转发IP(默认为[::]):")
    if remote_ip == "":
        remote_ip = "[::]"
    remote_port = input("请输入转发端口:")
    remote = f"{remote_ip}:{remote_port}"
    return listen,remote

def encrypt():
    print("1.tls\n2.ws\n3.wss\n")
    n = input("选择加密方式:")
    while 1:
        if int(n) == 1:
            method = "tls"
            sni = input("请输入sni：")
            while 1:
                insecure = input("是否使用证书(y/n,默认为n):")
                if insecure == "n" or insecure == "":            
                    remote_transport = f"{method};sni={sni};insecure"
                    break
                elif insecure == "y":
                    remote_transport = f"{method};sni={sni}"
                    break
                else:
                    print("输入错误，请重新输入")
                    continue
            break
        elif int(n) == 2:
            method = "ws"
            host = input("请输入host:")
            path = input("请输入路径（带/）:")
            remote_transport = f"{method};host={host};path={path}"
            break
        elif int(n) == 3:
            method_1 = "ws"
            method_2 = "tls"
            host = input("请输入host:")
            path = input("请输入路径（带/）:")
            sni = host
            while 1:
                insecure = input("是否使用证书(y/n,默认为n):")
                if insecure == "y": 
                    remote_transport = f"{method_1};host={host};path={path};{method_2};sni={sni}"
                    break
                elif insecure == "n" or insecure == "":
                    remote_transport = f"{method_1};host={host};path={path};{method_2};sni={sni};insecure"
                    break
                else:
                    print("输入错误请重新输入！")
                    continue
            break
        else:
            print("输入错误，请重新输入！")
            continue
    return remote_transport

def decrypt():
    print("1.tls\n2.ws\n3.wss\n")
    n = input("选择解密方式:")
    while 1:         
        if int(n) == 1:
            method = "tls"
            while 1:
                insecure = input("是否使用证书(y/n,默认为n):")
                if insecure == "y": 
                    cert_path = input("请输入证书路径：") 
                    key_path = input("请输入密钥路径：") 
                    listen_transport = f"{method};cert={cert_path};key={key_path}"
                    break
                elif insecure == "n" or insecure == "":
                    servername=input("请输入servername：")
                    listen_transport = f"{method};servername={servername}"
                    break
                else:
                    print("输入错误请重新输入！")
                    continue
            break
        elif int(n) == 2:
            method = "ws"
            host = input("请输入host:")
            path = input("请输入路径（带/）:")
            listen_transport = f"{method};host={host};path={path}"
            break
        elif int(n) == 3:
            method_1 = "ws"
            method_2 = "tls"
            host = input("请输入host:")
            path = input("请输入路径（带/）:")
            servername = host
            while 1:
                insecure = input("是否使用证书(y/n,默认为n):")
                if insecure == "y": 
                    cert_path = input("请输入证书路径：") 
                    key_path = input("请输入密钥路径：") 
                    listen_transport = f"{method_1};host={host};path={path};{method_2};cert={cert_path};key={key_path}"
                    break
                elif insecure == "n" or insecure == "":
                    listen_transport = f"{method_1};host={host};path={path};{method_2};servername={servername}"
                    break
                else:
                    print("输入错误请重新输入！")
                    continue
            break
        else:
            print("输入错误请重新输入！")
            continue
    return listen_transport

def add_config():
    file_name = "/opt/realm/config.json"
    with open(file_name, 'r', encoding='utf-8') as file:
        data = json.load(file)
    endpoints = data["endpoints"]
    port = main()
    listen = port[0]
    remote = port[1]
    print("1.加密\n2.解密\n3.直接转发")
    type = input("请输入转发方式(默认为直接转发)：")
    while 1:
        if int(type) == 1:
            remote_transport = encrypt()
            endpoints_config = {"listen":listen,"remote":remote,"remote_transport":remote_transport}
            break
        elif int(type) == 2:
            listen_transport = decrypt()
            endpoints_config = {"listen":listen,"remote":remote,"listen_transport":listen_transport}
            break
        elif int(type) == 3 or type == "":
            endpoints_config = {"listen":listen,"remote":remote}
            break
        else:
            print("输入错误请重新输入！")
            continue
    endpoints.append(endpoints_config)
    with open(file_name, 'w', encoding='utf-8') as file:
        json.dump(data, file, indent=2, ensure_ascii=False)
    print("规则添加成功",endpoints[-1]) 

add_config()
EOF
}

add_show_config_py(){
    cat << 'EOF' > $RM_BASE_PATH/show_config.py
import json
def show_config():
    file_name = "/opt/realm/config.json"
    with open(file_name, 'r', encoding='utf-8') as file:
        data = json.load(file)
    endpoints = data["endpoints"]
    if len(endpoints) > 0:
        i = 0 
        while i < len(endpoints):
            endpoint = endpoints[i]
            listen = endpoint.get("listen")
            remote = endpoint.get("remote")
            transport_value = endpoint.get("listen_transport") or endpoint.get("remote_transport")
            if transport_value:
                transport = transport_value.split(";")
                if len(transport) < 5:
                    if transport[0] == "tls":
                        print(f"{i+1}.{transport[0]}://{listen} -> {remote} | {transport[1].split('=')[1]}")
                    else:
                        print(f"{i+1}.ws://{listen} -> {remote} | {transport[1].split('=')[1]}{transport[2].split('=')[1]}")
                else:
                    print(f"{i+1}.wss://{listen} -> {remote} | {transport[1].split('=')[1]}{transport[2].split('=')[1]}")
            else:
                print(f"{i+1}.{listen} -> {remote}")
            i += 1 
    else:
        print("暂无规则")
show_config()
EOF
}

add_del_config_py(){
    cat << 'EOF' > $RM_BASE_PATH/del_config.py
import json
    
def del_config():
    file_name = "/opt/realm/config.json"
    with open(file_name, 'r', encoding='utf-8') as file:
        data = json.load(file)
    endpoints = data["endpoints"]
    if len(endpoints) > 0:
        i = 0 
        while i < len(endpoints):
            endpoint = endpoints[i]
            listen = endpoint.get("listen")
            remote = endpoint.get("remote")
            transport_value = endpoint.get("listen_transport") or endpoint.get("remote_transport")
            if transport_value:
                transport = transport_value.split(";")
                if len(transport) < 5:
                    if transport[0] == "tls":
                        print(f"{i+1}.{transport[0]}://{listen} -> {remote} | {transport[1].split('=')[1]}")
                    else:
                        print(f"{i+1}.ws://{listen} -> {remote} | {transport[1].split('=')[1]}{transport[2].split('=')[1]}")
                else:
                    print(f"{i+1}.wss://{listen} -> {remote} | {transport[1].split('=')[1]}{transport[2].split('=')[1]}")
            else:
                print(f"{i+1}.{listen} -> {remote}")
            i += 1
        n = int(input("请输入要删除的规则："))
        del data["endpoints"][n-1]
        print("规则删除完成")
    else:
        print("暂无规则")
    with open(file_name, 'w', encoding='utf-8') as file:
        json.dump(data, file, indent=2, ensure_ascii=False)
    
del_config()  
EOF
}

add_config(){
    if [ ! -d "$RM_BASE_PATH" ];then
        echo -e "${red}realm未安装，请先安装realm${plain}"
        else
        if [ ! -f "$RM_BASE_PATH/config.json" ];then
            echo -e "${red}未发现配置文件${plain}"
        fi
        if [ ! -f "$RM_BASE_PATH/add_config.py" ];then
            echo -e "${red}未发现python文件${plain}"
            else
            python3 $RM_BASE_PATH/add_config.py
            systemctl restart realm
            if systemctl is-active --quiet realm.service; then
                echo -e "${green}realm 重启成功${plain}"
                else
                echo -e "${red}realm 重启失败${plain}"
            fi
        fi
    fi
    before_show_menu
}


show_config(){
    if [ ! -d "$RM_BASE_PATH" ];then
        echo -e "${red}realm未安装，请先安装realm${plain}"
        else
        if [ ! -f "$RM_BASE_PATH/config.json" ];then
            echo -e "${red}未发现配置文件${plain}"
        fi
        if [ ! -f "$RM_BASE_PATH/add_config.py" ];then
            echo -e "${red}未发现python文件${plain}"
            else
            python3 $RM_BASE_PATH/show_config.py
        fi
    fi
    before_show_menu
}


del_config(){
    if [ ! -d "$RM_BASE_PATH" ];then
        echo -e "${red}realm未安装，请先安装realm${plain}"
        else
        if [ ! -f "$RM_BASE_PATH/config.json" ];then
            echo -e "${red}未发现配置文件${plain}"
        fi
        if [ ! -f "$RM_BASE_PATH/del_config.py" ];then
            echo -e "${red}未发现python文件${plain}"
            else
            python3 $RM_BASE_PATH/del_config.py
            if systemctl is-active --quiet realm.service; then
                systemctl restart realm
                if systemctl is-active --quiet realm.service; then
                    echo -e "${green}realm 重启成功${plain}"
                    else
                    echo -e "${red}realm 重启失败${plain}"
                fi
            fi
        fi
    fi
    before_show_menu
}


show_menu() {
    pre_check
    cd ~
    clear
    echo -e "
  ${green}Realm一键管理脚本${plain} 
--- https://github.com/kentinya/Realm-mangescript --- 
  ${green}0.${plain}  修改配置
——————————————————
  ${green}1.${plain}  安装 Realm

  ${green}2.${plain}  更新 Realm

  ${green}3.${plain}  卸载 Realm
——————————————————
  ${green}4.${plain}  停止 Realm

  ${green}5.${plain}  重启 Realm

  ${green}6.${plain}  启动 Realm

  ${green}7.${plain}  查看 Realm 状态
——————————————————
  ${green}8.${plain}  增加 Realm 配置

  ${green}9.${plain}  删除 Realm 配置

  ${green}10.${plain} 查看 Realm 配置
——————————————————
  ${green}11.${plain} 退出脚本

Realm运行状态：${status},Realm版本：${exixt}
    "
    echo && read -ep "请输入选择 [0-13]: " num
    case "${num}" in
        0)
            change_config
            ;;
        1)
            install_realm
            ;;
        2)
            update_realm
            ;;
        3)
            uninstall_realm
            ;;
        4)
            stop_realm
            ;;
        5)
            restart_realm
            ;;
        6)
            start_realm
            ;;
        7)
            show_realm_status
            ;;
        8)
            add_config
            ;;
        9)
            del_config
            ;;
        10)
            show_config
            ;;
        11)
            exit 0
            ;;
        *)
            echo -e "${red}请输入正确的数字 [0-13]${plain}"
            ;;
        esac
}

show_menu