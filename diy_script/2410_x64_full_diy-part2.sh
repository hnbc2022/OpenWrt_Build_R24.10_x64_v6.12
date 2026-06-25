#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: 2410_x64_full_diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

echo "开始 DIY2 配置……"
echo "========================="
build_date=$(TZ=Asia/Shanghai date "+%Y.%m.%d")
build_name="全功能大满贯版"

# 🟢 [修改] 默认 LAN 地址改为 192.168.15.15
sed -i 's/192.168.1.1/192.168.15.15/g' package/base-files/files/bin/config_generate

# 🟢 [强力修正] 彻底清洗源码中所有潜伏的老旧主机名，强制锁定为主机名：OpenWrt-PENGCHAO
sed -i 's/OpenWrt-GXNAS/OpenWrt-PENGCHAO/g' package/base-files/files/bin/config_generate
sed -i 's/OpenWrt/OpenWrt-PENGCHAO/g' package/base-files/files/bin/config_generate
sed -i 's/set system.@system\[0\].hostname=.*/set system.@system[0].hostname="OpenWrt-PENGCHAO"/' package/base-files/files/bin/config_generate

# 最大连接数修改为65535
sed -i '/customized in this file/a net.netfilter.nf_conntrack_max=65535' package/base-files/files/etc/sysctl.conf

# 🟢 [核心修改] 强行清空 root 初始密码（抹除老旧 MD5 影子哈希，实现初次网页/客户端彻底免密登录）
mkdir -p package/base-files/files/etc
sed -i '/root/d' package/base-files/files/etc/shadow
echo 'root::0:0:99999:7:::' >> package/base-files/files/etc/shadow

# 🟢 [核心修改] 移除原有 Lean 固件在默认设置里可能写入的干扰密码残余
sed -i '/$1$V4UetPzk$CYXluq4wUazHjmCDBCqXF./d' package/lean/default-settings/files/zzz-default-settings

# 调整 x86 型号只显示 CPU 型号
sed -i 's/${g}.*/${a}${b}${c}${d}${e}${f}${hydrid}/g' package/lean/autocore/files/x86/autocore

# 设置ttyd免帐号登录
sed -i 's/\/bin\/login/\/bin\/login -f root/' feeds/packages/utils/ttyd/files/ttyd.config

# 设置argon为默认主题
sed -i '/set luci.main.mediaurlbase=\/luci-static\/bootstrap/d' feeds/luci/themes/luci-theme-bootstrap/root/etc/uci-defaults/30_luci-theme-bootstrap
sed -i 's/Bootstrap theme/Argon theme/g' feeds/luci/collections/*/Makefile
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/*/Makefile

# 显示增加编译时间 & 修改系统版本标志名称
sed -i "s/DISTRIB_REVISION='R[0-9]\+\.[0-9]\+\.[0-9]\+'/DISTRIB_REVISION='@R$build_date'/g" package/lean/default-settings/files/zzz-default-settings
sed -i "s/LEDE/OpenWrt-PENGCHAO_2410_x64_${build_name}/g" package/lean/default-settings/files/zzz-default-settings
sed -i 's/OpenWrt-GXNAS/OpenWrt-PENGCHAO/g' package/lean/default-settings/files/zzz-default-settings

# 自定义生成登录页和右下角的版本页脚说明 (移除原作者的私有文件复制操作，改用纯文件内替换或直接写入)
if [ -f package/luci-theme-argon/ucode/template/themes/argon/footer.ut ]; then
    sed -i "s/OpenWrt.*/OpenWrt-PENGCHAO ${build_name} @R${build_date}/g" package/luci-theme-argon/ucode/template/themes/argon/footer.ut
fi
if [ -f package/luci-theme-argon/ucode/template/themes/argon/footer_login.ut ]; then
    sed -i "s/OpenWrt.*/OpenWrt-PENGCHAO ${build_name} @R${build_date}/g" package/luci-theme-argon/ucode/template/themes/argon/footer_login.ut
fi

# 🟢 [修改] 已恢复以前的系统默认欢迎 banner 文本（不再强制覆盖）

# 修复 netdata 不会自动启动的问题
echo ">>> Fix netdata init.d & enable service"
if [ -f /etc/init.d/netdata ]; then
  echo "netdata init script exists"
else
  if [ -f package/luci-app-netdata/root/etc/init.d/netdata ]; then
    chmod +x package/luci-app-netdata/root/etc/init.d/netdata
  fi
fi
mkdir -p package/base-files/files/etc/rc.d
ln -sf ../init.d/netdata package/base-files/files/etc/rc.d/S99netdata
mkdir -p package/base-files/files/etc/netdata
cat << 'EOF' > package/base-files/files/etc/netdata/netdata.conf
[global]
    run as user = root
    memory mode = ram
[cloud]
    enabled = no
EOF
mkdir -p package/base-files/files/etc/uci-defaults
cat << 'EOF' > package/base-files/files/etc/uci-defaults/99-netdata
#!/bin/sh
if [ -x /etc/init.d/netdata ]; then
  /etc/init.d/netdata enable
  /etc/init.d/netdata restart
fi
exit 0
EOF
chmod +x package/base-files/files/etc/uci-defaults/99-netdata

# 修复上游仓库不稳定造成ustream-ssl报错问题
find . -type f \( -name "Makefile" -o -name "*.mk" \) -exec sed -i 's#https://git.openwrt.org/#https://github.com/openwrt/#g' {} \;
if [ -f "$USTREAM_MK" ]; then
  sed -i 's/^PKG_SOURCE_PROTO.*/PKG_SOURCE_PROTO:=git/' $USTREAM_MK
  sed -i 's#https://github.com/openwrt/project/ustream-ssl.git#https://github.com/openwrt/ustream-ssl.git#g' $USTREAM_MK
  sed -i 's#https://git.openwrt.org/project/ustream-ssl.git#https://github.com/openwrt/ustream-ssl.git#g' $USTREAM_MK
  sed -i '/^PKG_SOURCE:=/d' $USTREAM_MK
  sed -i '/^PKG_HASH:=/d'   $USTREAM_MK
fi
rm -rf dl/ustream-ssl-*
rm -rf build_dir/target-*/ustream-ssl-*

# 移除 default-settings 中的 UPnP
find package/feeds -type f | xargs sed -i -e '/luci-app-upnp/d' -e '/luci-i18n-upnp/d' -e '/miniupnpd/d'
sed -i '/luci-app-upnp/d' package/Makefile
sed -i '/luci-i18n-upnp/d' package/Makefile
sed -i '/miniupnpd/d' package/Makefile
rm -f tmp/.package_install

# 修复 default-settings 问题
echo ">>> Purge default-settings (all variants)"
find package/feeds -maxdepth 2 -type d -name "default-settings*" -exec rm -rf {} +
rm -rf package/default-settings*

# 默认系统 UCI 配置 (全局彻底覆盖主机名和时区参数)
mkdir -p package/base-files/files/etc/uci-defaults
cat << 'EOF' > package/base-files/files/etc/uci-defaults/99-system
#!/bin/sh
uci set system.@system[0].hostname='OpenWrt-PENGCHAO'
uci set system.@system[0].zonename='Asia/Shanghai'
uci set system.@system[0].timezone='CST-8'
uci -q delete system.ntp.server
uci add_list system.ntp.server='ntp.aliyun.com'
uci add_list system.ntp.server='time1.cloud.tencent.com'
uci add_list system.ntp.server='time.apple.com'
uci add_list system.ntp.server='time.windows.com'
uci commit system
exit 0
EOF
chmod +x package/base-files/files/etc/uci-defaults/99-system

cat << 'EOF' > package/base-files/files/etc/uci-defaults/99-luci
#!/bin/sh
uci set luci.main.lang='zh_cn'
uci commit luci
exit 0
EOF
chmod +x package/base-files/files/etc/uci-defaults/99-luci

find . -type f \( -name "Makefile" -o -name "*.mk" \) \
-exec sed -i 's#https://git.openwrt.org/#https://github.com/openwrt/#g' {} \;

rm -rf dl/ustream-ssl-* build_dir/target-*/ustream-ssl-*
find package -type f | xargs sed -i \
  -e '/luci-app-upnp/d' \
  -e '/luci-i18n-upnp/d' \
  -e '/miniupnpd/d' || true

echo "========================="
echo " DIY2 配置完成……"
