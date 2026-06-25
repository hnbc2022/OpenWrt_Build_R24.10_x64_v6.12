#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: 2410_x64_full_diy-part1.sh
# Description: OpenWrt DIY script part 1 (Before Update feeds)
#

echo "开始 DIY1 核心拉取组件配置……"
echo "========================="

# 添加源仓库
sed -i '/helloworld/d' feeds.conf.default
sed -i '/small/d' feeds.conf.default
sed -i '/passwall/d' feeds.conf.default
sed -i '2i src-git small https://github.com/kenzok8/small' feeds.conf.default
sed -i '$a src-git helloworld https://github.com/fw876/helloworld' feeds.conf.default
sed -i '$a src-git passwall_packages https://github.com/Openwrt-Passwall/openwrt-passwall-packages.git;main' feeds.conf.default
sed -i '$a src-git passwall_luci https://github.com/Openwrt-Passwall/openwrt-passwall.git;main' feeds.conf.default
sed -i '$a src-git openclaw https://github.com/10000ge10000/luci-app-openclaw.git;main' feeds.conf.default

# 添加 adguardHome
git clone --depth=1 https://github.com/kongfl888/luci-app-adguardhome package/luci-app-adguardhome

# 添加 argon 主题 (移除在part1阶段无效的 rm -rf feeds/ 逻辑，改用 depth=1 高速拉取)
git clone --depth=1 https://github.com/jerrykuku/luci-theme-argon.git package/luci-theme-argon
git clone --depth=1 https://github.com/jerrykuku/luci-app-argon-config.git package/luci-app-argon-config

# 添加 Lucky
git clone --depth=1 https://github.com/gdy666/luci-app-lucky.git package/lucky

# 添加 netdata
git clone --depth=1 https://github.com/sirpdboy/luci-app-netdata package/luci-app-netdata

# 添加 oaf
git clone --depth=1 https://github.com/destan19/OpenAppFilter.git package/OpenAppFilter

# 添加 passwall-packages (移除在part1阶段无效的 rm -rf feeds/ 逻辑)
git clone --depth=1 https://github.com/xiaorouji/openwrt-passwall-packages package/passwall-packages

# 添加 poweroffdevice
git clone --depth=1 https://github.com/sirpdboy/luci-app-poweroffdevice.git package/luci-app-poweroffdevice

# 添加 istore
git clone --depth=1 https://github.com/linkease/istore-ui package/luci-app-store-ui
git clone --depth=1 https://github.com/linkease/istore package/luci-app-store

echo "========================="
echo " DIY1 配置完成……"
