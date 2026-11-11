# 项目简介
本固件适配斐讯 N1 旁路由模式，追求轻量（请注意：不具备 PPPoE、WiFi 相关功能）。<br>
固件包含默认皮肤、完整 IPv6 支持，以及下列 luci-app：<br>
- 添加 amlogic
- 添加 dockerman
- 添加 Mosdns
- 添加 Pushbot
- 添加 OpenClash
- 添加 阿里DDNS
- 添加 网络唤醒
***
# 使用说明
- 默认管理地址：`192.168.128.3`，请确保它没有与现有网络设备冲突。
- 固件首次启动后请立即设置管理员密码；不要在公开发布说明或脚本中保存明文密码。
- 本项目通过 GitHub Actions 编译。手动编译可在 Actions 页面运行 `Build ImmortalWrt for N1`，源码分支为 `openwrt-24.10`。
- 构建产物包括 N1 固件和可选的 ARM64 Docker 镜像；Docker 镜像制作脚本需要先存在 `openwrt/bin/targets/*/*/*rootfs.tar.gz`。

## 配置入口
- `N1/.config`：固件目标和内置软件包。
- `N1/diy.sh`：下载额外软件包、修改默认网络/主题并执行定制。
- `N1/files`：写入固件的默认配置文件。
- `.github/workflows/openwrt-builder.yml`：编译、发布和 Docker 镜像流程。

提交配置变更前，建议先在 Actions 中使用手动触发验证；若修改上游分支，也要同步更新 `update-checker.yml`。

# 致谢
本项目基于天灵的 [ImmortalWrt-24.10](https://github.com/immortalwrt/immortalwrt/tree/openwrt-24.10) 源码编译，使用 flippy 的[脚本](https://github.com/unifreq/openwrt_packit)， breakings 维护的[内核](https://github.com/breakings/OpenWrt/releases/tag/kernel_stable)和nantayo的[编译项目](https://github.com/nantayo/N1-OpenWrt)打包成完整固件，感谢开发者们的无私分享。<br>
flippy 固件的更多细节参考[恩山论坛帖子](https://www.right.com.cn/forum/thread-4076037-1-1.html)。
