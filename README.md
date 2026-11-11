# 项目简介
本固件适配斐讯 N1 旁路由模式，追求轻量（请注意：不具备 PPPoE、WiFi 相关功能）。<br>
固件包含默认皮肤、完整 IPv6 支持，以及下列 luci-app：<br>
- amlogic、dockerman、homeproxy、easytier、nginx-manager
- ddns-go、动态 DNS、网络唤醒
- diskman、ttyd、opkg
***
# 使用说明
- 默认管理地址：`192.168.128.3`，请确保它没有与现有网络设备冲突。
- 固件首次启动后请立即设置管理员密码；不要在公开发布说明或脚本中保存明文密码。
- 本项目通过 GitHub Actions 编译。手动编译可在 Actions 页面运行 `Build ImmortalWrt for N1`，源码分支为 `openwrt-25.12`（上游当前稳定分支）。
- 构建产物包括 N1 固件和可选的 ARM64 Docker 镜像；Docker 镜像制作脚本需要先存在 `openwrt/bin/targets/*/*/*rootfs.tar.gz`。
- 默认已预置上海时区和 NTP、`192.168.128.3/24` 静态管理地址、上游网关 `192.168.128.1`、公共 DNS，以及关闭 DHCP 服务，适合旁路由模式。若主路由网段不同，请修改 `N1/files/etc/config/network`。
- LuCI 管理端口预设为 `8080`（HTTPS 为 `8443`），Nginx 预留 `80/443` 用于反向代理；访问管理页面请使用 `http://192.168.128.3:8080/cgi-bin/luci`。
- Docker Hub 发布需要在仓库 Secrets 中配置 `DOCKERHUB_USERNAME` 和 `DOCKERHUB_PASSWORD`（建议使用 Docker Hub Access Token）。成功后会发布 `latest`、`openwrt-25.12` 和提交 SHA 三个标签。

## 配置入口
- `N1/.config`：固件目标和内置软件包。
- `N1/diy.sh`：下载额外软件包、修改默认网络/主题并执行定制。
- `N1/files`：写入固件的默认配置文件，包括网络、DHCP、时区和 NTP。
- `.github/workflows/openwrt-builder.yml`：编译、发布和 Docker 镜像流程。

## Docker 与公网访问

`docker/Dockerfile` 使用编译出的 ARM64 rootfs 创建容器，`EXPOSE 22 80 443` 只是镜像元数据，不会自动提供公网入口。运行容器时仍需映射端口，例如 `-p 80:80 -p 443:443`；公网访问还需要在上级路由器转发 TCP 80/443 到 N1，并准备域名、证书和防火墙规则。

固件内置 `luci-app-nginx-manager`，可在 LuCI 的“服务 → Nginx Manager”中创建反向代理站点，支持 WebSocket 和 ACME 证书。建议只转发到具体服务，不要把 `8080/8443` 管理端口转发到公网；没有公网 IPv4 时可使用 IPv6、端口映射服务或安全隧道。

提交配置变更前，建议先在 Actions 中使用手动触发验证；若修改上游分支，也要同步更新 `update-checker.yml`。

# 致谢
本项目基于天灵的 [ImmortalWrt-25.12](https://github.com/immortalwrt/immortalwrt/tree/openwrt-25.12) 源码编译，使用 flippy 的[脚本](https://github.com/unifreq/openwrt_packit)， breakings 维护的[内核](https://github.com/breakings/OpenWrt/releases/tag/kernel_stable)和nantayo的[编译项目](https://github.com/nantayo/N1-OpenWrt)打包成完整固件，感谢开发者们的无私分享。<br>
flippy 固件的更多细节参考[恩山论坛帖子](https://www.right.com.cn/forum/thread-4076037-1-1.html)。
