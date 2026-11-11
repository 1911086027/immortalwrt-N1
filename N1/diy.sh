#!/usr/bin/env bash
set -Eeuo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly WORKSPACE="${GITHUB_WORKSPACE:-$(cd -- "${SCRIPT_DIR}/.." && pwd)}"

trap 'printf "diy.sh failed at line %s: %s\n" "${BASH_LINENO[0]}" "${BASH_COMMAND}" >&2' ERR

# Remove packages
rm -rf -- package/luci-app-amlogic

#rm -rf feeds/packages/net/v2ray-geodata

# Git稀疏克隆，只克隆指定目录到本地
function git_sparse_clone() {
  local branch="$1" repourl="$2"
  shift 2
  local repodir
  repodir="$(basename -- "${repourl}")"
  git clone --depth=1 -b "${branch}" --single-branch --filter=blob:none --sparse "${repourl}" "${repodir}"
  (
    cd -- "${repodir}"
    git sparse-checkout set "$@"
    mv -f -- "$@" ../package
  )
  rm -rf -- "${repodir}"
}

# Add packages
git clone --depth=1 https://github.com/ophub/luci-app-amlogic.git package/luci-app-amlogic
#git clone https://github.com/sbwml/luci-app-mosdns -b v5 package/mosdns
#git clone https://github.com/sbwml/v2ray-geodata package/v2ray-geodata
#git clone https://github.com/rufengsuixing/luci-app-adguardhome.git package/luci-app-adguardhome
git clone --depth=1 https://github.com/EasyTier/luci-app-easytier.git package/luci-app-easytier
git clone --depth=1 --branch v1.8.8-1 https://github.com/hello-yunshu/luci-app-nginx-manager.git package/luci-app-nginx-manager
#git clone https://github.com/Zxilly/UA2F.git package/UA2F

cat >> .config <<'EOF'

# 插件
CONFIG_PACKAGE_luci-app-amlogic=y
CONFIG_PACKAGE_luci-app-dockerman=y
#CONFIG_PACKAGE_luci-app-mosdns=y
CONFIG_PACKAGE_luci-app-ddns-go=y
#CONFIG_PACKAGE_luci-app-socat=y
#CONFIG_PACKAGE_luci-app-openclash=y
CONFIG_PACKAGE_luci-app-homeproxy=y
#CONFIG_PACKAGE_luci-app-adguardhome=y
#CONFIG_PACKAGE_luci-app-qbittorrent=y
#CONFIG_PACKAGE_luci-app-rclone=y
#CONFIG_PACKAGE_luci-app-alist=y
#CONFIG_PACKAGE_luci-app-acme=y
CONFIG_PACKAGE_luci-app-easytier=y
CONFIG_PACKAGE_luci-app-nginx-manager=y
#CONFIG_PACKAGE_ua2f=y
#CONFIG_PACKAGE_luci-app-ua2f=y
EOF

# 修改默认IP
sed -i 's/192.168.1.1/192.168.128.3/g' package/base-files/files/bin/config_generate

# 修改默认主题
sed -i 's/luci-theme-design/luci-theme-argon/g' feeds/luci/collections/luci/Makefile
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# 修改主机名
sed -i 's/ImmortalWrt/OpenWrt/g' package/base-files/files/bin/config_generate

# 修改主题背景
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
