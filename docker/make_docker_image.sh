#!/usr/bin/env bash
set -Eeuo pipefail
readonly script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly current_path="$(cd -- "${script_dir}/.." && pwd)"
readonly openwrt_path="${current_path}/openwrt/bin/targets"
docker_rootfs_file="openwrt-docker-armvirt-64-default-rootfs.tar.gz"
docker_path="${current_path}/docker"
common_files="${docker_path}/files"
tmp_path="${current_path}/tmp"
out_path="${current_path}/out"

# 输出提示。
STEPS="[\033[95m STEPS \033[0m]"
INFO="[\033[94m INFO \033[0m]"
SUCCESS="[\033[92m SUCCESS \033[0m]"
ERROR="[\033[91m ERROR \033[0m]"

trap 'error_msg "命令在第 ${BASH_LINENO[0]} 行失败：${BASH_COMMAND}"' ERR

error_msg() {
    echo -e "${ERROR} ${1}" >&2
    exit 1
}

find_openwrt() {
    command -v tar >/dev/null || error_msg "缺少 tar。"
    command -v gzip >/dev/null || error_msg "缺少 gzip。"
    cd "${current_path}"
    echo -e "${STEPS} 开始查找 OpenWrt rootfs 文件..."

    mapfile -t rootfs_files < <(find "${openwrt_path}" -mindepth 3 -maxdepth 3 -type f -name '*rootfs.tar.gz' -print | sort)
    if [[ "${#rootfs_files[@]}" -eq 1 ]]; then
        openwrt_file_name="${rootfs_files[0]}"
        echo -e "${INFO} 找到 OpenWrt 文件：[ ${openwrt_file_name##*/} ]"
    elif [[ "${#rootfs_files[@]}" -eq 0 ]]; then
        error_msg "在 [ ${openwrt_path} ] 中找不到 rootfs.tar.gz。"
    else
        error_msg "找到多个 rootfs.tar.gz，请清理构建产物后重试：${rootfs_files[*]}"
    fi

    [[ -f "${docker_path}/Dockerfile" ]] || error_msg "缺少 Dockerfile。"
}

adjust_settings() {
    cd "${current_path}"
    echo -e "${STEPS} 开始调整 OpenWrt 文件..."

    echo -e "${INFO} 解压 OpenWrt rootfs。"
    rm -rf -- "${tmp_path}" && mkdir -p -- "${tmp_path}"
    tar -xzf "${openwrt_file_name}" -C "${tmp_path}"

    echo -e "${INFO} 删除无用文件。"
    rm -rf -- "${tmp_path}/lib/firmware" "${tmp_path}/lib/modules"
    rm -f -- "${tmp_path}/root/.todo_rootfs_resize"
    find "${tmp_path}" -name '*.rej' -exec rm -f -- {} \;
    find "${tmp_path}" -name '*.orig' -exec rm -f -- {} \;
    rm -f -- "${tmp_path}/usr/lib/lua/luci/controller/amlogic.lua"
    rm -rf -- "${tmp_path}/usr/lib/lua/luci/model/cbi/amlogic" \
        "${tmp_path}/usr/share/amlogic"
    rm -f -- "${tmp_path}"/usr/sbin/openwrt-*-* "${tmp_path}/etc/init.d/amlogic"
    rm -f -- "${tmp_path}/usr/lib/lua/luci/controller/docker"*
    rm -rf -- "${tmp_path}/usr/lib/lua/luci/model/cbi/docker"*
    rm -f -- "${tmp_path}/usr/lib/lua/luci/model/docker"* \
        "${tmp_path}/usr/bin/docker"* "${tmp_path}/etc/init.d/docker"*

    [[ -f "${tmp_path}/etc/config/turboacc" ]] && {
        echo -e "${INFO} 调整 turboacc 设置。"
        sed -i "s|option hw_flow.*|option hw_flow '0'|g" "${tmp_path}/etc/config/turboacc"
        sed -i "s|option sw_flow.*|option sw_flow '0'|g" "${tmp_path}/etc/config/turboacc"
    }

    [[ -f "${tmp_path}/etc/config/cpufreq" ]] && {
        echo -e "${INFO} 调整 CPU 调频设置。"
        sed -i "s/ondemand/schedutil/g" "${tmp_path}/etc/config/cpufreq"
    }

    [[ -f "${common_files}/sbin/kmod" ]] && (
        echo -e "${INFO} 调整 kmod 链接。"
        mkdir -p -- "${tmp_path}/sbin"
        cp -f -- "${common_files}/sbin/kmod" "${tmp_path}/sbin/kmod"
        chmod +x "${tmp_path}/sbin/kmod"
        kmod_list="depmod insmod lsmod modinfo modprobe rmmod"
        for ki in ${kmod_list}; do
            rm -f -- "${tmp_path}/sbin/${ki}"
            ln -sf kmod "${tmp_path}/sbin/${ki}"
        done
    )

    [[ -f "${common_files}/etc/banner" ]] && {
        cp -f -- "${common_files}/etc/banner" "${tmp_path}/etc/banner"
        echo -e "${INFO} 写入 Docker 标识。"
        echo " Board: docker | Production Date: $(date +%Y-%m-%d)" >>"${tmp_path}/etc/banner"
        echo "───────────────────────────────────────────────────────────────────────" >>"${tmp_path}/etc/banner"
    }
}

make_dockerimg() {
    cd "${tmp_path}"
    echo -e "${STEPS} 开始制作 Docker 镜像 rootfs..."

    tar -czf "${current_path}/${docker_rootfs_file}" .

    rm -rf -- "${out_path}" && mkdir -p -- "${out_path}"
    mv -f -- "${current_path}/${docker_rootfs_file}" "${out_path}"
    echo -e "${INFO} Docker rootfs 打包成功。"

    cd ${current_path}

    cp -f -- "${docker_path}/Dockerfile" "${out_path}"
    echo -e "${INFO} Dockerfile 复制成功。"

    rm -rf -- "${tmp_path}"

    sync && sleep 3
    echo -e "${INFO} Docker files list: \n$(ls -l "${out_path}")"
    echo -e "${SUCCESS} Docker 镜像文件已生成。"
}

echo -e "${STEPS} Docker 镜像制作工具启动。"
echo -e "${INFO} 工作目录：[ ${PWD} ]"
find_openwrt
adjust_settings
make_dockerimg
