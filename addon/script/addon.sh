#!/system/bin/sh
#
##############################################################
# File name       : addon.sh
#
# Description     : BiTGApps addon installer script
#
# Build Date      : Monday May 04 10:30:21 IST 2020
#
# BiTGApps Author : TheHitMan @ xda-developers
#
# Copyright       : Copyright (C) 2020 TheHitMan7 (Kartik Verma)
#
# License         : SPDX-License-Identifier: GPL-3.0-or-later
##############################################################
# The BiTGApps scripts are free software: you can redistribute it
# and/or modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# These scripts are distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
##############################################################

# Clone this script using following commands
# curl https://raw.githubusercontent.com/BiTGApps/BiTGApps/master/addon/script/addon.sh > /cache/addon.sh
#
# Install addon using following commands
# su
# cd /cache && chmod +x ./addon.sh
# ./addon.sh

# Set shell defaults
CYAN='\033[0;36m'
RED='\033[0;41m'
NC='\033[0m'

# Backup
rm -rf /sdcard/addon
mkdir /sdcard/addon

# Android SDK check
android_sdk=`getprop ro.build.version.sdk`

if [ "$android_sdk" == "29" ] || [ "$android_sdk" == "28" ]; then
  mount -o rw,remount /
else
  mount -o rw,remount /system
fi;

# Installation layout
echo "=========================="
busybox echo -e "${RED} BiTGApps Addon Installer ${NC}"
echo "=========================="
PS3='Please enter your choice: '
options=("Assistant" "Wellbeing" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Assistant")
            busybox echo -e "${CYAN}  => Removing Pre-installed Assistant Package ${NC}"
            rm -rf /system/priv-app/Velvet 2>/dev/null;
            rm -rf /system/product/priv-app/Velvet 2>/dev/null;
            busybox echo -e "${CYAN}  => Downloading Prebuilt Assistant Package ${NC}"
            busybox wget https://github.com/BiTGApps/BiTGApps/raw/master/addon/prebuilt/prebuilt_Velvet.tar.xz -O /cache/prebuilt_Velvet.tar.xz
            busybox echo -e "${CYAN}  => Installing Assistant Package ${NC}"
            if [ "$android_sdk" == "29" ]; then
              busybox tar -xf /cache/prebuilt_Velvet.tar.xz -C /system/product/priv-app 2>/dev/null;
              chmod 0755 /system/product/priv-app/Velvet 2>/dev/null;
              chmod 0644 /system/product/priv-app/Velvet/Velvet.apk 2>/dev/null;
              chcon -h u:object_r:system_file:s0 "/system/product/priv-app/Velvet/Velvet.apk"; 2>/dev/null;
              busybox echo -e "${CYAN}  => Check Installed Package ${NC}"
              if [ -f /system/product/priv-app/Velvet/Velvet.apk ]; then
                ls /system/product/priv-app/Velvet/Velvet.apk
              else
                echo "  => Package not installed" && break
              fi;
            else
              busybox tar -xf /cache/prebuilt_Velvet.tar.xz -C /system/priv-app 2>/dev/null;
              chmod 0755 /system/priv-app/Velvet 2>/dev/null;
              chmod 0644 /system/priv-app/Velvet/Velvet.apk 2>/dev/null;
              chcon -h u:object_r:system_file:s0 "/system/priv-app/Velvet/Velvet.apk"; 2>/dev/null;
              busybox echo -e "${CYAN}  => Check Installed Package ${NC}"
              if [ -f /system/priv-app/Velvet/Velvet.apk ]; then
                ls /system/priv-app/Velvet/Velvet.apk
              else
                echo "  => Package not installed" && break
              fi;
            fi;
            if [ -f /system/product/priv-app/Velvet/Velvet.apk ]; then
              busybox echo -e "${CYAN}  => Backup Assistant Package ${NC}"
              busybox tar -czf /sdcard/addon/prebuilt_Velvet.tar.gz /system/product/priv-app/Velvet
            else
              busybox echo -e "${CYAN}  => Backup Assistant Package ${NC}"
              busybox tar -czf /sdcard/addon/prebuilt_Velvet.tar.gz /system/priv-app/Velvet
            fi;
            rm -rf /cache/prebuilt_Velvet.tar.xz 2>/dev/null;
            busybox echo -e "${CYAN}  => Installation Finished ${NC}"
            break
            ;;
        "Wellbeing")
            busybox echo -e "${CYAN}  => Removing Pre-installed Wellbeing Package ${NC}"
            rm -rf /system/priv-app/Wellbeing 2>/dev/null;
            rm -rf /system/priv-app/WellbeingPrebuilt 2>/dev/null;
            rm -rf /system/product/priv-app/Wellbeing 2>/dev/null;
            rm -rf /system/product/priv-app/WellbeingPrebuilt 2>/dev/null;
            busybox echo -e "${CYAN}  => Downloading Prebuilt Wellbeing Package ${NC}"
            busybox wget https://github.com/BiTGApps/BiTGApps/raw/master/addon/prebuilt/prebuilt_Wellbeing.tar.xz -O /cache/prebuilt_Wellbeing.tar.xz
            busybox echo -e "${CYAN}  => Installing Wellbeing Package ${NC}"
            if [ "$android_sdk" == "29" ]; then
              busybox tar -xf /cache/prebuilt_Wellbeing.tar.xz -C /system/product/priv-app 2>/dev/null;
              chmod 0755 /system/product/priv-app/WellbeingPrebuilt 2>/dev/null;
              chmod 0644 /system/product/priv-app/WellbeingPrebuilt/WellbeingPrebuilt.apk 2>/dev/null;
              chcon -h u:object_r:system_file:s0 "/system/product/priv-app/WellbeingPrebuilt/WellbeingPrebuilt.apk"; 2>/dev/null;
              busybox echo -e "${CYAN}  => Check Installed Package ${NC}"
              if [ -f /system/product/priv-app/WellbeingPrebuilt/WellbeingPrebuilt.apk ]; then
                ls /system/product/priv-app/WellbeingPrebuilt/WellbeingPrebuilt.apk
              else
                echo "  => Package not installed" && break
              fi;
            else
              busybox tar -xf /cache/prebuilt_Wellbeing.tar.xz -C /system/priv-app 2>/dev/null;
              chmod 0755 /system/priv-app/WellbeingPrebuilt 2>/dev/null;
              chmod 0644 /system/priv-app/WellbeingPrebuilt/WellbeingPrebuilt.apk 2>/dev/null;
              chcon -h u:object_r:system_file:s0 "/system/priv-app/WellbeingPrebuilt/WellbeingPrebuilt.apk"; 2>/dev/null;
              busybox echo -e "${CYAN}  => Check Installed Package ${NC}"
              if [ -f /system/priv-app/WellbeingPrebuilt/WellbeingPrebuilt.apk ]; then
                ls /system/priv-app/WellbeingPrebuilt/WellbeingPrebuilt.apk
              else
                echo "  => Package not installed" && break
              fi;
            fi;
            if [ -f /system/product/priv-app/WellbeingPrebuilt/WellbeingPrebuilt.apk ]; then
              busybox echo -e "${CYAN}  => Backup WellbeingPrebuilt Package ${NC}"
              busybox tar -czf /sdcard/addon/prebuilt_Wellbeing.tar.gz /system/product/priv-app/WellbeingPrebuilt
            else
              busybox echo -e "${CYAN}  => Backup WellbeingPrebuilt Package ${NC}"
              busybox tar -czf /sdcard/addon/prebuilt_Wellbeing.tar.gz /system/priv-app/WellbeingPrebuilt
            fi;
            rm -rf /cache/prebuilt_Wellbeing.tar.xz 2>/dev/null;
            busybox echo -e "${CYAN}  => Installation Finished ${NC}"
            break
            ;;
        "Quit")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done
