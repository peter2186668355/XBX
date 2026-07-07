#!/bin/bash
#
# V2bX 一键安装脚本（含 simple-obfs 支持）
# 用法: wget -N https://raw.githubusercontent.com/peter2186668355/XBX/dev_new/install.sh && bash install.sh
#
# 无需额外安装 obfs-server — obfs 已编译进 V2bX 二进制。

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

GITHUB_USER="${GITHUB_USER:-peter2186668355}"
REPO="${REPO:-XBX}"
V2BX_VERSION="${V2BX_VERSION:-v1.01}"
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="/etc/V2bX"
SERVICE_FILE="/etc/systemd/system/V2bX.service"

# ---------- 架构检测 ----------
detect_arch() {
    local arch
    case "$(uname -m)" in
        x86_64)  arch="linux-64" ;;
        aarch64) arch="linux-arm64-v8a" ;;
        armv7l)  arch="linux-arm32-v7a" ;;
        *)       echo -e "${RED}不支持的架构: $(uname -m)${NC}"; exit 1 ;;
    esac
    echo "$arch"
}

# ---------- 下载二进制 ----------
download_v2bx() {
    local arch="$1"
    local url="https://github.com/${GITHUB_USER}/${REPO}/releases/${V2BX_VERSION}/download/V2bX-${arch}.zip"
    echo -e "${GREEN}>>> 下载 V2bX (${arch})...${NC}"
    wget -q --show-progress "$url" -O /tmp/V2bX.zip
    unzip -o /tmp/V2bX.zip -d /tmp/v2bx-install/
    cp /tmp/v2bx-install/V2bX "${INSTALL_DIR}/V2bX"
    chmod +x "${INSTALL_DIR}/V2bX"
    rm -rf /tmp/V2bX.zip /tmp/v2bx-install
}

# ---------- 复制 geo 数据 ----------
download_geo() {
    echo -e "${GREEN}>>> 复制 geoip/geosite 数据...${NC}"
    cp /tmp/v2bx-install/geoip.dat "${CONFIG_DIR}/geoip.dat" 2>/dev/null || true
    cp /tmp/v2bx-install/geosite.dat "${CONFIG_DIR}/geosite.dat" 2>/dev/null || true
}

# ---------- 生成配置 ----------
generate_config() {
    echo -e "${YELLOW}>>> 配置面板连接信息${NC}"

    read -p "面板地址 (如 https://panel.example.com): " API_HOST
    read -p "节点 ID: " NODE_ID
    read -p "API Key: " API_KEY
    read -p "节点类型 (shadowsocks/vmess/vless/trojan/hysteria2): " NODE_TYPE
    read -p "证书模式 (none/file/http/dns): " CERT_MODE

    mkdir -p "$CONFIG_DIR"

    cat > "${CONFIG_DIR}/config.json" <<EOF
{
    "Log": {
        "Level": "info",
        "Output": ""
    },
    "Cores": [
        {
            "Type": "sing",
            "Name": "sing-box",
            "SingConfig": {
                "Log": {"Level": "warn"},
                "NTP": {"Enabled": true},
                "OriginalPath": ""
            }
        }
    ],
    "Nodes": [
        {
            "ApiHost": "${API_HOST}",
            "NodeID": ${NODE_ID},
            "ApiKey": "${API_KEY}",
            "NodeType": "${NODE_TYPE}",
            "Timeout": 30,
            "ListenIP": "0.0.0.0",
            "SendIP": "0.0.0.0",
            "DeviceOnlineMinTraffic": 100,
            "ReportMinTraffic": 100,
            "RuleListPath": "",
            "SingOptions": {
                "EnableTFO": false,
                "EnableSniff": true,
                "SniffOverrideDestination": false,
                "EnableDNS": true,
                "DomainStrategy": "",
                "MultiplexConfig": {"Enabled": false}
            },
            "CertConfig": {
                "CertMode": "${CERT_MODE}",
                "CertDomain": "",
                "CertFile": "/etc/V2bX/cert.pem",
                "KeyFile": "/etc/V2bX/key.pem",
                "Provider": "",
                "Email": "",
                "DNSEnv": {}
            }
        }
    ]
}
EOF

    echo -e "${GREEN}配置文件已生成: ${CONFIG_DIR}/config.json${NC}"
    echo -e "${YELLOW}提示: obfs 由面板 API 自动下发，无需在 config.json 中配置。${NC}"
}

# ---------- 注册服务 ----------
install_service() {
    cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=V2bX Node Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/V2bX server --config /etc/V2bX/config.json
Restart=on-failure
RestartSec=5s
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable V2bX
    echo -e "${GREEN}systemd 服务已注册${NC}"
}

# ---------- 启动 ----------
start_v2bx() {
    systemctl start V2bX
    sleep 2
    if systemctl is-active --quiet V2bX; then
        echo -e "${GREEN}V2bX 启动成功${NC}"
        echo -e "${GREEN}查看日志: journalctl -u V2bX -f${NC}"
    else
        echo -e "${RED}V2bX 启动失败，查看日志: journalctl -u V2bX -n 50${NC}"
        exit 1
    fi
}

# ---------- main ----------
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  V2bX 安装脚本 (simple-obfs 集成版)${NC}"
echo -e "${GREEN}========================================${NC}"

ARCH=$(detect_arch)

if [ -f "${INSTALL_DIR}/V2bX" ]; then
    read -p "V2bX 已安装，是否覆盖? (y/N): " OVERWRITE
    [ "$OVERWRITE" != "y" ] && [ "$OVERWRITE" != "Y" ] && exit 0
fi

download_v2bx "$ARCH"
download_geo

if [ ! -f "${CONFIG_DIR}/config.json" ]; then
    generate_config
else
    echo -e "${YELLOW}配置文件已存在，跳过生成。${NC}"
fi

install_service
start_v2bx

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  安装完成！${NC}"
echo -e "${GREEN}  状态: systemctl status V2bX${NC}"
echo -e "${GREEN}  日志: journalctl -u V2bX -f${NC}"
echo -e "${GREEN}  配置: ${CONFIG_DIR}/config.json${NC}"
echo -e "${GREEN}========================================${NC}"
