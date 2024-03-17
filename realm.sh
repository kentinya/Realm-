#!/bin/bash
cd ~
if [ -f "/usr/local/bin/python3.12" ];then
    if [ ! -f "/usr/bin/python" ];then
        ln -sf /usr/local/bin/python3.12 /usr/bin/python
    fi
    if [ ! -f "/usr/bin/pip" ];then
        ln -sf /usr/local/bin/pip3.12 /usr/bin/pip
    fi
    echo "Python已安装"
    if [ ! -d ".venv" ];then
        mkdir .venv
        python -m venv .venv

        cd .venv

        source ./bin/activate
        pip install requests > /dev/nell
        pip install psutil > /dev/nell
        wget -N https://raw.githubusercontent.com/kentinya/Realm-mangescript/main/realm.py
        python realm.py
        else
        echo "文件夹已经存在"
        cd .venv
        source ./bin/activate
        pip install requests > /dev/nell
        pip install psutil > /dev/nell
        if [ ! -f "realm.py" ]
            wget -N https://raw.githubusercontent.com/kentinya/Realm-mangescript/main/realm.py
            python realm.py
            else
            python realm.py
        fi
    fi

    

    else
    echo "文件不存在"
    if [ "$1" == "" ];then
        # 安装编译Python所需的依赖
        apt-get update -y
        apt-get install -y wget build-essential libncursesw5-dev libssl-dev libsqlite3-dev tk-dev libgdbm-dev libc6-dev libbz2-dev libffi-dev zlib1g-dev 
        mkdir ~/python-compile
        cd ~/python-compile
    
        # 获取最新版本的Python源码下载链接
        PYTHON_URL="https://www.python.org/ftp/python/3.12.2/Python-3.12.2.tgz"
    
        # 下载最新版本的Python源码
        wget -N $PYTHON_URL
    
        # 解压源码
        tar -xvf Python-3.12.2.tgz
    
        # 进入解压后的目录
        cd Python-3.12.2
    
        # 配置Python源码
        ./configure --enable-optimizations
    
        # 编译并安装
        make -j $(nproc)  # 使用所有可用的核心进行编译
        make altinstall  # 使用altinstall避免替换默认python命令
    
        # 返回到家目录并清理临时文件
        cd ~
        rm -rf ~/python-compile
    
        # 创建软链接
        # 请根据需要调整以下命令。这里以Python 3.x为例，创建python3和python链接到新安装的版本
        # 检测安装的Python版本并创建软链接
        PYTHON_VERSION=$(echo $PYTHON_LATEST | grep -oP '\d+\.\d+')
    
        rm /usr/local/bin/python
    
        ln -sf /usr/local/bin/python3.12 /usr/bin/python
        ln -sf /usr/local/bin/pip3.12 /usr/bin/pip
        echo "Python 3.12 安装完成。已创建软链接。"
        else
        tar -xvf $1 -C /usr/local/
        rm $1
        ln -sf /usr/local/bin/python3.12 /usr/bin/python
        ln -sf /usr/local/bin/pip3.12 /usr/bin/pip
    fi
    mkdir .venv

    python -m venv .venv

    cd .venv

    source ./bin/activate
    pip install requests  > /dev/nell
    pip install psutil  > /dev/nell
    wget -N https://raw.githubusercontent.com/kentinya/Realm-mangescript/main/realm.py
    python realm.py

fi


# 创建临时目录用于下载和编译Python


