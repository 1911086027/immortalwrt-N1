#!/usr/bin/env bash
set -Eeuo pipefail
current_path="${PWD}"
openwrt_path="${current_path}/openwrt/bin/targets/*/*"
openwrt_rootfs_file="*rootfs.tar.gz"
docker_rootfs_file="openwrt-docker-armvirt-64-default-rootfs.tar.gz"
docker_path="${current_path}/docker"
common_files="${docker_path}/files"
tmp_path="${current_path}/tmp"
out_path="${current_path}/out"

STEPS="[\033[95m STEPS \033[0m]"
INFO="[\033[94m INFO \033[0m]"
SUCCESS="[\033[92m SUCCESS \033[0m]"
ERROR="[\033[91m ERROR \033[0m]"

trap 'error_msg "Command failed at line ${BASH_LINENO[0]}: ${BASH_COMMAND}"' ERR

error_msg() {
    echo -e "${ERROR} ${1}"
    exit 1
}

check_depends() {
    is_dpkg="0"
    dpkg_packages=("tar" "gzip")
    for package in "${dpkg_packages[@]}"; do
        [[ -n "$(dpkg -l | awk '{print $2}' | grep -w "^${package}$" 2>/dev/null)" ]] || is_dpkg="1"
    done

    if [[ "${is_dpkg}" -eq "1" ]]; then
        echo -e "${STEPS} Start installing the necessary dependencies..."
        sudo apt-get update
        sudo apt-get install -y "${dpkg_packages[@]}" ||
            error_msg "Dependency installation failed."
    fi
}

find_openwrt() {
    cd ${current_path}
    echo -e "${STEPS} Start searching for OpenWrt file..."

    openwrt_file_name="$(find ${openwrt_path} -maxdepth 1 -type f -name "${openwrt_rootfs_file}" -print -quit)"
    if [[ -n "${openwrt_file_name}" ]]; then
        echo -e "${INFO} OpenWrt file: [ ${openwrt_file_name##*/} ]"
    else
        error_msg "There is no [ ${openwrt_rootfs_file} ] file in the [ ${openwrt_path} ] directory."
    fi

    [[ -f "${docker_path}/Dockerfile" ]] || error_msg "Missing Dockerfile."
}

adjust_settings() {
    cd ${current_path}
    echo -e "${STEPS} Start adjusting OpenWrt file settings..."

    echo -e "${INFO} Unpack Openwrt."
    rm -rf ${tmp_path} && mkdir -p ${tmp_path}
    tar -xzf "${openwrt_file_name}" -C "${tmp_path}"

    echo -e "${INFO} Remove useless files."
    rm -rf ${tmp_path}/lib/firmware/*
    rm -rf ${tmp_path}/lib/modules/*
    rm -f ${tmp_path}/root/.todo_rootfs_resize
    find ${tmp_path} -name '*.rej' -exec rm {} \;
    find ${tmp_path} -name '*.orig' -exec rm {} \;
    rm -f ${tmp_path}/usr/lib/lua/luci/controller/amlogic.lua
    rm -rf ${tmp_path}/usr/lib/lua/luci/model/cbi/amlogic
    rm -rf ${tmp_path}/usr/share/amlogic
    rm -f ${tmp_path}/usr/sbin/openwrt-*-*
    rm -f ${tmp_path}/etc/init.d/amlogic
    rm -f ${tmp_path}/usr/lib/lua/luci/controller/docker*
    rm -rf ${tmp_path}/usr/lib/lua/luci/model/cbi/docker*
    rm -f ${tmp_path}/usr/lib/lua/luci/model/docker*
    rm -f ${tmp_path}/usr/bin/docker*
    rm -f ${tmp_path}/etc/init.d/docker*

    [[ -f "${tmp_path}/etc/config/turboacc" ]] && {
        echo -e "${INFO} Adjust turboacc settings."
        sed -i "s|option hw_flow.*|option hw_flow '0'|g" ${tmp_path}/etc/config/turboacc
        sed -i "s|option sw_flow.*|option sw_flow '0'|g" ${tmp_path}/etc/config/turboacc
    }

    [[ -f "${tmp_path}/etc/config/cpufreq" ]] && {
        echo -e "${INFO} Adjust cpufreq settings"
        sed -i "s/ondemand/schedutil/g" ${tmp_path}/etc/config/cpufreq
    }

    [[ -f "${common_files}/sbin/kmod" ]] && (
        echo -e "${INFO} Adjust kmod settings."
        mkdir -p -- "${tmp_path}/sbin"
        cp -f -- "${common_files}/sbin/kmod" "${tmp_path}/sbin/kmod"
        chmod +x ${tmp_path}/sbin/kmod
        kmod_list="depmod insmod lsmod modinfo modprobe rmmod"
        for ki in ${kmod_list}; do
            rm -f ${tmp_path}/sbin/${ki}
            ln -sf kmod ${tmp_path}/sbin/${ki}
        done
    )

    [[ -f "${common_files}/etc/banner" ]] && {
        cp -f ${common_files}/etc/banner ${tmp_path}/etc/banner
        echo -e "${INFO} Adjust banner settings."
        echo " Board: docker | Production Date: $(date +%Y-%m-%d)" >>${tmp_path}/etc/banner
        echo "───────────────────────────────────────────────────────────────────────" >>${tmp_path}/etc/banner
    }
}

make_dockerimg() {
    cd ${tmp_path}
    echo -e "${STEPS} Start making docker image..."

    tar -czf "${current_path}/${docker_rootfs_file}" .

    rm -rf ${out_path} && mkdir -p ${out_path}
    mv -f -- "${current_path}/${docker_rootfs_file}" "${out_path}"
    echo -e "${INFO} Docker image packaging succeeded."

    cd ${current_path}

    cp -f -- "${docker_path}/Dockerfile" "${out_path}"
    echo -e "${INFO} Dockerfile added successfully."

    rm -rf ${tmp_path}

    sync && sleep 3
    echo -e "${INFO} Docker files list: \n$(ls -l ${out_path})"
    echo -e "${SUCCESS} Docker image successfully created."
}

echo -e "${STEPS} Welcome to the Docker Image Maker Tool."
echo -e "${INFO} Make path: [ ${PWD} ]"
check_depends
find_openwrt
adjust_settings
make_dockerimg
