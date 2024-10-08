#!/usr/bin/env bash
#=====================================================================================
# Description: Automatically Packaged OpenWrt
# Function: Use Flippy's kernrl files and script to Packaged openwrt
# Copyright (C) 2020-2021 Flippy
# Copyright (C) 2020-2021 https://github.com/ophub/flippy-openwrt-actions
#=====================================================================================

if [[ -z "${OPENWRT_ARMVIRT}" ]]; then
   echo "The [ OPENWRT_ARMVIRT ] variable must be specified."
   echo "You can use ${GITHUB_WORKSPACE} relative path: [ openwrt/bin/targets/*/*/*.tar.gz ]"
   echo "Absolute path can be used: [ https://github.com/.../releases/download/.../openwrt-armvirt-64-default-rootfs.tar.gz ]"
   echo "You can run this Actions again after setting."
   exit 1
fi

# Set the default value
MAKE_PATH=${PWD}
PACKAGE_OPENWRT=("vplus" "beikeyun" "l1pro" "s905" "s905d" "s905x2" "s905x3" "s912" "s922x")
SELECT_ARMBIANKERNEL=("5.13.2" "5.4.132")
SCRIPT_REPO_URL_VALUE="https://github.com/unifreq/openwrt_packit"
SCRIPT_REPO_BRANCH_VALUE="master"
KERNEL_REPO_URL_VALUE="https://github.com/ophub/amlogic-s9xxx-openwrt/trunk/amlogic-s9xxx/amlogic-kernel"
KERNEL_VERSION_NAME_VALUE="5.13.2_5.4.132"
PACKAGE_SOC_VALUE="s905d_s905x3_beikeyun"
GZIP_IMGS_VALUE="true"
SELECT_OUTPUTPATH_VALUE="/opt/openwrt_packit/tmp"
SAVE_OPENWRT_ARMVIRT_VALUE="true"

# Set the default packaging script
SCRIPT_VPLUS_FILE="mk_h6_vplus.sh"
SCRIPT_BEIKEYUN_FILE="mk_rk3328_beikeyun.sh"
SCRIPT_L1PRO_FILE="mk_rk3328_l1pro.sh"
SCRIPT_S905_FILE="mk_s905_mxqpro+.sh"
SCRIPT_S905D_FILE="mk_s905d_n1.sh"
SCRIPT_S905X2_FILE="mk_s905x2_x96max.sh"
SCRIPT_S905X3_FILE="mk_s905x3_multi.sh"
SCRIPT_S912_FILE="mk_s912_zyxq.sh"
SCRIPT_S022X_FILE="mk_s922x_gtking.sh"

# Set make.env related parameters
WHOAMI_VALUE="flippy"
OPENWRT_VER_VALUE="R21.7.15"
SFE_FLAG_VALUE="0"
FLOWOFFLOAD_FLAG_VALUE="1"
ENABLE_WIFI_K504_VALUE="1"
ENABLE_WIFI_K510_VALUE="1"

# Set font color
blue_font_prefix="\033[34m"
purple_font_prefix="\033[35m"
green_font_prefix="\033[32m"
yellow_font_prefix="\033[33m"
red_font_prefix="\033[31m"
font_color_suffix="\033[0m"
INFO="[${blue_font_prefix}INFO${font_color_suffix}]"
STEPS="[${purple_font_prefix}STEPS${font_color_suffix}]"
SUCCESS="[${green_font_prefix}SUCCESS${font_color_suffix}]"
WARNING="[${yellow_font_prefix}WARNING${font_color_suffix}]"
ERROR="[${red_font_prefix}ERROR${font_color_suffix}]"

# Specify the default value
[[ -n "${SCRIPT_REPO_URL}" ]] || SCRIPT_REPO_URL="${SCRIPT_REPO_URL_VALUE}"
[[ ${SCRIPT_REPO_URL} == http* ]] || SCRIPT_REPO_URL="https://github.com/${SCRIPT_REPO_URL}"
[[ -n "${SCRIPT_REPO_BRANCH}" ]] || SCRIPT_REPO_BRANCH="${SCRIPT_REPO_BRANCH_VALUE}"
[[ -n "${KERNEL_REPO_URL}" ]] || KERNEL_REPO_URL="${KERNEL_REPO_URL_VALUE}"
[[ ${KERNEL_REPO_URL} == http* ]] || KERNEL_REPO_URL="https://github.com/${KERNEL_REPO_URL}"
[[ -n "${PACKAGE_SOC}" ]] || PACKAGE_SOC="${PACKAGE_SOC_VALUE}"
[[ -n "${KERNEL_VERSION_NAME}" ]] || KERNEL_VERSION_NAME="${KERNEL_VERSION_NAME_VALUE}"
[[ -n "${GZIP_IMGS}" ]] || GZIP_IMGS=${GZIP_IMGS_VALUE}
[[ -n "${SELECT_OUTPUTPATH}" ]] || SELECT_OUTPUTPATH="${SELECT_OUTPUTPATH_VALUE}"
[[ -n "${SAVE_OPENWRT_ARMVIRT}" ]] || SAVE_OPENWRT_ARMVIRT="${SAVE_OPENWRT_ARMVIRT_VALUE}"

# Specify the default packaging script
[[ -n "${SCRIPT_VPLUS}" ]] || SCRIPT_VPLUS="${SCRIPT_VPLUS_FILE}"
[[ -n "${SCRIPT_BEIKEYUN}" ]] || SCRIPT_BEIKEYUN="${SCRIPT_BEIKEYUN_FILE}"
[[ -n "${SCRIPT_L1PRO}" ]] || SCRIPT_L1PRO="${SCRIPT_L1PRO_FILE}"
[[ -n "${SCRIPT_S905}" ]] || SCRIPT_S905="${SCRIPT_S905_FILE}"
[[ -n "${SCRIPT_S905D}" ]] || SCRIPT_S905D="${SCRIPT_S905D_FILE}"
[[ -n "${SCRIPT_S905X2}" ]] || SCRIPT_S905X2="${SCRIPT_S905X2_FILE}"
[[ -n "${SCRIPT_S905X3}" ]] || SCRIPT_S905X3="${SCRIPT_S905X3_FILE}"
[[ -n "${SCRIPT_S912}" ]] || SCRIPT_S912="${SCRIPT_S912_FILE}"
[[ -n "${SCRIPT_S022X}" ]] || SCRIPT_S022X="${SCRIPT_S022X_FILE}"

# Specify make.env variable
[[ -n "${WHOAMI}" ]] || WHOAMI="${WHOAMI_VALUE}"
[[ -n "${OPENWRT_VER}" ]] || OPENWRT_VER="${OPENWRT_VER_VALUE}"
[[ -n "${SFE_FLAG}" ]] || SFE_FLAG="${SFE_FLAG_VALUE}"
[[ -n "${FLOWOFFLOAD_FLAG}" ]] || FLOWOFFLOAD_FLAG="${FLOWOFFLOAD_FLAG_VALUE}"
[[ -n "${ENABLE_WIFI_K504}" ]] || ENABLE_WIFI_K504="${ENABLE_WIFI_K504_VALUE}"
[[ -n "${ENABLE_WIFI_K510}" ]] || ENABLE_WIFI_K510="${ENABLE_WIFI_K510_VALUE}"

echo -e "${INFO} Welcome to use the OpenWrt packaging tool! \n"

cd /opt

# Server space usage
echo -e "${INFO} Server space usage before starting to compile:\n$(df -hT ${PWD}) \n"

# clone openwrt_packit repo
echo -e "${STEPS} Cloning package script repository [ ${SCRIPT_REPO_URL} ], branch [ ${SCRIPT_REPO_BRANCH} ] into openwrt_packit."
git clone --depth 1 ${SCRIPT_REPO_URL} -b ${SCRIPT_REPO_BRANCH} openwrt_packit

# Load openwrt-armvirt-64-default-rootfs.tar.gz
if [[ ${OPENWRT_ARMVIRT} == http* ]]; then
   echo -e "${STEPS} wget [ ${OPENWRT_ARMVIRT} ] file into openwrt_packit"
   wget ${OPENWRT_ARMVIRT} -q -P openwrt_packit
else
   echo -e "${STEPS} copy [ ${GITHUB_WORKSPACE}/${OPENWRT_ARMVIRT} ] file into openwrt_packit"
   cp -f ${GITHUB_WORKSPACE}/${OPENWRT_ARMVIRT} openwrt_packit
fi
sync

# Normal openwrt-armvirt-64-default-rootfs.tar.gz file should not be less than 10MB
armvirt_rootfs_size=$(ls -l openwrt_packit/openwrt-armvirt-64-default-rootfs.tar.gz 2>/dev/null | awk '{print $5}')
echo -e "${INFO} armvirt_rootfs_size: [ ${armvirt_rootfs_size} ]"
if [[ "${armvirt_rootfs_size}" -ge "10000000" ]]; then
   echo -e "${INFO} openwrt_packit/openwrt-armvirt-64-default-rootfs.tar.gz loaded successfully."
else
   echo -e "${ERROR} openwrt_packit/openwrt-armvirt-64-default-rootfs.tar.gz failed to load."
   exit 1
fi

# Load all selected kernels
[ -d kernel ] || sudo mkdir kernel
if  [[ -n "${KERNEL_VERSION_NAME}" ]]; then
    unset SELECT_ARMBIANKERNEL
    oldIFS=$IFS
    IFS=_
    SELECT_ARMBIANKERNEL=(${KERNEL_VERSION_NAME})
    IFS=$oldIFS
fi
echo -e "${INFO} Package OpenWrt Kernel List: [ ${SELECT_ARMBIANKERNEL[*]} ]"

i=1
for KERNEL_VAR in ${SELECT_ARMBIANKERNEL[*]}; do
    echo -e "${INFO} (${i}) ${KERNEL_VAR} Kernel loading from [ ${KERNEL_REPO_URL}/${KERNEL_VAR} ]"
    svn checkout ${KERNEL_REPO_URL}/${KERNEL_VAR} kernel
    pushd kernel && sudo rm -rf .svn && popd >/dev/null
    let i++
done
sync

# Confirm package object
if  [[ -n "${PACKAGE_SOC}" && "${PACKAGE_SOC}" != "all" ]]; then
    unset PACKAGE_OPENWRT
    oldIFS=$IFS
    IFS=_
    PACKAGE_OPENWRT=(${PACKAGE_SOC})
    IFS=$oldIFS
fi
echo -e "${INFO} Package OpenWrt SoC List: [ ${PACKAGE_OPENWRT[*]} ]"

# Packaged OpenWrt
echo -e "${STEPS} Start packaging openwrt..."
k=1
for KERNEL_VAR in ${SELECT_ARMBIANKERNEL[*]}; do

    KERNEL_VAR=${KERNEL_VAR//.TF/}
    boot_kernel_file=$( ls kernel/boot-${KERNEL_VAR}* 2>/dev/null | head -n 1 )
    boot_kernel_file=${boot_kernel_file##*/}
    boot_kernel_file=${boot_kernel_file//boot-/}
    boot_kernel_file=${boot_kernel_file//.tar.gz/}
    echo -e "${INFO} (${k}) KERNEL_VERSION: ${boot_kernel_file}"
    
    cd openwrt_packit
    
    rm -f make.env 2>/dev/null
    cat > make.env <<EOF
WHOAMI="${WHOAMI}"
OPENWRT_VER="${OPENWRT_VER}"
KERNEL_VERSION="${boot_kernel_file}"
KERNEL_PKG_HOME="/opt/kernel"
SFE_FLAG="${SFE_FLAG}"
FLOWOFFLOAD_FLAG="${FLOWOFFLOAD_FLAG}"
ENABLE_WIFI_K504="${ENABLE_WIFI_K504}"
ENABLE_WIFI_K510="${ENABLE_WIFI_K510}"
EOF
sync

    echo -e "${INFO} make.env file info:"
    cat make.env
    
    i=1
    for PACKAGE_VAR in ${PACKAGE_OPENWRT[*]}; do
        {
            echo -e "${STEPS} (${k}.${i}) Start packaging OpenWrt, Kernel is [ ${KERNEL_VAR} ], SoC is [ ${PACKAGE_VAR} ]"

            now_remaining_space=$(df -hT ${PWD} | grep '/dev/' | awk '{print $5}' | sed 's/.$//')
            if  [[ "${now_remaining_space}" -le "2" ]]; then
                echo -e "${WARNING} If the remaining space is less than 2G, exit this packaging. \n"
                break 2
            else
                echo -e "${INFO} Remaining space is ${now_remaining_space}G. \n"
            fi

            case "${PACKAGE_VAR}" in
                  vplus | s1) sudo ./${SCRIPT_VPLUS} ;;
                  beikeyun | s2) sudo ./${SCRIPT_BEIKEYUN} ;;
                  l1pro | s3) sudo ./${SCRIPT_L1PRO} ;;
                  s905 | s4) sudo ./${SCRIPT_S905} ;;
                  s905d | s5) sudo ./${SCRIPT_S905D} ;;
                  s905x2 | s6) sudo ./${SCRIPT_S905X2} ;;
                  s905x3 | s7) sudo ./${SCRIPT_S905X3} ;;
                  s912 | s8) sudo ./${SCRIPT_S912} ;;
                  s922x | s9) sudo ./${SCRIPT_S022X} ;;
                  *) ${WARNING} "Have no this SoC. Skipped."
                     continue ;;
            esac
            echo -e "${SUCCESS} (${k}.${i}) Package openwrt completed."
            sync
            
            if  [[ "${GZIP_IMGS_VALUE}" == "true" ]]; then
                echo -e "${STEPS} gzip the openwrt*.img files in the tmp folder. \n"
                cd tmp && gzip *.img && sync && cd ../
            fi
            
            let i++
        }
    done

    cd ../
    
    let k++
done
echo -e "${SUCCESS} All packaged completed. \n"

echo -e "${STEPS} Output environment variables."
if  [[ -d openwrt_packit/tmp ]]; then

    cd openwrt_packit/tmp

    if  [[ "${SAVE_OPENWRT_ARMVIRT}" == "true" ]]; then
        echo -e "${STEPS} copy openwrt-armvirt-64-default-rootfs.tar.gz files into tmp folder."
        cp -f ../openwrt-armvirt-64-default-rootfs.tar.gz . && sync
    fi
    
    echo -e "${STEPS} Output environment variables."
    echo "PACKAGED_OUTPUTPATH=${PWD}" >> $GITHUB_ENV
    echo "PACKAGED_OUTPUTDATE=$(date +"%Y.%m.%d.%H%M")" >> $GITHUB_ENV
    echo "PACKAGED_STATUS=success" >> $GITHUB_ENV
    echo -e "PACKAGED_OUTPUTPATH: ${PWD}"
    echo -e "PACKAGED_OUTPUTDATE: $(date +"%Y.%m.%d.%H%M")"
    echo -e "PACKAGED_STATUS: success"
    echo -e "${INFO} PACKAGED_OUTPUTPATH files list:"
    echo -e "$(ls /opt/openwrt_packit/tmp 2>/dev/null) \n"
else
    echo -e "${ERROR} Packaging failed. \n"
    echo "PACKAGED_STATUS=failure" >> $GITHUB_ENV
fi

# Server space usage and packaged files
echo -e "${INFO} Server space usage after compilation:\n$(df -hT ${PWD}) \n"
echo -e "${STEPS} The packaging process has been completed. \n"

