#!/bin/bash

# 主菜单函数
function main_menu() {
    while true; do
        clear
        echo "脚本由推特 @ferdie_jhovie，免费开源，请勿相信收费"
        echo "================================================================"
        echo "节点社区 Telegram 群组: https://t.me/niuwuriji"
        echo "节点社区 Telegram 频道: https://t.me/niuwuriji"
        echo "节点社区 Discord 社群: https://discord.gg/GbMV5EcNWF"
        echo "退出脚本，请按键盘 ctrl+c 退出即可"
        echo "请选择要执行的操作:"
        echo "1) 安装节点"
        echo "2) 退出"
        read -p "请输入选项 [1-2]: " choice

        case $choice in
            1)
                install_node
                ;;
            2)
                echo "退出脚本。"
                exit 0
                ;;
            *)
                echo "无效的选项，请重新选择。"
                ;;
        esac
    done
}

# 安装节点函数
function install_node() {
    # 更新系统并安装 curl
    echo "更新系统并安装 curl..."
    sudo apt-get update
    sudo apt-get install -y curl

    # 添加 Docker 的 GPG 密钥
    echo "添加 Docker 的 GPG 密钥..."
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # 将 Docker 仓库添加到 APT 源中
    echo "添加 Docker 仓库..."
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

    # 启动 Docker 服务
    echo "启动 Docker 服务..."
    sudo systemctl start docker
    sudo systemctl enable docker

    # 检测 NVIDIA GPU 驱动是否安装
    if ! command -v nvidia-smi &> /dev/null
    then
        echo "NVIDIA 驱动未安装，正在安装最新版本的 NVIDIA 驱动。"

        # 添加 NVIDIA 官方 PPA
        sudo add-apt-repository ppa:graphics-drivers/ppa
        sudo apt-get update

        # 安装最新版的 NVIDIA 驱动
        sudo apt-get install -y nvidia-driver-$(ubuntu-drivers devices | grep recommended | awk '{print $3}')
    else
        echo "NVIDIA 驱动已安装。"
    fi

    # 安装 gum（如果不存在）
    if ! command -v gum &> /dev/null
    then
        echo "gum 未安装，正在安装 gum。"
        # 下载安装 gum
        curl -fsSL https://github.com/charmbracelet/gum/releases/download/v0.18.0/gum_0.18.0_linux_amd64.tar.gz | sudo tar xz -C /usr/local/bin
    else
        echo "gum 已安装。"
    fi

    # 安装 jq（如果不存在）
    if ! command -v jq &> /dev/null
    then
        echo "jq 未安装，正在安装 jq。"
        sudo apt-get install -y jq
    else
        echo "jq 已安装。"
    fi

    # 配置节点
    echo "配置节点..."
    echo "请为您的节点选择一个唯一的名称："
    read -p "Choose a moniker for your node: " NODE_NAME

    echo "您的节点类型是 Validator 还是 Miner？"
    echo "[ ] Validator"
    echo "[ ] Miner"
    read -p "What type(s) of node is $NODE_NAME? (Validator/Miner): " NODE_TYPE

    if [[ "$NODE_TYPE" == "Validator" ]]; then
        read -p "Validator's Private Key: " PRIVATE_KEY
    elif [[ "$NODE_TYPE" == "Miner" ]]; then
        echo "矿工类型：在 Distributed Miner 或 Non-Distributed Miner 之间进行选择。"
        echo "[ ] Distributed Miner"
        echo "[ ] Non-Distributed Miner"
        read -p "What type of miner will $NODE_NAME be? (Distributed Miner/Non-Distributed Miner): " MINER_TYPE
        
        if [[ "$MINER_TYPE" == "Distributed Miner" ]]; then
            echo "请选择现有 swarm 或启动新 swarm。"
            echo "[ ] Join existing swarm"
            echo "[ ] Start a new swarm"
            read -p "Would you like to join an existing swarm or start a new one? (Join existing swarm/Start a new swarm): " SWARM_ACTION
            
            if [[ "$SWARM_ACTION" == "Start a new swarm" ]]; then
                read -p "Which model would you like to run? (meta-llama/Llama-2-13b-Chat-Hf): " MODEL
            fi
        elif [[ "$MINER_TYPE" == "Non-Distributed Miner" ]]; then
            read -p "Which model would you like to run? (meta-llama/Llama-2-13b-Chat-Hf): " MODEL
        fi
    fi

    # 为所有操作系统运行远程脚本
    echo "运行远程初始化脚本..."
    bash <(curl -s https://raw.githubusercontent.com/nesaorg/bootstrap/master/bootstrap.sh)

    # 尝试启动 docker-compose
    echo "尝试启动 Docker Compose 容器..."
    if sudo docker-compose up -d; then
        echo "Docker Compose 容器启动成功。"
    else
        echo "Docker Compose 容器启动失败，请检查配置和日志。"
    fi
}

# 运行主菜单
main_menu
