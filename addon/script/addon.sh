#!/system/bin/sh
#
##############################################################
# File name       : addon.sh
#
# Description     : BiTGApps addon installer script
#
# Build Date      : Monday May 04 10:30:21 IST 2020
#
# Updated on      : Thursday June 11 10:55:50 IST 2020
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
LRED='\033[1;31m'
NC='\033[0m'

# Root check
id=`id`; id=`echo ${id#*=}`; id=`echo ${id%%\(*}`; id=`echo ${id%% *}`
if [ "$id" != "0" ] && [ "$id" != "root" ]; then
  sleep 1
  echo ""
  echo "You are NOT running as root..."
  echo ""
  sleep 1
  echo ""
  echo "Please type 'su' first before typing 'addon.sh'..."
  echo ""
  exit
fi;

# Backup
rm -rf /sdcard/addon
mkdir /sdcard/addon

# Android SDK check
android_sdk=`getprop ro.build.version.sdk`

# Mount system partition
mount -o rw,remount / 2>/dev/null;
mount -o rw,remount /system 2>/dev/null;

# Check system mount
MOUNTED_FS="false"
if [ -f /system/build.prop ]; then
  MOUNTED_FS="true"
fi;
if [ "$MOUNTED_FS" == "false" ]; then
  echo "Unable to mount system. Aborting...";
  sleep 2
  exit 1
fi;

# Set Busybox
BB="/data/adb/magisk/busybox"
if [ -f "$BB" ]; then
  MAGISK="true"
fi;
if [ "$MAGISK" == "false" ]; then
  echo "Unable to find magisk busybox. Aborting...";
  sleep 2
  exit 1
fi;

# Installation layout
echo "=========================="
$BB echo -e "${RED} BiTGApps Addon Installer ${NC}"
echo "=========================="
PS3='Please enter your choice: '
options=("Assistant" "Wellbeing" "Reboot" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Assistant")
            $BB echo -e "${CYAN}  => Downloading Prebuilt Assistant Package ${NC}"
            curl https://bitgapps.cf/addon/VelvetPrebuilt.tar.xz > /cache/VelvetPrebuilt.tar.xz
            $BB echo -e "${CYAN}  => Installing Assistant Package ${NC}"
            if [ "$android_sdk" == "29" ]; then
              $BB tar -xf /cache/VelvetPrebuilt.tar.xz -C /system/product/priv-app 2>/dev/null;
              chmod 0755 /system/product/priv-app/Velvet 2>/dev/null;
              chmod 0644 /system/product/priv-app/Velvet/Velvet.apk 2>/dev/null;
              chcon -h u:object_r:system_file:s0 "/system/product/priv-app/Velvet/Velvet.apk" 2>/dev/null;
              $BB echo -e "${CYAN}  => Check Installed Package ${NC}"
              if [ -f /system/product/priv-app/Velvet/Velvet.apk ]; then
                $BB echo -e "${CYAN}  => Package installed ${NC}"
                $BB echo -e "${CYAN}  => Backup Assistant Package ${NC}"
                cp -f /cache/VelvetPrebuilt.tar.xz /sdcard/addon/VelvetPrebuilt.tar.xz
              else
                $BB echo -e "${LRED}  => Package not installed ${NC}" && break
              fi;
              rm -rf /cache/VelvetPrebuilt.tar.xz 2>/dev/null;
              $BB echo -e "${CYAN}  => Installation Finished ${NC}"
            else
              $BB tar -xf /cache/VelvetPrebuilt.tar.xz -C /system/priv-app 2>/dev/null;
              chmod 0755 /system/priv-app/Velvet 2>/dev/null;
              chmod 0644 /system/priv-app/Velvet/Velvet.apk 2>/dev/null;
              chcon -h u:object_r:system_file:s0 "/system/priv-app/Velvet/Velvet.apk" 2>/dev/null;
              $BB echo -e "${CYAN}  => Check Installed Package ${NC}"
              if [ -f /system/priv-app/Velvet/Velvet.apk ]; then
                $BB echo -e "${CYAN}  => Package installed ${NC}"
                $BB echo -e "${CYAN}  => Backup Assistant Package ${NC}"
                cp -f /cache/VelvetPrebuilt.tar.xz /sdcard/addon/VelvetPrebuilt.tar.xz
              else
                $BB echo -e "${LRED}  => Package not installed ${NC}" && break
              fi;
            fi;
            rm -rf /cache/VelvetPrebuilt.tar.xz 2>/dev/null;
            $BB echo -e "${CYAN}  => Installation Finished ${NC}"
            ;;
        "Wellbeing")
            $BB echo -e "${CYAN}  => Downloading Prebuilt Wellbeing Package ${NC}"
            curl https://bitgapps.cf/addon/WellbeingPrebuilt.tar.xz > /cache/WellbeingPrebuilt.tar.xz
            $BB echo -e "${CYAN}  => Installing Wellbeing Package ${NC}"
            if [ "$android_sdk" == "29" ]; then
              $BB tar -xf /cache/WellbeingPrebuilt.tar.xz -C /system/product/priv-app 2>/dev/null;
              chmod 0755 /system/product/priv-app/WellbeingPrebuilt 2>/dev/null;
              chmod 0644 /system/product/priv-app/WellbeingPrebuilt/WellbeingPrebuilt.apk 2>/dev/null;
              chcon -h u:object_r:system_file:s0 "/system/product/priv-app/WellbeingPrebuilt/WellbeingPrebuilt.apk" 2>/dev/null;
              $BB echo -e "${CYAN}  => Check Installed Package ${NC}"
              if [ -f /system/product/priv-app/WellbeingPrebuilt/WellbeingPrebuilt.apk ]; then
                $BB echo -e "${CYAN}  => Package installed ${NC}"
                $BB echo -e "${CYAN}  => Backup WellbeingPrebuilt Package ${NC}"
                cp -f /cache/WellbeingPrebuilt.tar.xz /sdcard/addon/WellbeingPrebuilt.tar.xz
              else
                $BB echo -e "${LRED}  => Package not installed ${NC}" && break
              fi;
              rm -rf /cache/WellbeingPrebuilt.tar.xz 2>/dev/null;
              $BB echo -e "${CYAN}  => Installation Finished ${NC}"
            elif [ "$android_sdk" == "28" ]; then
              $BB tar -xf /cache/WellbeingPrebuilt.tar.xz -C /system/priv-app 2>/dev/null;
              chmod 0755 /system/priv-app/WellbeingPrebuilt 2>/dev/null;
              chmod 0644 /system/priv-app/WellbeingPrebuilt/WellbeingPrebuilt.apk 2>/dev/null;
              chcon -h u:object_r:system_file:s0 "/system/priv-app/WellbeingPrebuilt/WellbeingPrebuilt.apk" 2>/dev/null;
              $BB echo -e "${CYAN}  => Check Installed Package ${NC}"
              if [ -f /system/priv-app/WellbeingPrebuilt/WellbeingPrebuilt.apk ]; then
                $BB echo -e "${CYAN}  => Package installed ${NC}"
                $BB echo -e "${CYAN}  => Backup WellbeingPrebuilt Package ${NC}"
                cp -f /cache/WellbeingPrebuilt.tar.xz /sdcard/addon/WellbeingPrebuilt.tar.xz
              else
                $BB echo -e "${LRED}  => Package not installed ${NC}" && break
              fi;
              rm -rf /cache/WellbeingPrebuilt.tar.xz 2>/dev/null;
              $BB echo -e "${CYAN}  => Installation Finished ${NC}"
            else
              $BB echo -e "${LRED}  => Unsupported Android SDK Version $android_sdk ${NC}"
              rm -rf /cache/WellbeingPrebuilt.tar.xz 2>/dev/null;
              $BB echo -e "${LRED}  => Package not installed ${NC}" && break
            fi;
            ;;
        "Reboot")
            $BB echo -e "${LRED}  => Rebooting in 2 Secs ${NC}"
            sleep 2
            reboot
            ;;
        "Quit")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done
