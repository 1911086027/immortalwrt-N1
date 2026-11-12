# 项目简介
本固件适配斐讯 N1 旁路由模式，追求轻量（不包含 PPPoE；已加入 N1 无线驱动，但无线默认关闭）。<br>
固件包含默认皮肤、IPv6 内核支持，以及下列 luci-app：<br>
- amlogic、dockerman、homeproxy、easytier、nginx-manager、openlist
- ddns-go、网络唤醒
- diskman、ttyd、opkg
***
# 使用说明
- 默认管理地址：`192.168.128.3`，请确保它没有与现有网络设备冲突。
- 固件首次启动后请立即设置管理员密码；不要在公开发布说明或脚本中保存明文密码。
- 本项目通过 GitHub Actions 编译。手动运行 `Build ImmortalWrt for N1` 会同时构建 `openwrt-24.10` 和 `openwrt-25.12` 两个版本。
- 构建产物包括 N1 固件和可选的 ARM64 Docker 镜像；Docker 镜像制作脚本需要先存在 `openwrt/bin/targets/*/*/*rootfs.tar.gz`。
- 默认已预置上海时区和 NTP、`192.168.128.3/24` 静态管理地址、上游网关 `192.168.128.2`、公共 DNS，以及关闭 DHCP 服务，适合旁路由模式。若主路由网段不同，请修改 `N1/files/etc/config/network`。
- LuCI 管理端口预设为 `8080`（HTTPS 为 `8443`），Nginx 预留 `80/443` 用于反向代理；访问管理页面请使用 `http://192.168.128.3:8080/cgi-bin/luci`。
- Docker Hub 发布需要在仓库 Secrets 中配置 `DOCKERHUB_USERNAME` 和 `DOCKERHUB_PASSWORD`（建议使用 Docker Hub Access Token）。成功后会发布 `openwrt-24.10`、`openwrt-25.12` 和对应提交 SHA；`latest` 仅指向 `openwrt-25.12`。

## 配置入口
- `N1/.config`：固件目标和内置软件包。
- `N1/diy.sh`：下载额外软件包、修改默认网络/主题并执行定制。
- `N1/files`：写入固件的默认配置文件，包括网络、DHCP、时区和 NTP。
- `.github/workflows/openwrt-builder.yml`：编译、发布和 Docker 镜像流程。

## Docker 与公网访问

`docker/Dockerfile` 使用编译出的 ARM64 rootfs 创建容器，当前不声明 `EXPOSE`，避免让人误以为端口会自动开放。运行容器时仍需显式映射端口，例如 `-p 80:80 -p 443:443`；公网访问还需要在上级路由器转发 TCP 80/443 到 N1，并准备域名、证书和防火墙规则。

固件内置 `luci-app-nginx-manager`，可在 LuCI 的“服务 → Nginx Manager”中创建反向代理站点，支持 WebSocket 和 ACME 证书。建议只转发到具体服务，不要把 `8080/8443` 管理端口转发到公网；没有公网 IPv4 时可使用 IPv6、端口映射服务或安全隧道。

固件内置 OpenList，默认监听 `5244` 且关闭 WAN 访问。首次使用请在 LuCI 的“服务 → OpenList”中启用；如需公网访问，推荐通过 Nginx 反代并使用 HTTPS，不要直接开放 OpenList 管理端口。

HomeProxy 已预置 VMess 服务端模板，端口为 `809`，但默认关闭。启用前请在 LuCI 中生成 UUID，配置域名和证书，再将证书放入 `/etc/homeproxy/certs/server.crt`、`/etc/homeproxy/certs/server.key`，并按需开启 WAN 防火墙规则。DDNS-Go 生成证书后，可将证书复制或链接到上述路径，具体路径以 DDNS-Go 页面显示为准。

EasyTier 默认关闭。启用并完成组网后，插件会创建 `EasyTier` 网络接口和防火墙区域；外部 VMess 客户端需要把 EasyTier 子网加入代理客户端路由，N1 才能将该流量从 HomeProxy 服务端转发到 EasyTier 接口。固件不会擅自猜测你的 EasyTier 网段、节点密钥或出口节点。

提交配置变更前，建议先在 Actions 中使用手动触发验证；`update-checker.yml` 当前跟踪 `openwrt-25.12`，发现上游更新后会触发双版本构建。

# 致谢
本项目基于天灵的 [ImmortalWrt-25.12](https://github.com/immortalwrt/immortalwrt/tree/openwrt-25.12) 源码编译，使用 flippy 的[脚本](https://github.com/unifreq/openwrt_packit)， breakings 维护的[内核](https://github.com/breakings/OpenWrt/releases/tag/kernel_stable)和nantayo的[编译项目](https://github.com/nantayo/N1-OpenWrt)打包成完整固件，感谢开发者们的无私分享。<br>
flippy 固件的更多细节参考[恩山论坛帖子](https://www.right.com.cn/forum/thread-4076037-1-1.html)。
