import os
import time
import platform
import requests
import tarfile
import json
import subprocess
import io
import psutil
from urllib.parse import urlparse
def is_ip_in_china():
    # 使用ip-api.com提供的免费服务获取IP地理位置信息
    response = requests.get('https://myip.ipip.net/json')
    response.raise_for_status()  # 如果请求失败，抛出异常
    data = response.json()   
    # 检查API调用是否成功
    if data["ret"] != 'ok':
        print(f"API调用失败: {data.get('message', '未知错误')}")       
    # 如果国家代码是'CN'，则IP位于中国
    return data['data']['location'][0]


def is_url(input_string):
    try:
        result = urlparse(input_string)
        # 确保结果有网络协议和网络位置部分
        return all([result.scheme, result.netloc])
    except Exception:
        return False


def install():
    base_path = "/opt/realm/"
    if not os.path.exists(os.path.dirname(base_path)):
        os.makedirs(os.path.dirname(base_path))
    os_type = platform.system()
    cpu_architecture = platform.machine()
    print("操作系统名称：", os_type)
    print("CPU架构：", cpu_architecture)
    if is_ip_in_china() != '中国':
        response = requests.get("https://api.github.com/repos/zhboner/realm/releases/latest")
        tar_name = response.json()["tag_name"]
        print("当前最新版本为:",tar_name)   
        path = "/realm-" + cpu_architecture + "-unknown-linux-musl.tar.gz"
        url = "https://github.com/zhboner/realm/releases/download/" + tar_name + path
        print("正在下载最新Realm")
        file = requests.get(url)
        if file.status_code == 200:
            with tarfile.open(fileobj=io.BytesIO(file.content), mode='r:gz') as tar:
                tar.extractall(path=base_path,filter=tarfile.fully_trusted_filter)
        else:
            print(file.status_code)
    else:
        while 1:
            file = input("手动指定文件位置/Url(需要为gz文件)：")
            if not is_url(file):
                print("输入的是一个文件")
                if not os.path.exists(file):
                    print("Realm文件不存在,请重新输入！")
                    continue
                else:
                    with tarfile.open(file, mode='r:gz') as tar:
                        tar.extractall(path=base_path,filter=tarfile.fully_trusted_filter)
            elif is_url(file):
                print("输入的是一个url")
                file = requests.get(file)
                if file.status_code == 200:
                    with tarfile.open(fileobj=io.BytesIO(file.content), mode='r:gz') as tar:
                        tar.extractall(path=base_path,filter=tarfile.fully_trusted_filter)
                else:
                    print(file.status_code)
                    continue
            break
    print("解压Realm到目标目录：",base_path)
    os.chmod(base_path, 0o755) #调整权限
    print("授予Realm执行权限")
    config_path = os.path.join(os.path.dirname(base_path),"config.json") #创建配置文件
    config_content = {
        "log": {
            "level": "warn",
            "output": "/opt/realm/realm.log"
        },
        "network": {
            "no_tcp": bool(0),
            "use_udp": bool(1)
        },
        "endpoints": []
    } #部分内容
    with open(config_path, 'w') as f:
        json.dump(config_content, f)
    servce_config = """
        [Unit]
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
        WantedBy=multi-user.target
    """
    with open('/etc/systemd/system/realm.service', 'w') as service_file:
        service_file.write(servce_config)
    subprocess.run(['sudo', 'systemctl', 'daemon-reload'])
    subprocess.run(['sudo', 'systemctl', 'enable', 'realm.service'])
    input("安装完成！按任意键继续...")

def uninstall():
    subprocess.run(['sudo', 'systemctl', 'stop', 'realm.service'])
    subprocess.run(['sudo', 'systemctl', 'disable', 'realm.service'])
    subprocess.run(['sudo', 'rm', '-rf', '/opt/realm/'])
    subprocess.run(['sudo', 'rm', '-rf', '/etc/systemd/system/realm.service'])
    subprocess.run(['sudo', 'systemctl', 'daemon-reload'])
    print("卸载完成，可以删除本脚本：rm -rf realm.py")


def check_status():
    command = "systemctl status realm.service"
    process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    stdout, stderr = process.communicate()
    print(stdout)
    if stderr:
        print("错误输出:")
        print(stderr)


def is_process_running(process_name):
    for process in psutil.process_iter():
        try:
            if process_name.lower() in process.name().lower():
                return True
        except (psutil.NoSuchProcess, psutil.AccessDenied, psutil.ZombieProcess):
            pass
    return False


def stop():
    subprocess.run(['sudo', 'systemctl', 'stop', 'realm.service'])
    time.sleep(0.5)
    if not is_process_running("realm"):
        input("Realm停止成功，按任意键继续...")


def start():
    subprocess.run(['sudo', 'systemctl', 'start', 'realm.service'])
    time.sleep(0.5)
    if is_process_running("realm"):
        input("Realm启动成功，按任意键继续...")
    else:
        input("Realm启动失败，按任意键继续...")
    


def show_log():
    subprocess.run(['cat', '/opt/realm/realm.log'])


def restart():
    subprocess.run(['sudo', 'systemctl', 'restart', 'realm.service'])
    time.sleep(0.5)
    print("Realm服务重启成功！按任意键继续...")


def del_config():
    file_name = "/opt/realm/config.json"
    with open(file_name, 'r', encoding='utf-8') as file:
        data = json.load(file)
    if len(data["endpoints"]) > 0:
        i = 0 
        while i < len(data["endpoints"]):
            if "listen_transport" in data["endpoints"][i]:
                if "tls" in data["endpoints"][i]["listen_transport"]:
                    print(i+1,":","tls://",data["endpoints"][i]["listen"],"->",data["endpoints"][i]["remote"])
                    i += 1
                    continue
                elif "ws" in data["endpoints"][i]["listen_transport"]:
                    print(i+1,":","ws://",data["endpoints"][i]["listen"],"->",data["endpoints"][i]["remote"])
                    i += 1
                    continue
                elif "wss" in data["endpoints"][i]["listen_transport"]:
                    print(i+1,":","wss://",data["endpoints"][i]["listen"],"->",data["endpoints"][i]["remote"])
                    i += 1
                    continue
            elif "remote_transport" in data["endpoints"][i]:
                if "tls" in data["endpoints"][i]["remote_transport"]:
                    print(i+1,":","tls://",data["endpoints"][i]["listen"],"->",data["endpoints"][i]["remote"])
                    i += 1
                    continue
                elif "ws" in data["endpoints"][i]["remote_transport"]:
                    print(i+1,":","ws://",data["endpoints"][i]["listen"],"->",data["endpoints"][i]["remote"])
                    i += 1
                    continue
                elif "wss" in data["endpoints"][i]["remote_transport"]:
                    print(i+1,":","wss://",data["endpoints"][i]["listen"],"->",data["endpoints"][i]["remote"])
                    i += 1
                    continue
            else:
                print(i+1,":",data["endpoints"][i]["listen"],"->",data["endpoints"][i]["remote"])
                i += 1
                continue
            
        n = int(input("请输入要删除的规则："))
        del data["endpoints"][n-1]
        with open(file_name, 'w', encoding='utf-8') as file:
            json.dump(data, file, indent=2, ensure_ascii=False)
        time.sleep(0.5)
        print("规则删除完成")
        time.sleep(0.3)
        #restart()
        print("Realm服务重启成功！")
    else:
        print("暂无规则")


def show_config():
    file_name = "/opt/realm/config.json"
    with open(file_name, 'r', encoding='utf-8') as file:
        data = json.load(file)
    if len(data["endpoints"]) > 0:
        i = 0 
        while i < len(data["endpoints"]):
            if "listen_transport" in data["endpoints"][i]:
                if "tls" in data["endpoints"][i]["listen_transport"]:
                    print(i+1,":","tls://",data["endpoints"][i]["listen"],"->",data["endpoints"][i]["remote"])
                    i += 1
                    continue
                elif "ws" in data["endpoints"][i]["listen_transport"]:
                    print(i+1,":","ws://",data["endpoints"][i]["listen"],"->",data["endpoints"][i]["remote"])
                    i += 1
                    continue
                elif "wss" in data["endpoints"][i]["listen_transport"]:
                    print(i+1,":","wss://",data["endpoints"][i]["listen"],"->",data["endpoints"][i]["remote"])
                    i += 1
                    continue
            elif "remote_transport" in data["endpoints"][i]:
                if "tls" in data["endpoints"][i]["remote_transport"]:
                    print(i+1,":","tls://",data["endpoints"][i]["listen"],"->",data["endpoints"][i]["remote"])
                    i += 1
                    continue
                elif "ws" in data["endpoints"][i]["remote_transport"]:
                    print(i+1,":","ws://",data["endpoints"][i]["listen"],"->",data["endpoints"][i]["remote"])
                    i += 1
                    continue
                elif "wss" in data["endpoints"][i]["remote_transport"]:
                    print(i+1,":","wss://",data["endpoints"][i]["listen"],"->",data["endpoints"][i]["remote"])
                    i += 1
                    continue
            else:
                print(i+1,":",data["endpoints"][i]["listen"],"->",data["endpoints"][i]["remote"])
                i += 1
                continue



def check_pythonversion():
    version = platform.python_version()
    if version < "3.12.2":
        print("当前版本：",version,"无法使用本脚本，建议升级至：",version,"以上")


def add_config():
    file_name = "/opt/realm/config.json"
    with open(file_name, 'r', encoding='utf-8') as file:
        data = json.load(file)
    endpoints = data["endpoints"]
    local_ip = input("请输入监听IP(默认为[::]):")
    if local_ip == "":
        local_ip = "[::]"
    local_port = input("请输入监听端口:")
    listen = local_ip + ":" + local_port 
    remote_ip = input("请输入转发IP(默认为[::]):")
    if remote_ip == "":
        remote_ip = "[::]"
    remote_port = input("请输入转发端口:")
    remote = remote_ip + ":" + remote_port
    while 1:
        print("1.加密\n2.解密\n3.直接转发")
        type = input("请输入转发方式(默认为直接转发)：")
        if type == "2":
            print("1.tls\n2.ws\n3.wss\n")
            while 1:
                method = input("选择解密方式:")
                if method == "1":
                    method = "tls"
                    while 1:
                        insecure = input("是否使用证书(y/n,默认为n):")
                        if insecure == "y": 
                            cert_path = input("请输入证书路径：") 
                            key_path = input("请输入密钥路径：") 
                            listen_transport = method + ";cert=" + cert_path + ";key=" + key_path
                        elif insecure == "n" or insecure == "":
                            servername=input("请输入servername：")
                            listen_transport = method + ";servername=" + servername
                        else:
                            print("输入错误请重新输入！")
                            continue
                        endpoints_config = {"listen":listen,"remote":remote,"listen_transport":listen_transport}
                        endpoints.append(endpoints_config)
                        print("规则添加成功",endpoints[-1])
                        break
                    break
                elif method == "2":
                    method = "ws"
                    host = input("请输入host:")
                    path = input("请输入路径（带/）:")
                    listen_transport = method + ";host=" + host + ";path=" + path
                    endpoints_config = {"listen":listen,"remote":remote,"listen_transport":listen_transport}
                    endpoints.append(endpoints_config)
                    print("规则添加成功",endpoints[-1])
                    break
                elif method == "3":
                    method_1 = "ws"
                    method_2 = "tls"
                    host = input("请输入host:")
                    path = input("请输入路径（带/）:")
                    while 1:
                        insecure = input("是否使用证书(y/n,默认为n):")
                        if insecure == "y": 
                            cert_path = input("请输入证书路径：") 
                            key_path = input("请输入密钥路径：") 
                            listen_transport = method_1 + ";host=" + host + ";path=" + path + ";" + method_2 + ";cert=" + cert_path + ";key=" + key_path
                        elif insecure == "n" or insecure == "":
                            servername = host
                            listen_transport = method_1 + ";host=" + host + ";path=" + path + ";" + method_2 + ";servername=" + servername
                        else:
                            print("输入错误请重新输入！")
                            continue
                        endpoints_config = {"listen":listen,"remote":remote,"listen_transport":listen_transport}
                        endpoints.append(endpoints_config)
                        print("规则添加成功",endpoints[-1])
                        break
                    break
                else:
                    print("输入错误请重新输入！")
                    continue
            break
        elif type == "1":
            print("1.tls\n2.ws\n3.wss\n")
            while 1:
                method = input("选择加密方式:")
                if method == "1":
                    method = "tls"
                    sni = input("请输入sni：")
                    while 1:
                        insecure = input("是否使用证书(y/n,默认为n):")
                        if insecure == "n":            
                            remote_transport = method + ";sni=" + sni + ";insecure"
                        elif insecure == "y" or insecure == "":
                            remote_transport = method + ";sni=" + sni
                        else:
                            print("输入错误，请重新输入")
                            continue
                        endpoints_config = {"listen":listen,"remote":remote,"remote_transport":remote_transport}
                        endpoints.append(endpoints_config)
                        print("规则添加成功",endpoints[-1])
                    break
                elif method == "2":
                    method = "ws"
                    host = input("请输入host:")
                    path = input("请输入路径（带/）:")
                    remote_transport = method + ";host=" + host + ";path=" + path
                    endpoints_config = {"listen":listen,"remote":remote,"remote_transport":remote_transport}
                    endpoints.append(endpoints_config)
                    print("规则添加成功",endpoints[-1])
                    break
                elif method == "3":
                        method_1 = "ws"
                        method_2 = "tls"
                        host = input("请输入host:")
                        path = input("请输入路径（带/）:")
                        sni = host
                        while 1:
                            insecure = input("是否使用证书(y/n,默认为n):")
                            if insecure == "y": 
                                remote_transport = method_1 + ";host=" + host + ";path=" + path + ";" + method_2 + ";sni=" + sni
                            elif insecure == "n" or insecure == "":
                                remote_transport = method_1 + ";host=" + host + ";path=" + path + ";" + method_2 + ";sni=" + sni + ";insecure"
                            else:
                                print("输入错误请重新输入！")
                                continue
                            endpoints_config = {"listen":listen,"remote":remote,"remote_transport":remote_transport}
                            endpoints.append(endpoints_config)
                            print("规则添加成功",endpoints[-1])
                            break
                        break
                else:
                    print("输入错误，请重新输入！")
                    continue
            break
        elif type == "3" or type == "":
            endpoints_config = {"listen":listen,"remote":remote}
            endpoints.append(endpoints_config)
            print("规则添加成功",endpoints[-1])
            break
        else:
            print("输入错误请重新输入！")
            continue
    with open(file_name, 'w', encoding='utf-8') as file:
        json.dump(data, file, indent=2, ensure_ascii=False) 


def update_realm():
    subprocess.run(['sudo', 'systemctl', 'stop', 'realm.service'])
    time.sleep(0.5)
    if not is_process_running("realm"):
        print("停止Realm成功")
    else:
        print("检查Realm是否已安装")
    base_path = "/opt/realm/"
    if not os.path.exists(os.path.dirname(base_path)):
        print("检查Realm是否已安装")
    else:
        subprocess.run(['sudo', 'rm', '-rf', '/opt/realm/realm'])
        time.sleep(0.5)
        print("删除Realm旧版本")
        #os_type = platform.system()
        if is_ip_in_china() != '中国':
            cpu_architecture = platform.machine()
            #print("操作系统名称：", os_type)
            #print("CPU架构：", cpu_architecture)
            response = requests.get("https://api.github.com/repos/zhboner/realm/releases/latest")
            tar_name = response.json()["tag_name"]
            print("当前最新版本为",tar_name)   
            path = "/realm-" + cpu_architecture + "-unknown-linux-gnu.tar.gz"
            url = "https://github.com/zhboner/realm/releases/download/" + tar_name + path
        #print(url)
            file = requests.get(url)
            if file.status_code == 200:
                with tarfile.open(fileobj=io.BytesIO(file.content), mode='r:gz') as tar:
                    tar.extractall(path=base_path,filter=tarfile.fully_trusted_filter)
            else:
                print(file.status_code)
        else:
            while 1:
                file = input("手动指定文件位置/Url(需要为gz文件)：")
                if not is_url(file):
                    print("输入的是一个文件")
                    if not os.path.exists(file):
                        print("Realm文件不存在,请重新输入！")
                        continue
                    else:
                        with tarfile.open(file, mode='r:gz') as tar:
                            tar.extractall(path=base_path,filter=tarfile.fully_trusted_filter)
                elif is_url(file):
                    print("输入的是一个url")
                    file = requests.get(file)
                    if file.status_code == 200:
                        with tarfile.open(fileobj=io.BytesIO(file.content), mode='r:gz') as tar:
                            tar.extractall(path=base_path,filter=tarfile.fully_trusted_filter)
                    else:
                        print(file.status_code)
                        continue
                break
        os.chmod(base_path, 0o755) #调整权限
        print("Realm升级完成！")
        subprocess.run(['sudo', 'systemctl', 'start', 'realm.service'])
        time.sleep(0.3)
        print("Realm重启完成！请按任意键继续")


def check_location():
    if is_process_running("realm"):
        status = "Realm运行状态：已运行"
    else:
        status = "Realm运行状态：未运行"
    if is_ip_in_china() == '中国':
        latest = input("当前ip位于中国，请手动指定Realm版本：")
        latest_version = latest[1:]
    else:
        latest = requests.get("https://api.github.com/repos/zhboner/realm/releases/latest")
        latest_version = latest.json()["tag_name"][1:]
    return status,latest_version


def main_tab(status,latest_version):
    local_version = "Realm未安装"
    if os.path.exists("/opt/realm/realm"):
        result = subprocess.run(['/opt/realm/realm', '-v'], capture_output=True, text=True)
        if result.returncode == 0:
            local_version = result.stdout
    else:
        local_version = "Realm未安装"
    print('\033[1;31m')
    print('*' * 50)
    print("\nRealm一键安装脚本\n")
    print("最新Realm版本:",latest_version,"当前Realm版本:",local_version[5:12])
    print("\n当前Realm状态:",status)
    print("\n0.更新Realm服务\n" )
    print("1.安装Realm服务\n" )
    print("2.卸载Realm服务\n" )
    print("3.增加Realm配置\n" )
    print("4.删除Realm配置\n" )
    print("5.启动Realm服务\n" )
    print("6.停止Realm服务\n" )
    print("7.查看Realm日志\n" )
    print("8.查看Realm状态\n" )
    print("9.重启Realm服务\n" )
    print("10.查看Realm配置\n" )
    print("11.退出\n" )
    print('*' * 50)
    print('\033[0m')
    
    usr_input = input("请输入：")
    return usr_input


location = check_location()
subprocess.run('clear')
check_pythonversion()

status = location[0]
latest_version = location[1]
usr_input = main_tab(status,latest_version)

while usr_input != '':
    if usr_input == '0':
        update_realm()
        time.sleep(0.5)
        usr_input = main_tab(status,latest_version)
        continue    
    if usr_input == '1':
        install()
        time.sleep(0.5)
        usr_input = main_tab(status,latest_version)
        continue    
        #pass
    elif usr_input == '2':
        uninstall()
        time.sleep(0.5)
        input("按任意键继续...")
        usr_input = main_tab(status,latest_version)
        continue    
    elif usr_input == '3':
        add_config()
        time.sleep(0.5)
        input("按任意键继续...")
        usr_input = main_tab(status,latest_version)
        continue    
    elif usr_input == '4':
        del_config()
        time.sleep(0.5)
        input("按任意键继续...")
        usr_input = main_tab(status,latest_version)
        continue   
    elif usr_input == '5':
        start()
        time.sleep(0.5)
        usr_input = main_tab(status,latest_version)
        continue
    elif usr_input == '6':
        stop()
        time.sleep(0.5)
        usr_input = main_tab(status,latest_version)
        continue 
    elif usr_input == '7':
        show_log()
        time.sleep(0.5)
        input("按任意键继续...")
        usr_input = main_tab(status,latest_version)
        continue  
    elif usr_input == '8':
        check_status()
        input("按任意键继续...")
        time.sleep(0.5)
        usr_input = main_tab(status,latest_version)
        continue  
    elif  usr_input == '9':
        restart()
        time.sleep(0.5)
        usr_input = main_tab(status,latest_version)
        continue
    elif  usr_input == '10':
        show_config()
        time.sleep(0.2)
        input("按任意键继续...")
        usr_input = main_tab(status,latest_version)
        break
    elif  usr_input == '11':
        time.sleep(0.2)
        print("byebye")
        break
    else:
        print("输入错误,请重新输入！")
        time.sleep(0.5)
        usr_input = main_tab(status,latest_version)
        continue
else:
    print("byebye")
