# V2bX

[![](https://img.shields.io/badge/TgChat-UnOfficialV2Board%E4%BA%A4%E6%B5%81%E7%BE%A4-green)](https://t.me/unofficialV2board)
[![](https://img.shields.io/badge/TgChat-YuzukiProjects%E4%BA%A4%E6%B5%81%E7%BE%A4-blue)](https://t.me/YuzukiProjects)

A V2board node server based on multi core, modified from XrayR.  
一个基于多种内核的V2board节点服务端，修改自XrayR，支持V2ay,Trojan,Shadowsocks协议。

**注意： 本项目需要搭配[修改版V2board](https://github.com/wyx2685/v2board)**

## 特点

* 永久开源且免费。
* 支持Vmess/Vless, Trojan， Shadowsocks, Hysteria1/2多种协议。
* 支持Vless和XTLS等新特性。
* **支持 Shadowsocks 2022 HTTP/TLS obfs 混淆（simple-obfs）**，纯 Go 实现，零外部依赖。
* 支持单实例对接多节点，无需重复启动。
* 支持限制在线IP。
* 支持限制Tcp连接数。
* 支持节点端口级别、用户级别限速。
* 配置简单明了。
* 修改配置自动重启实例。
* 支持多种内核，易扩展。
* 支持条件编译，可仅编译需要的内核。

## 功能介绍

| 功能        | v2ray | trojan | shadowsocks | hysteria1/2 |
|-----------|-------|--------|-------------|----------|
| 自动申请tls证书 | √     | √      | √           | √        |
| 自动续签tls证书 | √     | √      | √           | √        |
| 在线人数统计    | √     | √      | √           | √        |
| 审计规则      | √     | √      | √           | √         |
| 自定义DNS    | √     | √      | √           | √        |
| 在线IP数限制   | √     | √      | √           | √        |
| 连接数限制     | √     | √      | √           | √         |
| 跨节点IP数限制  |√      |√       |√            |√          |
| 按照用户限速    | √     | √      | √           | √         |
| 动态限速(未测试) | √     | √      | √           | √         |

## TODO

- [x] SS2022 simple-obfs 集成 (HTTP/TLS)
- [ ] 重新实现动态限速
- [ ] 完善使用文档

## 软件安装

### 一键安装（Docker）

```bash
# 拉取镜像并启动
docker run -d --name v2bx --restart=always --network=host \
  -v /opt/V2bX/config.json:/etc/V2bX/config.json:ro \
  -v /opt/V2bX/certs:/etc/V2bX/certs:ro \
  ghcr.io/peter2186668355/v2bx:latest
```

### docker-compose

```bash
git clone https://github.com/peter2186668355/XBX.git
cd XBX
cp .omc/deploy/config.json.example config.json
# 编辑 config.json 填入面板地址、节点ID、API Key
docker compose up -d
```

### 一键安装（脚本）

```bash
wget -N https://raw.githubusercontent.com/peter2186668355/XBX/master/install.sh && bash install.sh
```

安装脚本会：下载 V2bX 二进制（含 obfs）→ 交互式生成 config.json → 注册 systemd 服务 → 启动。

### 手动安装

[手动安装教程](https://v2bx.v-50.me/v2bx/v2bx-xia-zai-he-an-zhuang/install/manual)

## 构建

```bash
# 通过 -tags 指定内核，可选 xray, sing, hysteria2
# obfs 随 sing 内核编译进二进制，无需额外依赖
GOEXPERIMENT=jsonv2 go build -v -o V2bX -tags "sing xray hysteria2 with_quic with_grpc with_utls with_wireguard with_acme with_gvisor" -trimpath -ldflags "-X 'github.com/InazumaV/V2bX/cmd.version=$version' -s -w -buildid="
```

### Docker 构建

```bash
docker build -t v2bx .
```

## SS2022-OBFS 使用

obfs 由面板 API 自动下发，面板新增字段即可：

```json
{
  "cipher": "2022-blake3-aes-256-gcm",
  "server_key": "<key>",
  "obfs": "http",
  "obfs_settings": { "host": "cloudfront.net" }
}
```

- `obfs`: `"http"` | `"tls"` | `""`（空 = 关闭）
- `obfs_settings.host`: 可选，设置后校验客户端 Host 头
- 面板 V2Board 需在 `UniProxyController.php` 下发 `obfs` 和 `obfs_settings` 字段
- 详见 `.omc/skills/v2bx-ss2022-obfs/SKILL.md`

## 配置文件及详细使用教程

[详细使用教程](https://v2bx.v-50.me/)

## 免责声明

* 此项目用于本人自用，因此本人不能保证向后兼容性。
* 由于本人能力有限，不能保证所有功能的可用性，如果出现问题请在Issues反馈。
* 本人不对任何人使用本项目造成的任何后果承担责任。
* 本人比较多变，因此本项目可能会随想法或思路的变动随性更改项目结构或大规模重构代码，若不能接受请勿使用。

## 赞助

[赞助链接](https://v-50.me/)

## Thanks

* [Project X](https://github.com/XTLS/)
* [V2Fly](https://github.com/v2fly)
* [VNet-V2ray](https://github.com/ProxyPanel/VNet-V2ray)
* [Air-Universe](https://github.com/crossfw/Air-Universe)
* [XrayR](https://github.com/XrayR/XrayR)
* [sing-box](https://github.com/SagerNet/sing-box)

## Stars 增长记录

[![Stargazers over time](https://starchart.cc/wyx2685/V2bX.svg)](https://starchart.cc/wyx2685/V2bX)
