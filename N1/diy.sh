#!/usr/bin/env bash
set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly WORKSPACE="${GITHUB_WORKSPACE:-$(cd -- "${SCRIPT_DIR}/.." && pwd)}"

trap 'printf "diy.sh failed at line %s: %s\n" "${BASH_LINENO[0]}" "${BASH_COMMAND}" >&2' ERR

# 删除上游可能残留的同名插件目录，避免重复定义。
rm -rf -- package/luci-app-amlogic

# 引入第三方插件。24.10 保留上游 Go feed，避免与 Docker/containerd 的旧构建链冲突。
if [ "${REPO_BRANCH:-openwrt-25.12}" = "openwrt-25.12" ]; then
	rm -rf -- feeds/packages/lang/golang
	git clone --depth=1 --branch 27.x https://github.com/OpenListTeam/packages_lang_golang.git feeds/packages/lang/golang
	OPENLIST_REF="v4.2.9"
else
	OPENLIST_REF="v4.1.9"
fi

git clone --depth=1 https://github.com/ophub/luci-app-amlogic.git package/luci-app-amlogic
git clone --depth=1 https://github.com/EasyTier/luci-app-easytier.git package/luci-app-easytier
git clone --depth=1 https://github.com/hello-yunshu/luci-app-nginx-manager.git package/luci-app-nginx-manager
git clone --depth=1 --branch "${OPENLIST_REF}" https://github.com/OpenListTeam/OpenList-OpenWRT.git package/openlist

# 写入插件选择。
cat >> .config <<'EOF'

CONFIG_PACKAGE_luci-app-amlogic=y
CONFIG_PACKAGE_luci-app-ddns-go=y
CONFIG_PACKAGE_luci-app-homeproxy=y
CONFIG_PACKAGE_luci-app-easytier=y
CONFIG_PACKAGE_luci-app-nginx-manager=y
CONFIG_PACKAGE_luci-app-openlist=y
EOF

# 修改默认管理地址。
sed -i 's/192.168.1.1/192.168.128.3/g' package/base-files/files/bin/config_generate

# 修改默认主题。
sed -i 's/luci-theme-design/luci-theme-argon/g' feeds/luci/collections/luci/Makefile
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# 修改默认主机名。
sed -i 's/ImmortalWrt/OpenWrt/g' package/base-files/files/bin/config_generate

# 安装 Argon 主题资源。
readonly ARGON_DIR="${WORKSPACE}/argon"
readonly ARGON_TARGET="feeds/luci/themes/luci-theme-argon"
mkdir -p -- "${ARGON_TARGET}/htdocs/luci-static/argon/img" \
  "${ARGON_TARGET}/htdocs/luci-static/argon/icon"
cp -f -- "${ARGON_DIR}/background/background.jpg" "${ARGON_TARGET}/htdocs/luci-static/argon/img/bg1.jpg"
cp -f -- "${ARGON_DIR}/img/argon.svg" "${ARGON_TARGET}/htdocs/luci-static/argon/img/argon.svg"
cp -f -- "${ARGON_DIR}/favicon.ico" "${ARGON_TARGET}/htdocs/luci-static/argon/favicon.ico"
for icon in "${ARGON_DIR}"/icon/*.png; do
  cp -f -- "${icon}" "${ARGON_TARGET}/htdocs/luci-static/argon/icon/$(basename -- "${icon}")"
done
