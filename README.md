# ImmortalWrt N1

面向斐讯 N1 的 ARM64 旁路由固件项目。默认地址为 `192.168.128.3`，主路由网关和 DNS 为 `192.168.128.2`，DHCP 默认关闭。

## 主要内容

- ImmortalWrt `openwrt-24.10`、`openwrt-25.12` 双版本构建
- N1 Amlogic 支持、zram、irqbalance、USB 存储和常用管理工具
- 两个版本都保留 `luci-app-dockerman`，24.10 使用上游默认 Go 工具链以兼容 Docker/containerd
- Nginx HTTPS 反向代理与 LuCI 管理器
- OpenList、HomeProxy、EasyTier、DDNS-Go 等可选服务
- ARM64 Docker 镜像构建和 Docker Hub 发布

HomeProxy、EasyTier、OpenList WAN 访问和 Wi-Fi 默认不会自动启用或写入业务参数。它们必须按实际域名、证书、节点和网段配置。

## 默认端口

| 服务 | 端口 | 说明 |
| --- | --- | --- |
| LuCI | `8080` / `8443` | 管理页面 |
| Nginx | `80` / `443` | 反向代理入口 |
| OpenList | `5244` | 默认不允许 WAN 访问 |

## 构建

在 **Actions → Build ImmortalWrt for N1 → Run workflow** 手动运行，会同时构建两个源码分支。固件发布到 GitHub Releases，Docker 镜像发布到：

```text
1911086027/openwrt_cortex-a53:personal-24.10
1911086027/openwrt_cortex-a53:personal-25.12
```

Docker Hub 需要配置 `DOCKERHUB_USERNAME` 和 `DOCKERHUB_PASSWORD` Secrets。

GitHub Release 标签会使用 `OpenWrt_24.10_时间` 或 `OpenWrt_25.12_时间`，可直接区分固件源码版本。

## Docker 镜像边界

镜像由 ARM64 OpenWrt rootfs 制作，入口为 `/sbin/init`。打包时会移除 Amlogic 硬件服务、内核模块、dockerd 和 Dockerman，因此它适合运行 OpenWrt 用户态服务，不适合：

- 作为真实 N1 固件使用
- 在容器内继续运行 Docker
- 直接提供硬件 Wi-Fi、USB、CPU 调频和 N1 专用功能

建议在 ARM64 主机使用特权和主机网络运行，以便 procd、网络和防火墙正常工作：

```bash
docker run -d --name immortalwrt-n1 \
  --privileged --network host \
  1911086027/openwrt_cortex-a53:personal-25.12
```

公网端口仍由 Docker `-p`、主机防火墙、上级路由端口转发共同决定，Dockerfile 不会自动开放公网端口。

更完整的模块说明、服务配置和 Docker 检查结果见 [`docs/配置说明.md`](docs/配置说明.md)。
