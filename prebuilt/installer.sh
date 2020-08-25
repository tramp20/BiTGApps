#!/sbin/sh
#
##############################################################
# File name       : installer.sh
#
# Description     : Main installation script of BiTGApps
#
# Build Date      : Friday March 15 11:36:43 IST 2019
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

# Import OUTFD function
ui_print() {
  echo -n -e "ui_print $1\n" >> /proc/self/fd/$OUTFD
  echo -n -e "ui_print\n" >> /proc/self/fd/$OUTFD
}

# Unset predefined environmental variable
recovery_actions() {
  OLD_LD_LIB=$LD_LIBRARY_PATH
  OLD_LD_PRE=$LD_PRELOAD
  OLD_LD_CFG=$LD_CONFIG_FILE
  unset LD_LIBRARY_PATH
  unset LD_PRELOAD
  unset LD_CONFIG_FILE
}

# Restore predefined environmental variable
recovery_cleanup() {
  unset -f getprop;
  test "$OLD_LD_LIB" && export LD_LIBRARY_PATH=$OLD_LD_PATH;
  test "$OLD_LD_PRE" && export LD_PRELOAD=$OLD_LD_PRE;
  test "$OLD_LD_CFG" && export LD_CONFIG_FILE=$OLD_LD_CFG;
}

# Change SELinux status to permissive
selinux() {
  setenforce 0;
}

# Static unzip function
unpack_zip() {
  for f in $ZIP; do
    unzip -o "$ZIPFILE" "$f" -d "$TMP";
  done
}

# insert_line <file> <if search string> <before|after> <line match string> <inserted line>
insert_line() {
  local offset line;
  if ! grep -q "$2" $1; then
    case $3 in
      before) offset=0;;
      after) offset=1;;
    esac;
    line=$((`grep -n "$4" $1 | head -n1 | cut -d: -f1` + offset));
    if [ -f $1 -a "$line" ] && [ "$(wc -l $1 | cut -d\  -f1)" -lt "$line" ]; then
      echo "$5" >> $1;
    else
      sed -i "${line}s;^;${5}\n;" $1;
    fi;
  fi;
}

# replace_line <file> <line replace string> <replacement line>
replace_line() {
  if grep -q "$2" $1; then
    local line=$(grep -n "$2" $1 | head -n1 | cut -d: -f1);
    sed -i "${line}s;.*;${3};" $1;
  fi;
}

# remove_line <file> <line match string>
remove_line() {
  if grep -q "$2" $1; then
    local line=$(grep -n "$2" $1 | head -n1 | cut -d: -f1);
    sed -i "${line}d" $1;
  fi;
}

# Set package defaults
build_defaults() {
  # Set temporary zip directory
  ZIP_FILE="$TMP/zip";
  # Create temporary unzip directory
  mkdir $TMP/unzip
  chmod 0755 $TMP/unzip
  # Create temporary outfile directory
  mkdir $TMP/out
  chmod 0755 $TMP/out
  # Create temporary restore directory
  mkdir $TMP/restore
  chmod 0755 $TMP/restore
  # Create temporary links
  UNZIP_DIR="$TMP/unzip";
  TMP_ADDON="$UNZIP_DIR/tmp_addon";
  TMP_SYS="$UNZIP_DIR/tmp_sys";
  TMP_SYS_ROOT="$UNZIP_DIR/tmp_sys_root";
  TMP_SYS_AOSP="$UNZIP_DIR/tmp_sys_aosp";
  TMP_PRIV="$UNZIP_DIR/tmp_priv";
  TMP_PRIV_ROOT="$UNZIP_DIR/tmp_priv_root";
  TMP_PRIV_SETUP="$UNZIP_DIR/tmp_priv_setup";
  TMP_PRIV_AOSP="$UNZIP_DIR/tmp_priv_aosp";
  TMP_LIB="$UNZIP_DIR/tmp_lib";
  TMP_LIB64="$UNZIP_DIR/tmp_lib64";
  TMP_FRAMEWORK="$UNZIP_DIR/tmp_framework";
  TMP_CONFIG="$UNZIP_DIR/tmp_config";
  TMP_DEFAULT_PERM="$UNZIP_DIR/tmp_default";
  TMP_G_PERM="$UNZIP_DIR/tmp_perm";
  TMP_G_PERM_AOSP="$UNZIP_DIR/tmp_perm_aosp";
  TMP_G_PREF="$UNZIP_DIR/tmp_pref";
  TMP_PERM_ROOT="$UNZIP_DIR/tmp_perm_root";
  # Set logging
  LOG="/cache/bitgapps/installation.log";
  config_log="/cache/bitgapps/config-installation.log";
  restore="/cache/bitgapps/backup-script.log";
  whitelist="/cache/bitgapps/whitelist.log";
  SQLITE_LOG="/cache/bitgapps/sqlite.log";
  SQLITE_TOOL="/tmp/sqlite3";
  ZIPALIGN_LOG="/cache/bitgapps/zipalign.log";
  ZIPALIGN_TOOL="/tmp/zipalign";
  ZIPALIGN_OUTFILE="/tmp/out";
  sdk_v29="/cache/bitgapps/sdk_v29.log";
  sdk_v28="/cache/bitgapps/sdk_v28.log";
  sdk_v27="/cache/bitgapps/sdk_v27.log";
  sdk_v25="/cache/bitgapps/sdk_v25.log";
  LINKER="/cache/bitgapps/lib-symlink.log";
  PARTITION="/cache/bitgapps/vendor.log";
  CTS_PATCH="/cache/bitgapps/config-cts.log";
  SETUP_CONFIG="/cache/bitgapps/config-setupwizard.log";
  ADDON_CONFIG="/cache/bitgapps/config-addon.log";
  TARGET_SYSTEM="/cache/bitgapps/cts-system.log";
  TARGET_VENDOR="/cache/bitgapps/cts-vendor.log";
  bootlog_SAR="/cache/bitgapps/init-SAR.log";
  bootlog_AB="/cache/bitgapps/init-AB.log";
  bootlog_A="/cache/bitgapps/init-A.log";
  bootlog_SYS="/cache/bitgapps/init-SYS.log";
  OPTv28="/cache/bitgapps/gms_opt_v28.log";
  OPTv29="/cache/bitgapps/gms_opt_v29.log";
  # CTS defaults
  CTS_DEFAULT_SYSTEM_EXT_BUILD_FINGERPRINT="ro.system.build.fingerprint=";
  CTS_DEFAULT_SYSTEM_BUILD_FINGERPRINT="ro.build.fingerprint=";
  CTS_DEFAULT_SYSTEM_BUILD_SEC_PATCH="ro.build.version.security_patch=";
  CTS_DEFAULT_SYSTEM_BUILD_TYPE="ro.build.type=";
  CTS_DEFAULT_VENDOR_BUILD_FINGERPRINT="ro.vendor.build.fingerprint=";
  CTS_DEFAULT_VENDOR_BUILD_BOOTIMAGE="ro.bootimage.build.fingerprint=";
  CTS_DEFAULT_VENDOR_BUILD_SEC_PATCH="ro.vendor.build.security_patch=";
  # CTS patch
  CTS_SYSTEM_EXT_BUILD_FINGERPRINT="ro.system.build.fingerprint=google/coral/coral:10/QQ3A.200805.001/6578210:user/release-keys";
  CTS_SYSTEM_BUILD_FINGERPRINT="ro.build.fingerprint=google/coral/coral:10/QQ3A.200805.001/6578210:user/release-keys";
  CTS_SYSTEM_BUILD_SEC_PATCH="ro.build.version.security_patch=2020-08-05";
  CTS_SYSTEM_BUILD_TYPE="ro.build.type=user";
  CTS_VENDOR_BUILD_FINGERPRINT="ro.vendor.build.fingerprint=google/coral/coral:10/QQ3A.200805.001/6578210:user/release-keys";
  CTS_VENDOR_BUILD_BOOTIMAGE="ro.bootimage.build.fingerprint=google/coral/coral:10/QQ3A.200805.001/6578210:user/release-keys";
  CTS_VENDOR_BUILD_SEC_PATCH="ro.vendor.build.security_patch=2020-08-05";
}

# Set partition and boot slot property
on_partition_check() {
  system_as_root=`getprop ro.build.system_root_image`
  active_slot=`getprop ro.boot.slot_suffix`
  dynamic_partitions=`getprop ro.boot.dynamic_partitions`
}

# Set fstab for getting mount point
fstab() {
  filesystem="/etc/fstab";
  if [ -f "/etc/recovery.fstab" ]; then
    filesystem="/etc/recovery.fstab";
  fi;
}

# Set vendor mount point
vendor_mnt() {
  device_vendorpartition="false";
  if [ -d /vendor ] && [ -n "$(cat /etc/fstab | grep /vendor)" ]; then
    device_vendorpartition="true";
    VENDOR="/vendor";
  fi;
  if [ "$dynamic_partitions" == "true" ]; then
    device_vendorpartition="true";
    VENDOR="/vendor";
  fi;
}

# Detect A/B partition layout https://source.android.com/devices/tech/ota/ab_updates
# and system-as-root https://source.android.com/devices/bootloader/system-as-root
ab_partition() {
  device_abpartition="false";
  if [ "$system_as_root" == "true" ]; then
    if [ ! -z "$active_slot" ]; then
      device_abpartition="true";
    fi;
  fi;
}

# Detect dynamic partition layout https://source.android.com/devices/tech/ota/dynamic_partitions/implement
super_partition() {
  device_superpartition="false";
  if [ "$dynamic_partitions" == "true" ]; then
    device_superpartition="true";
    if [ ! -z "$active_slot" ]; then
      device_abpartition="true";
    fi;
  fi;
}

is_mounted() { mount | grep -q " $1 "; }

setup_mountpoint() {
  test -L $1 && mv -f $1 ${1}_link
  if [ ! -d $1 ]; then
    rm -f $1
    mkdir $1
  fi
}

mount_apex() {
  if [ "$device_superpartition" == "false" ]; then
    if [ -d /system_root/system ] && [ -n "$(cat /etc/fstab | grep /system_root)" ];
    then
      SYSTEM="/system_root/system";
    else
      SYSTEM="/system/system";
    fi;
  else
    test -d $ANDROID_ROOT="/system_root" && SYSTEM="/system_root/system" || SYSTEM="/system/system";
  fi;
  test -d $SYSTEM/apex && APEX="true" || APEX="false";
  if [ "$APEX" == "true" ]; then
    local apex dest loop minorx num
    setup_mountpoint /apex
    test -e /dev/block/loop1 && minorx=$(ls -l /dev/block/loop1 | awk '{ print $6 }') || minorx=1
    num=0
    for apex in $SYSTEM/apex/*; do
      dest=/apex/$(basename $apex .apex)
      test "$dest" == /apex/com.android.runtime.release && dest=/apex/com.android.runtime
      mkdir -p $dest
      case $apex in
        *.apex)
          unzip -qo $apex apex_payload.img -d /apex
          mv -f /apex/apex_payload.img $dest.img
          mount -t ext4 -o ro,noatime $dest.img $dest 2>/dev/null
          if [ $? != 0 ]; then
            while [ $num -lt 64 ]; do
              loop=/dev/block/loop$num
              (mknod $loop b 7 $((num * minorx))
              losetup $loop $dest.img) 2>/dev/null
              num=$((num + 1))
              losetup $loop | grep -q $dest.img && break
            done
            mount -t ext4 -o ro,loop,noatime $loop $dest
            if [ $? != 0 ]; then
              losetup -d $loop 2>/dev/null
            fi;
          fi;
        ;;
        *) mount -o bind $apex $dest;;
      esac
    done
    export ANDROID_RUNTIME_ROOT="/apex/com.android.runtime";
    export ANDROID_TZDATA_ROOT="/apex/com.android.tzdata";
    export BOOTCLASSPATH="/apex/com.android.runtime/javalib/core-oj.jar:/apex/com.android.runtime/javalib/core-libart.jar:/apex/com.android.runtime/javalib/okhttp.jar:/apex/com.android.runtime/javalib/bouncycastle.jar:/apex/com.android.runtime/javalib/apache-xml.jar:/system/framework/framework.jar:/system/framework/ext.jar:/system/framework/telephony-common.jar:/system/framework/voip-common.jar:/system/framework/ims-common.jar:/system/framework/android.test.base.jar:/apex/com.android.conscrypt/javalib/conscrypt.jar:/apex/com.android.media/javalib/updatable-media.jar";
  fi;
}

umount_apex() {
  test -d /apex || return 1
  local dest loop
  for dest in $(find /apex -type d -mindepth 1 -maxdepth 1); do
    if [ -f $dest.img ]; then
      loop=$(mount | grep $dest | cut -d" " -f1)
    fi
    (umount -l $dest
    losetup -d $loop) 2>/dev/null
  done
  rm -rf /apex 2>/dev/null
  unset ANDROID_RUNTIME_ROOT ANDROID_TZDATA_ROOT BOOTCLASSPATH
}

early_umount() {
  umount_apex;
  umount /data 2>/dev/null;
  if [ -d /system ] && [ -n "$(cat /etc/fstab | grep /system)" ]; then
    umount /system 2>/dev/null;
  fi;
  if [ -d /system_root ] && [ -n "$(cat /etc/fstab | grep /system_root)" ]; then
    umount /system_root 2>/dev/null;
  fi;
  umount /vendor 2>/dev/null;
  umount /product 2>/dev/null;
  # For devices with dynamic partitions
  umount $ANDROID_ROOT 2>/dev/null;
}

# Mount partitions
mount_all() {
  vendor_mnt;
  mount -o bind /dev/urandom /dev/random
  if ! is_mounted /data; then
    mount /data
  fi;
  mount -o ro -t auto /cache 2>/dev/null;
  mount -o rw,remount -t auto /cache
  mount -o ro -t auto /persist 2>/dev/null;
  if [ "$dynamic_partitions" == "true" ]; then
    test -d $ANDROID_ROOT="/system_root" && ANDROID_ROOT="/system_root" || ANDROID_ROOT="/system";
    if [ "$device_abpartition" == "true" ]; then
      for block in system product vendor; do
        for slot in "" _a _b; do
          blockdev --setrw /dev/block/mapper/$block$slot 2>/dev/null;
        done
      done
      local slot=$(getprop ro.boot.slot_suffix 2>/dev/null)
      mount -o ro -t auto /dev/block/mapper/system$slot $ANDROID_ROOT 2>/dev/null;
      mount -o rw,remount -t auto /dev/block/mapper/system$slot $ANDROID_ROOT
      if [ "$device_vendorpartition" == "true" ]; then
        mount -o ro -t auto /dev/block/mapper/vendor$slot $VENDOR 2>/dev/null;
        mount -o rw,remount -t auto /dev/block/mapper/vendor$slot $VENDOR
      fi;
      mount -o ro -t auto /dev/block/mapper/product$slot /product 2>/dev/null;
      mount -o rw,remount -t auto /dev/block/mapper/product$slot /product
    else
      for block in system product vendor; do
        blockdev --setrw /dev/block/mapper/$block 2>/dev/null
      done
      mount -o ro -t auto /dev/block/mapper/system $ANDROID_ROOT 2>/dev/null;
      mount -o rw,remount -t auto /dev/block/mapper/system $ANDROID_ROOT
      if [ "$device_vendorpartition" == "true" ]; then
        mount -o ro -t auto /dev/block/mapper/vendor $VENDOR 2>/dev/null;
        mount -o rw,remount -t auto /dev/block/mapper/vendor $VENDOR
      fi;
      mount -o ro -t auto /dev/block/mapper/product /product 2>/dev/null;
      mount -o rw,remount -t auto /dev/block/mapper/product /product
    fi;
  else
    if [ -d /system_root ] && [ -n "$(cat /etc/fstab | grep /system_root)" ]; then
      ANDROID_ROOT="/system_root";
    else
      ANDROID_ROOT="/system";
    fi;
    mount -o ro -t auto $ANDROID_ROOT 2>/dev/null;
    mount -o rw,remount -t auto $ANDROID_ROOT
    if [ "$device_vendorpartition" == "true" ]; then
      mount -o ro -t auto $VENDOR 2>/dev/null;
      mount -o rw,remount -t auto $VENDOR
    fi;
    if [ -d /product ] && [ -n "$(cat /etc/fstab | grep /product)" ]; then
      mount -o ro -t auto /product 2>/dev/null;
      mount -o rw,remount -t auto /product
    fi;
    if [ "$system_as_root" == "true" ]; then
      if [ "$device_abpartition" == "true" ]; then
        local slot=$(getprop ro.boot.slot_suffix 2>/dev/null)
        umount $ANDROID_ROOT
        umount $VENDOR
        if [ "$ANDROID_ROOT" == "/system_root" ] && [ -n "$(cat /etc/fstab | grep /system_root)" ]; then
          mount -o ro -t auto /dev/block/bootdevice/by-name/system$slot /system_root 2>/dev/null;
          mount -o rw,remount -t auto /dev/block/bootdevice/by-name/system$slot /system_root
        fi;
        if [ "$ANDROID_ROOT" == "/system" ] && [ -n "$(cat /etc/fstab | grep /system_root)" ]; then
          mount -o ro -t auto /dev/block/bootdevice/by-name/system$slot /system_root 2>/dev/null;
          mount -o rw,remount -t auto /dev/block/bootdevice/by-name/system$slot /system_root
        fi;
        if [ "$ANDROID_ROOT" == "/system" ] && [ -n "$(cat /etc/fstab | grep /system)" ]; then
          mount -o ro -t auto /dev/block/bootdevice/by-name/system$slot /system 2>/dev/null;
          mount -o rw,remount -t auto /dev/block/bootdevice/by-name/system$slot /system
        fi;
        if [ "$device_vendorpartition" = "true" ]; then
          mount -o ro -t auto /dev/block/bootdevice/by-name/vendor$slot $VENDOR 2>/dev/null;
          mount -o rw,remount -t auto /dev/block/bootdevice/by-name/vendor$slot $VENDOR
        fi;
        if [ -d /product ] && [ -n "$(cat /etc/fstab | grep /product)" ]; then
          mount -o ro -t auto /dev/block/bootdevice/by-name/product /product 2>/dev/null;
          mount -o rw,remount -t auto /dev/block/bootdevice/by-name/product /product
        fi;
      fi;
    fi;
  fi;
  mount_apex;
}

# Set installation layout
system_layout() {
  if [ "$dynamic_partitions" == "true" ]; then
    SYSTEM="$ANDROID_ROOT/system";
  else
    if [ -f /system_root/system/build.prop ] && [ -n "$(cat /etc/fstab | grep /system_root)" ]; then
      SYSTEM="/system_root/system";
    elif [ -f /system/system/build.prop ] && [ -n "$(cat /etc/fstab | grep /system)" ]; then
      SYSTEM="/system/system";
    elif [ "$device_abpartition" == "true" ]; then
      SYSTEM="/system/system";
    elif [ "$device_abpartition" == "true" ] && [ -n "$(cat /etc/fstab | grep /system_root)" ]; then
      SYSTEM="/system_root/system";
    elif [ "$device_abpartition" == "true" ] && [ -n "$(cat /etc/fstab | grep /system)" ]; then
      SYSTEM="/system/system";
    elif [ -f /system/build.prop ] && [ -n "$(cat /etc/fstab | grep /system_root)" ]; then
      SYSTEM="/system";
    else
      SYSTEM="/system";
    fi;
  fi;
}

boot_SAR() {
  if [ -f "/system_root/init.rc" ]; then
    sed -i '/init.${ro.zygote}.rc/a\\import /init.bootlog.rc' /system_root/init.rc
    cp -f $TMP/init.bootlog.rc /system_root/init.bootlog.rc
    chmod 0750 /system_root/init.bootlog.rc
    chcon -h u:object_r:rootfs:s0 "/system_root/init.bootlog.rc";
  else
    echo "ERROR: Unable to find kernel init" >> $bootlog_SAR;
  fi;
}

boot_AB() {
  if [ -f "/system/init.rc" ]; then
    sed -i '/init.${ro.zygote}.rc/a\\import /init.bootlog.rc' /system/init.rc
    cp -f $TMP/init.bootlog.rc /system/init.bootlog.rc
    chmod 0750 /system/init.bootlog.rc
    chcon -h u:object_r:rootfs:s0 "/system/init.bootlog.rc";
  else
    echo "ERROR: Unable to find kernel init" >> $bootlog_AB;
  fi;
}

boot_A() {
  if [ -f "/init.rc" ] && [ -n "$(cat /init.rc | grep ro.zygote)" ]; then
    sed -i '/init.${ro.zygote}.rc/a\\import /init.bootlog.rc' /init.rc
    cp -f $TMP/init.bootlog.rc /init.bootlog.rc
    chmod 0750 /init.bootlog.rc
    chcon -h u:object_r:rootfs:s0 "/init.bootlog.rc";
  else
    echo "ERROR: Unable to find kernel init" >> $bootlog_A;
  fi;
}

boot_SYS() {
  INIT="/system/system/etc/init/hw/init.rc"
  if [ -f $INIT ] && [ -n "$(cat $INIT | grep ro.zygote)" ]; then
    sed -i '/init.${ro.zygote}.rc/a\\import /system/etc/init/hw/init.bootlog.rc' $INIT
    cp -f $TMP/init.bootlog.rc /system/system/etc/init/hw/init.bootlog.rc
    chmod 0750 /system/system/etc/init/hw/init.bootlog.rc
    chcon -h u:object_r:system_file:s0 "/system/system/etc/init/hw/init.bootlog.rc";
  else
    echo "ERROR: Unable to find kernel init" >> $bootlog_SYS;
  fi;
}

# Bind mountpoint /system to /system_root if we have system-as-root
on_AB() {
  if [ -f /system/init.rc ]; then
    system_as_root="true";
    [ -L /system_root ] && rm -f /system_root
    mkdir /system_root 2>/dev/null;
    mount --move /system /system_root
    mount -o bind /system_root/system /system
  else
    grep ' / ' /proc/mounts | grep -qv 'rootfs' || grep -q ' /system_root ' /proc/mounts \
    && system_as_root="true" || system_as_root="false";
  fi;
}

# Print mount status
mount_stat() {
  ui_print "Checking Mount status";
  if [ -f "$SYSTEM/build.prop" ]; then
    ui_print "Mounted";
    ui_print " ";
  else
    ui_print " ";
    mount_abort "Mounting failed. Aborting...";
    ui_print " ";
  fi;
}

# Generate a separate log file on failed mounting
on_mount_failed() {
  rm -rf $INTERNAL/bitgapps_debug_failed_logs.tar.gz
  rm -rf /cache/bitgapps
  mkdir /cache/bitgapps
  cd /cache/bitgapps
  cp -f $TMP/recovery.log /cache/bitgapps/recovery.log 2>/dev/null;
  cp -f /etc/fstab /cache/bitgapps/fstab 2>/dev/null;
  cp -f /etc/recovery.fstab /cache/bitgapps/recovery.fstab 2>/dev/null;
  tar -cz -f "$TMP/bitgapps_debug_failed_logs.tar.gz" *
  cp -f $TMP/bitgapps_debug_failed_logs.tar.gz $INTERNAL/bitgapps_debug_failed_logs.tar.gz
  # Checkout log path
  cd /
}

# Generate a separate log file on abort
on_install_failed() {
  rm -rf $INTERNAL/bitgapps_debug_failed_logs.tar.gz
  rm -rf /cache/bitgapps
  mkdir /cache/bitgapps
  cd /cache/bitgapps
  cp -f $TMP/recovery.log /cache/bitgapps/recovery.log 2>/dev/null;
  cp -f /etc/fstab /cache/bitgapps/fstab 2>/dev/null;
  cp -f /etc/recovery.fstab /cache/bitgapps/recovery.fstab 2>/dev/null;
  cp -f $SYSTEM/build.prop /cache/bitgapps/system.prop 2>/dev/null;
  if [ "$device_vendorpartition" == "true" ]; then
    cp -f $VENDOR/build.prop /cache/bitgapps/vendor.prop 2>/dev/null;
  fi;
  if [ -f $SYSTEM/etc/prop.default ]; then
    cp -f $SYSTEM/etc/prop.default /cache/bitgapps/system.default 2>/dev/null;
  fi;
  cp -f $INTERNAL/addon-config.prop /cache/bitgapps/addon-config.prop 2>/dev/null;
  cp -f $INTERNAL/cts-config.prop /cache/bitgapps/cts-config.prop 2>/dev/null;
  cp -f $INTERNAL/setup-config.prop /cache/bitgapps/setup-config.prop 2>/dev/null;
  tar -cz -f "$TMP/bitgapps_debug_failed_logs.tar.gz" *
  cp -f $TMP/bitgapps_debug_failed_logs.tar.gz $INTERNAL/bitgapps_debug_failed_logs.tar.gz
  # Checkout log path
  cd /
}

# log
on_install_complete() {
  rm -rf $INTERNAL/bitgapps_debug_complete_logs.tar.gz
  cd /cache/bitgapps
  cp -f $TMP/recovery.log /cache/bitgapps/recovery.log 2>/dev/null;
  cp -f /etc/fstab /cache/bitgapps/fstab 2>/dev/null;
  cp -f /etc/recovery.fstab /cache/bitgapps/recovery.fstab 2>/dev/null;
  cp -f $SYSTEM/build.prop /cache/bitgapps/system.prop 2>/dev/null;
  if [ "$device_vendorpartition" == "true" ]; then
    cp -f $VENDOR/build.prop /cache/bitgapps/vendor.prop 2>/dev/null;
  fi;
  if [ -f $SYSTEM/etc/prop.default ]; then
    cp -f $SYSTEM/etc/prop.default /cache/bitgapps/system.default 2>/dev/null;
  fi;
  cp -f $INTERNAL/addon-config.prop /cache/bitgapps/addon-config.prop 2>/dev/null;
  cp -f $INTERNAL/cts-config.prop /cache/bitgapps/cts-config.prop 2>/dev/null;
  cp -f $INTERNAL/setup-config.prop /cache/bitgapps/setup-config.prop 2>/dev/null;
  tar -cz -f "$TMP/bitgapps_debug_complete_logs.tar.gz" *
  cp -f $TMP/bitgapps_debug_complete_logs.tar.gz $INTERNAL/bitgapps_debug_complete_logs.tar.gz
  # Checkout log path
  cd /
}

unmount_all() {
  ui_print " ";
  umount_apex;
  if [ "$device_abpartition" == "true" ]; then
    mount -o ro $ANDROID_ROOT
  else
    umount $ANDROID_ROOT
  fi;
  if [ "$device_vendorpartition" == "true" ]; then
    if [ "$device_abpartition" == "true" ]; then
      mount -o ro $VENDOR
    else
      umount $VENDOR
    fi;
  fi;
  umount /product
  umount /persist
  umount /dev/random
}

cleanup() {
  rm -rf $TMP/addon.sh
  rm -rf $TMP/bin
  rm -rf $TMP/bitgapps_debug_complete_logs.tar.gz
  rm -rf $TMP/bitgapps_debug_failed_logs.tar.gz
  rm -rf $TMP/busybox-arm
  rm -rf $TMP/bb
  rm -rf $TMP/curl
  rm -rf $TMP/data.prop
  rm -rf $TMP/g.prop
  rm -rf $TMP/init.bootlog.rc
  rm -rf $TMP/installer.sh
  rm -rf $TMP/out
  rm -rf $TMP/pm.sh
  rm -rf $TMP/restore
  rm -rf $TMP/sqlite3
  rm -rf $TMP/unzip
  rm -rf $TMP/updater
  rm -rf $TMP/zip
  rm -rf $TMP/zipalign
}

clean_logs() {
  rm -rf /cache/bitgapps
}

on_installed() {
  on_install_complete;
  unmount_all;
  clean_logs;
  cleanup;
  recovery_cleanup;
}

mount_abort() {
  ui_print "$*";
  on_mount_failed;
  unmount_all;
  clean_logs;
  cleanup;
  recovery_cleanup;
  exit 1;
}

on_abort() {
  ui_print "$*";
  on_install_failed;
  unmount_all;
  clean_logs;
  cleanup;
  recovery_cleanup;
  exit 1;
}

# Database optimization using sqlite tool
sqlite_opt() {
  for i in `find /d* -iname "*.db" 2>/dev/null;`; do
    # Running VACUUM
    $SQLITE_TOOL $i 'VACUUM;';
    resVac=$?
    if [ $resVac == 0 ]; then
      resVac="SUCCESS";
    else
      resVac="ERRCODE-$resVac";
    fi;
    # Running INDEX
    $SQLITE_TOOL $i 'REINDEX;';
    resIndex=$?
    if [ $resIndex == 0 ]; then
      resIndex="SUCCESS";
    else
      resIndex="ERRCODE-$resIndex";
    fi;
    echo "Database $i:  VACUUM=$resVac  REINDEX=$resIndex" >> "$SQLITE_LOG";
  done
}

profile() {
  BUILD_PROPFILE="$SYSTEM/build.prop";
  SETUP_PROPFILE="$INTERNAL/setup-config.prop";
  CTS_PROPFILE="$INTERNAL/cts-config.prop";
  ADDON_PROPFILE="$INTERNAL/addon-config.prop";
  DATA_PROPFILE="$SYSTEM/etc/data.prop";
}

get_file_prop() {
  grep -m1 "^$2=" "$1" | cut -d= -f2
}

get_prop() {
  #check known .prop files using get_file_prop
  for f in $BUILD_PROPFILE $SETUP_PROPFILE $CTS_PROPFILE $ADDON_PROPFILE $DATA_PROPFILE; do
    if [ -e "$f" ]; then
      prop="$(get_file_prop "$f" "$1")"
      if [ -n "$prop" ]; then
        break #if an entry has been found, break out of the loop
      fi;
    fi;
  done
  #if prop is still empty; try to use recovery's built-in getprop method; otherwise output current result
  if [ -z "$prop" ]; then
    getprop "$1" | cut -c1-
  else
    printf "$prop"
  fi;
}

# Set target property in the global environment
on_target() {
  supported_target="true";
}

# Set setupwizard check property
on_setup_check() {
  supported_setup_config="$(get_prop "ro.config.setupwizard")";
}

# Set cts check property
on_cts_check() {
  supported_cts_config="$(get_prop "ro.config.cts")";
}

# Set addon check property
on_addon_check() {
  supported_calculator_config="$(get_prop "ro.config.calculator")";
  supported_calendar_config="$(get_prop "ro.config.calendar")";
  supported_contacts_config="$(get_prop "ro.config.contacts")";
  supported_deskclock_config="$(get_prop "ro.config.deskclock")";
  supported_dialer_config="$(get_prop "ro.config.dialer")";
  supported_markup_config="$(get_prop "ro.config.markup")";
  supported_messages_config="$(get_prop "ro.config.messages")";
  supported_photos_config="$(get_prop "ro.config.photos")";
  supported_soundpicker_config="$(get_prop "ro.config.soundpicker")";
  supported_assistant_config="$(get_prop "ro.config.assistant")";
  supported_wellbeing_config="$(get_prop "ro.config.wellbeing")";
}

# Set privileged app Whitelist property
on_whitelist_check() {
  android_flag="$(get_prop "ro.control_privapp_permissions")";
  supported_flag_enforce="enforce";
  supported_flag_disable="disable";
  supported_flag_log="log";
  PROPFLAG="ro.control_privapp_permissions";
}

# Set version check property
on_version_check() {
  if [ "$ZIPTYPE" == "addon" ]; then
    android_sdk="$(get_prop "ro.build.version.sdk")";
  else
    if [ "$TARGET_ANDROID_SDK" == "29" ]; then
      android_sdk="$(get_prop "ro.build.version.sdk")";
      supported_sdk="29";
      android_version="$(get_prop "ro.build.version.release")";
      supported_version="10";
    fi;
    if [ "$TARGET_ANDROID_SDK" == "28" ]; then
      android_sdk="$(get_prop "ro.build.version.sdk")";
      supported_sdk="28";
      android_version="$(get_prop "ro.build.version.release")";
      supported_version="9";
    fi;
    if [ "$TARGET_ANDROID_SDK" == "27" ]; then
      android_sdk="$(get_prop "ro.build.version.sdk")";
      supported_sdk="27";
      android_version="$(get_prop "ro.build.version.release")";
      supported_version="8.1.0";
    fi;
    if [ "$TARGET_ANDROID_SDK" == "25" ]; then
      android_sdk="$(get_prop "ro.build.version.sdk")";
      supported_sdk="25";
      android_version="$(get_prop "ro.build.version.release")";
      supported_version="7.1.2";
    fi;
  fi;
}

# Set product check property
on_product_check() {
  android_product="$(get_prop "ro.product.system.brand")";
  supported_product="samsung";
}

# Set product check property
on_pixel_check() {
  android_product="$(get_prop "ro.product.system.brand")";
  supported_product="google";
}

# Set platform check property
on_platform_check() {
  # Obsolete build property in use
  device_architecture="$(get_prop "ro.product.cpu.abi")";
}

# Set supported Android SDK Version
on_sdk() {
  supported_sdk_v29="29";
  supported_sdk_v28="28";
  supported_sdk_v27="27";
  supported_sdk_v25="25";
}

# Set supported Android Platform
on_platform() {
  ANDROID_PLATFORM_ARM32="armeabi-v7a";
  ANDROID_PLATFORM_ARM64="arm64-v8a";
}

build_platform() {
  if [ "$TARGET_ANDROID_ARCH" == "ARM" ]; then
    ANDROID_PLATFORM="$ANDROID_PLATFORM_ARM32"
  fi;
  if [ "$TARGET_ANDROID_ARCH" == "ARM64" ]; then
    ANDROID_PLATFORM="$ANDROID_PLATFORM_ARM64"
  fi;
}

# Set system data check property
on_data_check() {
  android_data="$(get_prop "ro.build.system_data")";
}

# Android SDK
check_sdk() {
  ui_print "Checking Android SDK version";
  if [ "$android_sdk" == "$supported_sdk" ]; then
    ui_print "$android_sdk";
    ui_print " ";
  else
    ui_print " ";
    on_abort "Unsupported Android SDK version. Aborting...";
    ui_print " ";
  fi;
}

# Android Version
check_version() {
  ui_print "Checking Android version";
  if [ "$android_version" == "$supported_version" ]; then
    ui_print "$android_version";
    ui_print " ";
  else
    ui_print " ";
    on_abort "Unsupported Android version. Aborting...";
    ui_print " ";
  fi;
}

# Android Platform
check_platform() {
  ui_print "Checking Android platform";
  for targetarch in $ANDROID_PLATFORM; do
    if [ "$device_architecture" == "$targetarch" ]; then
      ui_print "$device_architecture";
      ui_print " ";
    else
      ui_print " ";
      on_abort "Unsupported Android platform. Aborting...";
      ui_print " ";
    fi;
  done
}

# Delete listed packages permissions
clean_inst() {
  SYSTEM_DATA="false";
  # Check if system is already booted with GApps installed
  if [ "$android_data" == "$supported_target" ]; then
    SYSTEM_DATA="true";
  fi;
  if [ "$SYSTEM_DATA" == "false" ]; then
    # Did this 6.0+ system already boot and generated runtime permissions
    if [ -e /data/system/users/0/runtime-permissions.xml ]; then
      # Check if permissions were granted to Google Playstore, this permissions should always be set in the file if GApps were installed before
      if ! grep -q "com.android.vending" /data/system/users/*/runtime-permissions.xml; then
        # Purge the runtime permissions to prevent issues if flashing GApps for the first time on a dirty install
        rm -rf /data/system/users/*/runtime-permissions.xml
      fi;
    fi;
  fi;
}

on_gsf_check() {
  setsec="/data/system/users/0/settings_secure.xml"
  GSF="false";
  # Add support for Paranoid Android
  if [ -n "$(cat $SYSTEM/build.prop | grep ro.pa.device)" ]; then
    GSF="true";
  fi;
  # Add support for PixelExperience
  if [ -n "$(cat $SYSTEM/build.prop | grep org.pixelexperience.version)" ]; then
    GSF="true";
  fi;
  # Add support for EvolutionX
  if [ -n "$(cat $SYSTEM/build.prop | grep org.evolution.device)" ]; then
    GSF="true";
  fi;
  # Set target for AOSP packages installation
  if [ "$GSF" == "true" ]; then
    AOSP_PKG_INSTALL="true";
  fi;
  # Prevent installation of AOSP packages in SDK27 and SDK25
  if [ "$android_sdk" == "$supported_sdk_v27" ]; then
    AOSP_PKG_INSTALL="false";
  fi;
  if [ "$android_sdk" == "$supported_sdk_v25" ]; then
    AOSP_PKG_INSTALL="false";
  fi;
  # Check settings default XML file
  # Prevent merge conflicts on dirty install for ROM with gapps
  if [ -f "$setsec" ]; then
    SKIP_DEFAULT_CHECK="true";
  else
    SKIP_DEFAULT_CHECK="false";
  fi;
}

set_aosp_default() {
  if [ "$AOSP_PKG_INSTALL" == "true" ]; then
    # set AOSP Dialer as default; based on the work of osm0sis @ xda-developers
    setver="122"  # lowest version in MM, tagged at 6.0.0
    setsec="/data/system/users/0/settings_secure.xml"
    if [ "$SKIP_DEFAULT_CHECK" == "false" ]; then
      if [ ! -d "/data/system/users/0" ]; then
        install -d "/data/system/users/0"
        chown -R 1000:1000 "/data/system"
        chmod -R 775 "/data/system"
        chmod 700 "/data/system/users/0"
      fi;
      { echo -e "<?xml version='1.0' encoding='UTF-8' standalone='yes' ?>\r"
      echo -e '<settings version="'$setver'">\r'
      echo -e '  <setting id="1" name="dialer_default_application" value="com.android.dialer" package="android" defaultValue="com.android.dialer" defaultSysSet="true" />\r'
      echo -e '</settings>'; } > "$setsec"
    fi;
    chown 1000:1000 "$setsec"
    chmod 600 "$setsec"
  fi;
}

# Set pathmap
product_pathmap() {
  if [ "$android_sdk" == "$supported_sdk_v29" ]; then
    SYSTEM_ADDOND="$SYSTEM/product/addon.d";
    SYSTEM_APP="$SYSTEM/product/app";
    SYSTEM_PRIV_APP="$SYSTEM/product/priv-app";
    SYSTEM_ETC_CONFIG="$SYSTEM/product/etc/sysconfig";
    SYSTEM_ETC_DEFAULT="$SYSTEM/product/etc/default-permissions";
    SYSTEM_ETC_PERM="$SYSTEM/product/etc/permissions";
    SYSTEM_ETC_PREF="$SYSTEM/product/etc/preferred-apps";
    SYSTEM_FRAMEWORK="$SYSTEM/product/framework";
    SYSTEM_LIB="$SYSTEM/product/lib";
    SYSTEM_LIB64="$SYSTEM/product/lib64";
    mkdir $SYSTEM_ADDOND 2>/dev/null;
    mkdir $SYSTEM_ETC_CONFIG 2>/dev/null;
    mkdir $SYSTEM_ETC_DEFAULT 2>/dev/null;
    mkdir $SYSTEM_ETC_PREF 2>/dev/null;
    chmod 0755 $SYSTEM_ADDOND 2>/dev/null;
    chmod 0755 $SYSTEM_ETC_CONFIG 2>/dev/null;
    chmod 0755 $SYSTEM_ETC_DEFAULT 2>/dev/null;
    chmod 0755 $SYSTEM_ETC_PREF 2>/dev/null;
    chcon -h u:object_r:system_file:s0 $SYSTEM_ADDOND 2>/dev/null;
    chcon -h u:object_r:system_file:s0 $SYSTEM_ETC_CONFIG 2>/dev/null;
    chcon -h u:object_r:system_file:s0 $SYSTEM_ETC_DEFAULT 2>/dev/null;
    chcon -h u:object_r:system_file:s0 $SYSTEM_ETC_PREF 2>/dev/null;
  fi;
}

tmp_pathmap() {
  if [ "$android_sdk" == "$supported_sdk_v29" ]; then
    SYSTEM_ADDOND="$SYSTEM/addon.d";
    SYSTEM_APP="$SYSTEM/app";
    SYSTEM_PRIV_APP="$SYSTEM/priv-app";
    SYSTEM_ETC_CONFIG="$SYSTEM/etc/sysconfig";
    SYSTEM_ETC_DEFAULT="$SYSTEM/etc/default-permissions";
    SYSTEM_ETC_PERM="$SYSTEM/etc/permissions";
    SYSTEM_ETC_PREF="$SYSTEM/etc/preferred-apps";
    SYSTEM_FRAMEWORK="$SYSTEM/framework";
    SYSTEM_LIB="$SYSTEM/lib";
    SYSTEM_LIB64="$SYSTEM/lib64";
  fi;
}

system_pathmap() {
  if [ "$android_sdk" == "$supported_sdk_v28" ] || [ "$android_sdk" == "$supported_sdk_v27" ] || [ "$android_sdk" == "$supported_sdk_v25" ];
  then
    SYSTEM_ADDOND="$SYSTEM/addon.d";
    SYSTEM_APP="$SYSTEM/app";
    SYSTEM_PRIV_APP="$SYSTEM/priv-app";
    SYSTEM_ETC_CONFIG="$SYSTEM/etc/sysconfig";
    SYSTEM_ETC_DEFAULT="$SYSTEM/etc/default-permissions";
    SYSTEM_ETC_PERM="$SYSTEM/etc/permissions";
    SYSTEM_ETC_PREF="$SYSTEM/etc/preferred-apps";
    SYSTEM_FRAMEWORK="$SYSTEM/framework";
    SYSTEM_LIB="$SYSTEM/lib";
    SYSTEM_LIB64="$SYSTEM/lib64";
    mkdir $SYSTEM_ETC_DEFAULT 2>/dev/null;
    mkdir $SYSTEM_ETC_PREF 2>/dev/null;
    chmod 0755 $SYSTEM_ETC_DEFAULT 2>/dev/null;
    chmod 0755 $SYSTEM_ETC_PREF 2>/dev/null;
    chcon -h u:object_r:system_file:s0 $SYSTEM_ETC_DEFAULT 2>/dev/null;
    chcon -h u:object_r:system_file:s0 $SYSTEM_ETC_PREF 2>/dev/null;
  fi;
}
# end pathmap

# Create temporary log directory
logd() {
  mkdir /cache/bitgapps
  chmod 0755 /cache/bitgapps
}

# Create installation components
mk_component() {
  echo "-----------------------------------" >> $LOG;
  echo " --- BiTGApps Installation Log --- " >> $LOG;
  echo "             Start at              " >> $LOG;
  echo "        $( date +"%m-%d-%Y %H:%M:%S" )" >> $LOG;
  echo "-----------------------------------" >> $LOG;
  echo " " >> $LOG;
  echo "-----------------------------------" >> $LOG;
  if [ -d /cache/bitgapps ]; then
    echo "- Log directory found in :" /cache >> $LOG;
  else
    echo "- Log directory not found in :" /cache >> $LOG;
  fi;
  echo "-----------------------------------" >> $LOG;
  if [ -d "$UNZIP_DIR" ]; then
    echo "- Unzip directory found in :" $TMP >> $LOG;
    echo "- Creating components in :" $TMP >> $LOG;
    mkdir $UNZIP_DIR/tmp_addon
    mkdir $UNZIP_DIR/tmp_sys
    mkdir $UNZIP_DIR/tmp_sys_root
    mkdir $UNZIP_DIR/tmp_sys_aosp
    mkdir $UNZIP_DIR/tmp_priv
    mkdir $UNZIP_DIR/tmp_priv_root
    mkdir $UNZIP_DIR/tmp_priv_setup
    mkdir $UNZIP_DIR/tmp_priv_aosp
    mkdir $UNZIP_DIR/tmp_lib
    mkdir $UNZIP_DIR/tmp_lib64
    mkdir $UNZIP_DIR/tmp_framework
    mkdir $UNZIP_DIR/tmp_config
    mkdir $UNZIP_DIR/tmp_default
    mkdir $UNZIP_DIR/tmp_perm
    mkdir $UNZIP_DIR/tmp_perm_aosp
    mkdir $UNZIP_DIR/tmp_pref
    mkdir $UNZIP_DIR/tmp_perm_root
    chmod 0755 $UNZIP_DIR
    chmod 0755 $UNZIP_DIR/tmp_addon
    chmod 0755 $UNZIP_DIR/tmp_sys
    chmod 0755 $UNZIP_DIR/tmp_sys_root
    chmod 0755 $UNZIP_DIR/tmp_sys_aosp
    chmod 0755 $UNZIP_DIR/tmp_priv
    chmod 0755 $UNZIP_DIR/tmp_priv_root
    chmod 0755 $UNZIP_DIR/tmp_priv_setup
    chmod 0755 $UNZIP_DIR/tmp_priv_aosp
    chmod 0755 $UNZIP_DIR/tmp_lib
    chmod 0755 $UNZIP_DIR/tmp_lib64
    chmod 0755 $UNZIP_DIR/tmp_framework
    chmod 0755 $UNZIP_DIR/tmp_config
    chmod 0755 $UNZIP_DIR/tmp_default
    chmod 0755 $UNZIP_DIR/tmp_perm
    chmod 0755 $UNZIP_DIR/tmp_perm_aosp
    chmod 0755 $UNZIP_DIR/tmp_pref
    chmod 0755 $UNZIP_DIR/tmp_perm_root
  else
    echo "- Unzip directory not found in :" $TMP >> $LOG;
  fi;
}

# Remove pre-installed packages shipped with ROM
pre_installed() {
  if [ "$GSF" == "true" ]; then
    rm -rf $SYSTEM/addon.d/30*
    rm -rf $SYSTEM/addon.d/69*
    rm -rf $SYSTEM/addon.d/70*
    rm -rf $SYSTEM/addon.d/71*
    rm -rf $SYSTEM/addon.d/74*
    rm -rf $SYSTEM/addon.d/75*
    rm -rf $SYSTEM/addon.d/78*
    rm -rf $SYSTEM/addon.d/90*
    rm -rf $SYSTEM/app/AndroidAuto*
    rm -rf $SYSTEM/app/arcore
    rm -rf $SYSTEM/app/Books*
    rm -rf $SYSTEM/app/CarHomeGoogle
    rm -rf $SYSTEM/app/CalculatorGoogle*
    rm -rf $SYSTEM/app/CalendarGoogle*
    rm -rf $SYSTEM/app/CarHomeGoogle
    rm -rf $SYSTEM/app/Chrome*
    rm -rf $SYSTEM/app/CloudPrint*
    rm -rf $SYSTEM/app/DevicePersonalizationServices
    rm -rf $SYSTEM/app/DMAgent
    rm -rf $SYSTEM/app/Drive
    rm -rf $SYSTEM/app/Duo
    rm -rf $SYSTEM/app/EditorsDocs
    rm -rf $SYSTEM/app/Editorssheets
    rm -rf $SYSTEM/app/EditorsSlides
    rm -rf $SYSTEM/app/ExchangeServices
    rm -rf $SYSTEM/app/FaceLock
    rm -rf $SYSTEM/app/Fitness*
    rm -rf $SYSTEM/app/GalleryGo*
    rm -rf $SYSTEM/app/Gcam*
    rm -rf $SYSTEM/app/GCam*
    rm -rf $SYSTEM/app/Gmail*
    rm -rf $SYSTEM/app/GoogleCamera*
    rm -rf $SYSTEM/app/GoogleCalendar*
    rm -rf $SYSTEM/app/GoogleCalendarSyncAdapter
    rm -rf $SYSTEM/app/GoogleContactsSyncAdapter
    rm -rf $SYSTEM/app/GoogleCloudPrint
    rm -rf $SYSTEM/app/GoogleEarth
    rm -rf $SYSTEM/app/GoogleExtshared
    rm -rf $SYSTEM/app/GooglePrintRecommendationService
    rm -rf $SYSTEM/app/GoogleGo*
    rm -rf $SYSTEM/app/GoogleHome*
    rm -rf $SYSTEM/app/GoogleHindiIME*
    rm -rf $SYSTEM/app/GoogleKeep*
    rm -rf $SYSTEM/app/GoogleJapaneseInput*
    rm -rf $SYSTEM/app/GoogleLoginService*
    rm -rf $SYSTEM/app/GoogleMusic*
    rm -rf $SYSTEM/app/GoogleNow*
    rm -rf $SYSTEM/app/GooglePhotos*
    rm -rf $SYSTEM/app/GooglePinyinIME*
    rm -rf $SYSTEM/app/GooglePlus
    rm -rf $SYSTEM/app/GoogleTTS*
    rm -rf $SYSTEM/app/GoogleVrCore*
    rm -rf $SYSTEM/app/GoogleZhuyinIME*
    rm -rf $SYSTEM/app/Hangouts
    rm -rf $SYSTEM/app/KoreanIME*
    rm -rf $SYSTEM/app/Maps
    rm -rf $SYSTEM/app/Markup*
    rm -rf $SYSTEM/app/Music2*
    rm -rf $SYSTEM/app/Newsstand
    rm -rf $SYSTEM/app/NexusWallpapers*
    rm -rf $SYSTEM/app/Ornament
    rm -rf $SYSTEM/app/Photos*
    rm -rf $SYSTEM/app/PlayAutoInstallConfig*
    rm -rf $SYSTEM/app/PlayGames*
    rm -rf $SYSTEM/app/PrebuiltExchange3Google
    rm -rf $SYSTEM/app/PrebuiltGmail
    rm -rf $SYSTEM/app/PrebuiltKeep
    rm -rf $SYSTEM/app/Street
    rm -rf $SYSTEM/app/Stickers*
    rm -rf $SYSTEM/app/TalkBack
    rm -rf $SYSTEM/app/talkBack
    rm -rf $SYSTEM/app/talkback
    rm -rf $SYSTEM/app/TranslatePrebuilt
    rm -rf $SYSTEM/app/Tycho
    rm -rf $SYSTEM/app/Videos
    rm -rf $SYSTEM/app/Wallet
    rm -rf $SYSTEM/app/WallpapersBReel*
    rm -rf $SYSTEM/app/YouTube
    rm -rf $SYSTEM/etc/default-permissions/default-permissions.xml
    rm -rf $SYSTEM/etc/default-permissions/opengapps-permissions.xml
    rm -rf $SYSTEM/etc/permissions/default-permissions.xml
    rm -rf $SYSTEM/etc/permissions/privapp-permissions-elgoog.xml
    rm -rf $SYSTEM/etc/permissions/privapp-permissions-google*
    rm -rf $SYSTEM/etc/permissions/com.google.android.camera*
    rm -rf $SYSTEM/etc/permissions/com.google.android.dialer*
    rm -rf $SYSTEM/etc/permissions/com.google.android.maps*
    rm -rf $SYSTEM/etc/permissions/split-permissions-google.xml
    rm -rf $SYSTEM/etc/preferred-apps/google.xml
    rm -rf $SYSTEM/etc/preferred-apps/google_build.xml
    rm -rf $SYSTEM/etc/sysconfig/pixel_2017_exclusive.xml
    rm -rf $SYSTEM/etc/sysconfig/pixel_experience_2017.xml
    rm -rf $SYSTEM/etc/sysconfig/gmsexpress.xml
    rm -rf $SYSTEM/etc/sysconfig/googledialergo-sysconfig.xml
    rm -rf $SYSTEM/etc/sysconfig/google-hiddenapi-package-whitelist.xml
    rm -rf $SYSTEM/etc/sysconfig/google.xml
    rm -rf $SYSTEM/etc/sysconfig/google_build.xml
    rm -rf $SYSTEM/etc/sysconfig/google_experience.xml
    rm -rf $SYSTEM/etc/sysconfig/google_exclusives_enable.xml
    rm -rf $SYSTEM/etc/sysconfig/go_experience.xml
    rm -rf $SYSTEM/etc/sysconfig/nga.xml
    rm -rf $SYSTEM/etc/sysconfig/nexus.xml
    rm -rf $SYSTEM/etc/sysconfig/pixel*
    rm -rf $SYSTEM/etc/sysconfig/turbo.xml
    rm -rf $SYSTEM/etc/sysconfig/wellbeing.xml
    rm -rf $SYSTEM/framework/com.google.android.camera*
    rm -rf $SYSTEM/framework/com.google.android.dialer*
    rm -rf $SYSTEM/framework/com.google.android.maps*
    rm -rf $SYSTEM/framework/oat/arm/com.google.android.camera*
    rm -rf $SYSTEM/framework/oat/arm/com.google.android.dialer*
    rm -rf $SYSTEM/framework/oat/arm/com.google.android.maps*
    rm -rf $SYSTEM/framework/oat/arm64/com.google.android.camera*
    rm -rf $SYSTEM/framework/oat/arm64/com.google.android.dialer*
    rm -rf $SYSTEM/framework/oat/arm64/com.google.android.maps*
    rm -rf $SYSTEM/lib/libaiai-annotators.so
    rm -rf $SYSTEM/lib/libcronet.70.0.3522.0.so
    rm -rf $SYSTEM/lib/libfilterpack_facedetect.so
    rm -rf $SYSTEM/lib/libfrsdk.so
    rm -rf $SYSTEM/lib/libgcam.so
    rm -rf $SYSTEM/lib/libgcam_swig_jni.so
    rm -rf $SYSTEM/lib/libocr.so
    rm -rf $SYSTEM/lib/libparticle-extractor_jni.so
    rm -rf $SYSTEM/lib64/libbarhopper.so
    rm -rf $SYSTEM/lib64/libfacenet.so
    rm -rf $SYSTEM/lib64/libfilterpack_facedetect.so
    rm -rf $SYSTEM/lib64/libfrsdk.so
    rm -rf $SYSTEM/lib64/libgcam.so
    rm -rf $SYSTEM/lib64/libgcam_swig_jni.so
    rm -rf $SYSTEM/lib64/libsketchology_native.so
    rm -rf $SYSTEM/overlay/PixelConfigOverlay*
    rm -rf $SYSTEM/priv-app/Aiai*
    rm -rf $SYSTEM/priv-app/AmbientSense*
    rm -rf $SYSTEM/priv-app/AndroidAuto*
    rm -rf $SYSTEM/priv-app/AndroidMigrate*
    rm -rf $SYSTEM/priv-app/AndroidPlatformServices
    rm -rf $SYSTEM/priv-app/CalendarGoogle*
    rm -rf $SYSTEM/priv-app/CalculatorGoogle*
    rm -rf $SYSTEM/priv-app/Camera*
    rm -rf $SYSTEM/priv-app/CarrierServices
    rm -rf $SYSTEM/priv-app/CarrierSetup
    rm -rf $SYSTEM/priv-app/ConfigUpdater
    rm -rf $SYSTEM/priv-app/DataTransferTool
    rm -rf $SYSTEM/priv-app/DeviceHealthServices
    rm -rf $SYSTEM/priv-app/DevicePersonalizationServices
    rm -rf $SYSTEM/priv-app/DigitalWellbeing*
    rm -rf $SYSTEM/priv-app/FaceLock
    rm -rf $SYSTEM/priv-app/Gcam*
    rm -rf $SYSTEM/priv-app/GCam*
    rm -rf $SYSTEM/priv-app/GCS
    rm -rf $SYSTEM/priv-app/GmsCore*
    rm -rf $SYSTEM/priv-app/GoogleCalculator*
    rm -rf $SYSTEM/priv-app/GoogleCalendar*
    rm -rf $SYSTEM/priv-app/GoogleCamera*
    rm -rf $SYSTEM/priv-app/GoogleBackupTransport
    rm -rf $SYSTEM/priv-app/GoogleExtservices
    rm -rf $SYSTEM/priv-app/GoogleExtServicesPrebuilt
    rm -rf $SYSTEM/priv-app/GoogleFeedback
    rm -rf $SYSTEM/priv-app/GoogleOneTimeInitializer
    rm -rf $SYSTEM/priv-app/GooglePartnerSetup
    rm -rf $SYSTEM/priv-app/GoogleRestore
    rm -rf $SYSTEM/priv-app/GoogleServicesFramework
    rm -rf $SYSTEM/priv-app/HotwordEnrollment*
    rm -rf $SYSTEM/priv-app/HotWordEnrollment*
    rm -rf $SYSTEM/priv-app/matchmaker*
    rm -rf $SYSTEM/priv-app/Matchmaker*
    rm -rf $SYSTEM/priv-app/Phonesky
    rm -rf $SYSTEM/priv-app/PixelLive*
    rm -rf $SYSTEM/priv-app/PrebuiltGmsCore*
    rm -rf $SYSTEM/priv-app/PixelSetupWizard*
    rm -rf $SYSTEM/priv-app/SetupWizard*
    rm -rf $SYSTEM/priv-app/Tag*
    rm -rf $SYSTEM/priv-app/Tips*
    rm -rf $SYSTEM/priv-app/Turbo*
    rm -rf $SYSTEM/priv-app/Velvet
    rm -rf $SYSTEM/priv-app/Wellbeing*
    rm -rf $SYSTEM/usr/srec/en-US
    rm -rf $SYSTEM/product/app/AndroidAuto*
    rm -rf $SYSTEM/product/app/arcore
    rm -rf $SYSTEM/product/app/Books*
    rm -rf $SYSTEM/product/app/CalculatorGoogle*
    rm -rf $SYSTEM/product/app/CalendarGoogle*
    rm -rf $SYSTEM/product/app/CarHomeGoogle
    rm -rf $SYSTEM/product/app/Chrome*
    rm -rf $SYSTEM/product/app/CloudPrint*
    rm -rf $SYSTEM/product/app/DMAgent
    rm -rf $SYSTEM/product/app/DevicePersonalizationServices
    rm -rf $SYSTEM/product/app/Drive
    rm -rf $SYSTEM/product/app/Duo
    rm -rf $SYSTEM/product/app/EditorsDocs
    rm -rf $SYSTEM/product/app/Editorssheets
    rm -rf $SYSTEM/product/app/EditorsSlides
    rm -rf $SYSTEM/product/app/ExchangeServices
    rm -rf $SYSTEM/product/app/FaceLock
    rm -rf $SYSTEM/product/app/Fitness*
    rm -rf $SYSTEM/product/app/GalleryGo*
    rm -rf $SYSTEM/product/app/Gcam*
    rm -rf $SYSTEM/product/app/GCam*
    rm -rf $SYSTEM/product/app/Gmail*
    rm -rf $SYSTEM/product/app/GoogleCamera*
    rm -rf $SYSTEM/product/app/GoogleCalendar*
    rm -rf $SYSTEM/product/app/GoogleContacts*
    rm -rf $SYSTEM/product/app/GoogleCloudPrint
    rm -rf $SYSTEM/product/app/GoogleEarth
    rm -rf $SYSTEM/product/app/GoogleExtshared
    rm -rf $SYSTEM/product/app/GoogleExtShared
    rm -rf $SYSTEM/product/app/GoogleGalleryGo
    rm -rf $SYSTEM/product/app/GoogleGo*
    rm -rf $SYSTEM/product/app/GoogleHome*
    rm -rf $SYSTEM/product/app/GoogleHindiIME*
    rm -rf $SYSTEM/product/app/GoogleKeep*
    rm -rf $SYSTEM/product/app/GoogleJapaneseInput*
    rm -rf $SYSTEM/product/app/GoogleLoginService*
    rm -rf $SYSTEM/product/app/GoogleMusic*
    rm -rf $SYSTEM/product/app/GoogleNow*
    rm -rf $SYSTEM/product/app/GooglePhotos*
    rm -rf $SYSTEM/product/app/GooglePinyinIME*
    rm -rf $SYSTEM/product/app/GooglePlus
    rm -rf $SYSTEM/product/app/GoogleTTS*
    rm -rf $SYSTEM/product/app/GoogleVrCore*
    rm -rf $SYSTEM/product/app/GoogleZhuyinIME*
    rm -rf $SYSTEM/product/app/Hangouts
    rm -rf $SYSTEM/product/app/KoreanIME*
    rm -rf $SYSTEM/product/app/LocationHistory*
    rm -rf $SYSTEM/product/app/Maps
    rm -rf $SYSTEM/product/app/Markup*
    rm -rf $SYSTEM/product/app/MicropaperPrebuilt
    rm -rf $SYSTEM/product/app/Music2*
    rm -rf $SYSTEM/product/app/Newsstand
    rm -rf $SYSTEM/product/app/NexusWallpapers*
    rm -rf $SYSTEM/product/app/Ornament
    rm -rf $SYSTEM/product/app/Photos*
    rm -rf $SYSTEM/product/app/PlayAutoInstallConfig*
    rm -rf $SYSTEM/product/app/PlayGames*
    rm -rf $SYSTEM/product/app/PrebuiltBugle
    rm -rf $SYSTEM/product/app/PrebuiltClockGoogle
    rm -rf $SYSTEM/product/app/PrebuiltDeskClockGoogle
    rm -rf $SYSTEM/product/app/PrebuiltExchange3Google
    rm -rf $SYSTEM/product/app/PrebuiltGmail
    rm -rf $SYSTEM/product/app/PrebuiltKeep
    rm -rf $SYSTEM/product/app/SoundAmplifierPrebuilt
    rm -rf $SYSTEM/product/app/Street
    rm -rf $SYSTEM/product/app/Stickers*
    rm -rf $SYSTEM/product/app/TalkBack
    rm -rf $SYSTEM/product/app/talkBack
    rm -rf $SYSTEM/product/app/talkback
    rm -rf $SYSTEM/product/app/TranslatePrebuilt
    rm -rf $SYSTEM/product/app/Tycho
    rm -rf $SYSTEM/product/app/Videos
    rm -rf $SYSTEM/product/app/Wallet
    rm -rf $SYSTEM/product/app/WallpapersBReel*
    rm -rf $SYSTEM/product/app/YouTube*
    rm -rf $SYSTEM/product/etc/default-permissions/default-permissions.xml
    rm -rf $SYSTEM/product/etc/default-permissions/opengapps-permissions.xml
    rm -rf $SYSTEM/product/etc/permissions/default-permissions.xml
    rm -rf $SYSTEM/product/etc/permissions/privapp-permissions-elgoog.xml
    rm -rf $SYSTEM/product/etc/permissions/privapp-permissions-google*
    rm -rf $SYSTEM/product/etc/permissions/com.google.android.camera*
    rm -rf $SYSTEM/product/etc/permissions/com.google.android.dialer*
    rm -rf $SYSTEM/product/etc/permissions/com.google.android.maps*
    rm -rf $SYSTEM/product/etc/permissions/split-permissions-google.xml
    rm -rf $SYSTEM/product/etc/preferred-apps/google.xml
    rm -rf $SYSTEM/product/etc/preferred-apps/google_build.xml
    rm -rf $SYSTEM/product/etc/sysconfig/pixel_2017_exclusive.xml
    rm -rf $SYSTEM/product/etc/sysconfig/pixel_experience_2017.xml
    rm -rf $SYSTEM/product/etc/sysconfig/gmsexpress.xml
    rm -rf $SYSTEM/product/etc/sysconfig/googledialergo-sysconfig.xml
    rm -rf $SYSTEM/product/etc/sysconfig/google-hiddenapi-package-whitelist.xml
    rm -rf $SYSTEM/product/etc/sysconfig/google.xml
    rm -rf $SYSTEM/product/etc/sysconfig/google_build.xml
    rm -rf $SYSTEM/product/etc/sysconfig/google_experience.xml
    rm -rf $SYSTEM/product/etc/sysconfig/google_exclusives_enable.xml
    rm -rf $SYSTEM/product/etc/sysconfig/go_experience.xml
    rm -rf $SYSTEM/product/etc/sysconfig/nexus.xml
    rm -rf $SYSTEM/product/etc/sysconfig/nga.xml
    rm -rf $SYSTEM/product/etc/sysconfig/pixel*
    rm -rf $SYSTEM/product/etc/sysconfig/turbo.xml
    rm -rf $SYSTEM/product/etc/sysconfig/wellbeing.xml
    rm -rf $SYSTEM/product/framework/com.google.android.camera*
    rm -rf $SYSTEM/product/framework/com.google.android.dialer*
    rm -rf $SYSTEM/product/framework/com.google.android.maps*
    rm -rf $SYSTEM/product/framework/oat/arm/com.google.android.camera*
    rm -rf $SYSTEM/product/framework/oat/arm/com.google.android.dialer*
    rm -rf $SYSTEM/product/framework/oat/arm/com.google.android.maps*
    rm -rf $SYSTEM/product/framework/oat/arm64/com.google.android.camera*
    rm -rf $SYSTEM/product/framework/oat/arm64/com.google.android.dialer*
    rm -rf $SYSTEM/product/framework/oat/arm64/com.google.android.maps*
    rm -rf $SYSTEM/product/lib/libaiai-annotators.so
    rm -rf $SYSTEM/product/lib/libcronet.70.0.3522.0.so
    rm -rf $SYSTEM/product/lib/libfilterpack_facedetect.so
    rm -rf $SYSTEM/product/lib/libfrsdk.so
    rm -rf $SYSTEM/product/lib/libgcam.so
    rm -rf $SYSTEM/product/lib/libgcam_swig_jni.so
    rm -rf $SYSTEM/product/lib/libocr.so
    rm -rf $SYSTEM/product/lib/libparticle-extractor_jni.so
    rm -rf $SYSTEM/product/lib64/libbarhopper.so
    rm -rf $SYSTEM/product/lib64/libfacenet.so
    rm -rf $SYSTEM/product/lib64/libfilterpack_facedetect.so
    rm -rf $SYSTEM/product/lib64/libfrsdk.so
    rm -rf $SYSTEM/product/lib64/libgcam.so
    rm -rf $SYSTEM/product/lib64/libgcam_swig_jni.so
    rm -rf $SYSTEM/product/lib64/libsketchology_native.so
    rm -rf $SYSTEM/product/overlay/GoogleConfigOverlay*
    rm -rf $SYSTEM/product/overlay/PixelConfigOverlay*
    rm -rf $SYSTEM/product/overlay/Gms*
    rm -rf $SYSTEM/product/priv-app/Aiai*
    rm -rf $SYSTEM/product/priv-app/AmbientSense*
    rm -rf $SYSTEM/product/priv-app/AndroidAuto*
    rm -rf $SYSTEM/product/priv-app/AndroidMigrate*
    rm -rf $SYSTEM/product/priv-app/AndroidPlatformServices
    rm -rf $SYSTEM/product/priv-app/CalendarGoogle*
    rm -rf $SYSTEM/product/priv-app/CalculatorGoogle*
    rm -rf $SYSTEM/product/priv-app/Camera*
    rm -rf $SYSTEM/product/priv-app/CarrierServices
    rm -rf $SYSTEM/product/priv-app/CarrierSetup
    rm -rf $SYSTEM/product/priv-app/ConfigUpdater
    rm -rf $SYSTEM/product/priv-app/ConnMetrics
    rm -rf $SYSTEM/product/priv-app/DataTransferTool
    rm -rf $SYSTEM/product/priv-app/DeviceHealthServices
    rm -rf $SYSTEM/product/priv-app/DevicePersonalizationServices
    rm -rf $SYSTEM/product/priv-app/DigitalWellbeing*
    rm -rf $SYSTEM/product/priv-app/FaceLock
    rm -rf $SYSTEM/product/priv-app/Gcam*
    rm -rf $SYSTEM/product/priv-app/GCam*
    rm -rf $SYSTEM/product/priv-app/GCS
    rm -rf $SYSTEM/product/priv-app/GmsCore*
    rm -rf $SYSTEM/product/priv-app/GoogleBackupTransport
    rm -rf $SYSTEM/product/priv-app/GoogleCalculator*
    rm -rf $SYSTEM/product/priv-app/GoogleCalendar*
    rm -rf $SYSTEM/product/priv-app/GoogleCamera*
    rm -rf $SYSTEM/product/priv-app/GoogleContacts*
    rm -rf $SYSTEM/product/priv-app/GoogleDialer
    rm -rf $SYSTEM/product/priv-app/GoogleExtservices
    rm -rf $SYSTEM/product/priv-app/GoogleExtServices
    rm -rf $SYSTEM/product/priv-app/GoogleFeedback
    rm -rf $SYSTEM/product/priv-app/GoogleOneTimeInitializer
    rm -rf $SYSTEM/product/priv-app/GooglePartnerSetup
    rm -rf $SYSTEM/product/priv-app/GoogleRestore
    rm -rf $SYSTEM/product/priv-app/GoogleServicesFramework
    rm -rf $SYSTEM/product/priv-app/HotwordEnrollment*
    rm -rf $SYSTEM/product/priv-app/HotWordEnrollment*
    rm -rf $SYSTEM/product/priv-app/MaestroPrebuilt
    rm -rf $SYSTEM/product/priv-app/matchmaker*
    rm -rf $SYSTEM/product/priv-app/Matchmaker*
    rm -rf $SYSTEM/product/priv-app/Phonesky
    rm -rf $SYSTEM/product/priv-app/PixelLive*
    rm -rf $SYSTEM/product/priv-app/PrebuiltGmsCore*
    rm -rf $SYSTEM/product/priv-app/PixelSetupWizard*
    rm -rf $SYSTEM/product/priv-app/RecorderPrebuilt
    rm -rf $SYSTEM/product/priv-app/SCONE
    rm -rf $SYSTEM/product/priv-app/Scribe*
    rm -rf $SYSTEM/product/priv-app/SetupWizard*
    rm -rf $SYSTEM/product/priv-app/Tag*
    rm -rf $SYSTEM/product/priv-app/Tips*
    rm -rf $SYSTEM/product/priv-app/Turbo*
    rm -rf $SYSTEM/product/priv-app/Velvet
    rm -rf $SYSTEM/product/priv-app/WallpaperPickerGoogleRelease
    rm -rf $SYSTEM/product/priv-app/Wellbeing*
    rm -rf $SYSTEM/product/usr/srec/en-US
    rm -rf $SYSTEM/app/Abstruct
    rm -rf $SYSTEM/app/BasicDreams
    rm -rf $SYSTEM/app/BlissPapers
    rm -rf $SYSTEM/app/BookmarkProvider
    rm -rf $SYSTEM/app/Browser*
    rm -rf $SYSTEM/app/Camera*
    rm -rf $SYSTEM/app/Chromium
    rm -rf $SYSTEM/app/ColtPapers
    rm -rf $SYSTEM/app/EasterEgg*
    rm -rf $SYSTEM/app/EggGame
    rm -rf $SYSTEM/app/Email*
    rm -rf $SYSTEM/app/ExactCalculator
    rm -rf $SYSTEM/app/Exchange2
    rm -rf $SYSTEM/app/Gallery*
    rm -rf $SYSTEM/app/GugelClock
    rm -rf $SYSTEM/app/HTMLViewer
    rm -rf $SYSTEM/app/Jelly
    rm -rf $SYSTEM/app/messaging
    rm -rf $SYSTEM/app/MiXplorer*
    rm -rf $SYSTEM/app/Music*
    rm -rf $SYSTEM/app/Partnerbookmark*
    rm -rf $SYSTEM/app/PartnerBookmark*
    rm -rf $SYSTEM/app/Phonograph
    rm -rf $SYSTEM/app/PhotoTable
    rm -rf $SYSTEM/app/RetroMusic*
    rm -rf $SYSTEM/app/VanillaMusic
    rm -rf $SYSTEM/app/Via*
    rm -rf $SYSTEM/app/QPGallery
    rm -rf $SYSTEM/app/QuickSearchBox
    rm -rf $SYSTEM/priv-app/AudioFX
    rm -rf $SYSTEM/priv-app/Camera*
    rm -rf $SYSTEM/priv-app/Eleven
    rm -rf $SYSTEM/priv-app/MatLog
    rm -rf $SYSTEM/priv-app/MusicFX
    rm -rf $SYSTEM/priv-app/OmniSwitch
    rm -rf $SYSTEM/priv-app/Snap*
    rm -rf $SYSTEM/priv-app/Tag*
    rm -rf $SYSTEM/priv-app/Via*
    rm -rf $SYSTEM/priv-app/VinylMusicPlayer
    rm -rf $SYSTEM/product/app/AboutBliss
    rm -rf $SYSTEM/product/app/BasicDreams
    rm -rf $SYSTEM/product/app/BlissStatistics
    rm -rf $SYSTEM/product/app/BookmarkProvider
    rm -rf $SYSTEM/product/app/Browser*
    rm -rf $SYSTEM/product/app/Calendar*
    rm -rf $SYSTEM/product/app/Camera*
    rm -rf $SYSTEM/product/app/Dashboard
    rm -rf $SYSTEM/product/app/DeskClock
    rm -rf $SYSTEM/product/app/EasterEgg*
    rm -rf $SYSTEM/product/app/Email*
    rm -rf $SYSTEM/product/app/EmergencyInfo
    rm -rf $SYSTEM/product/app/Etar
    rm -rf $SYSTEM/product/app/Gallery*
    rm -rf $SYSTEM/product/app/HTMLViewer
    rm -rf $SYSTEM/product/app/Jelly
    rm -rf $SYSTEM/product/app/Messaging
    rm -rf $SYSTEM/product/app/messaging
    rm -rf $SYSTEM/product/app/Music*
    rm -rf $SYSTEM/product/app/Partnerbookmark*
    rm -rf $SYSTEM/product/app/PartnerBookmark*
    rm -rf $SYSTEM/product/app/PhotoTable*
    rm -rf $SYSTEM/product/app/Recorder*
    rm -rf $SYSTEM/product/app/RetroMusic*
    rm -rf $SYSTEM/product/app/SimpleGallery
    rm -rf $SYSTEM/product/app/Via*
    rm -rf $SYSTEM/product/app/WallpaperZone
    rm -rf $SYSTEM/product/app/QPGallery
    rm -rf $SYSTEM/product/app/QuickSearchBox
    rm -rf $SYSTEM/product/overlay/ChromeOverlay
    rm -rf $SYSTEM/product/overlay/TelegramOverlay
    rm -rf $SYSTEM/product/overlay/WhatsAppOverlay
    rm -rf $SYSTEM/product/priv-app/AncientWallpaperZone
    rm -rf $SYSTEM/product/priv-app/Camera*
    rm -rf $SYSTEM/product/priv-app/Contacts
    rm -rf $SYSTEM/product/priv-app/crDroidMusic
    rm -rf $SYSTEM/product/priv-app/Dialer
    rm -rf $SYSTEM/product/priv-app/Eleven
    rm -rf $SYSTEM/product/priv-app/EmergencyInfo
    rm -rf $SYSTEM/product/priv-app/Gallery2
    rm -rf $SYSTEM/product/priv-app/MatLog
    rm -rf $SYSTEM/product/priv-app/MusicFX
    rm -rf $SYSTEM/product/priv-app/OmniSwitch
    rm -rf $SYSTEM/product/priv-app/Recorder*
    rm -rf $SYSTEM/product/priv-app/Snap*
    rm -rf $SYSTEM/product/priv-app/Tag*
    rm -rf $SYSTEM/product/priv-app/Via*
    rm -rf $SYSTEM/product/priv-app/VinylMusicPlayer
    rm -rf $SYSTEM/app/AppleNLP*
    rm -rf $SYSTEM/app/AuroraDroid
    rm -rf $SYSTEM/app/AuroraStore
    rm -rf $SYSTEM/app/DejaVu*
    rm -rf $SYSTEM/app/DroidGuard
    rm -rf $SYSTEM/app/LocalGSM*
    rm -rf $SYSTEM/app/LocalWiFi*
    rm -rf $SYSTEM/app/MicroG*
    rm -rf $SYSTEM/app/MozillaUnified*
    rm -rf $SYSTEM/app/nlp*
    rm -rf $SYSTEM/app/Nominatim*
    rm -rf $SYSTEM/product/app/AppleNLP*
    rm -rf $SYSTEM/product/app/AuroraDroid
    rm -rf $SYSTEM/product/app/AuroraStore
    rm -rf $SYSTEM/product/app/DejaVu*
    rm -rf $SYSTEM/product/app/DroidGuard
    rm -rf $SYSTEM/product/app/LocalGSM*
    rm -rf $SYSTEM/product/app/LocalWiFi*
    rm -rf $SYSTEM/product/app/MicroG*
    rm -rf $SYSTEM/product/app/MozillaUnified*
    rm -rf $SYSTEM/product/app/nlp*
    rm -rf $SYSTEM/product/app/Nominatim*
    rm -rf $SYSTEM/priv-app/AuroraServices
    rm -rf $SYSTEM/priv-app/FakeStore
    rm -rf $SYSTEM/priv-app/GmsCore
    rm -rf $SYSTEM/priv-app/GsfProxy
    rm -rf $SYSTEM/priv-app/MicroG*
    rm -rf $SYSTEM/priv-app/PatchPhonesky
    rm -rf $SYSTEM/priv-app/Phonesky
    rm -rf $SYSTEM/product/priv-app/AuroraServices
    rm -rf $SYSTEM/product/priv-app/FakeStore
    rm -rf $SYSTEM/product/priv-app/GmsCore
    rm -rf $SYSTEM/product/priv-app/GsfProxy
    rm -rf $SYSTEM/product/priv-app/MicroG*
    rm -rf $SYSTEM/product/priv-app/PatchPhonesky
    rm -rf $SYSTEM/product/priv-app/Phonesky
    rm -rf $SYSTEM/etc/default-permissions/microg*
    rm -rf $SYSTEM/etc/default-permissions/phonesky*
    rm -rf $SYSTEM/etc/permissions/features.xml
    rm -rf $SYSTEM/etc/permissions/com.android.vending*
    rm -rf $SYSTEM/etc/permissions/com.aurora.services*
    rm -rf $SYSTEM/etc/permissions/com.google.android.backup*
    rm -rf $SYSTEM/etc/permissions/com.google.android.gms*
    rm -rf $SYSTEM/etc/sysconfig/microg*
    rm -rf $SYSTEM/etc/sysconfig/nogoolag*
    rm -rf $SYSTEM/product/etc/default-permissions/microg*
    rm -rf $SYSTEM/product/etc/default-permissions/phonesky*
    rm -rf $SYSTEM/product/etc/permissions/features.xml
    rm -rf $SYSTEM/product/etc/permissions/com.android.vending*
    rm -rf $SYSTEM/product/etc/permissions/com.aurora.services*
    rm -rf $SYSTEM/product/etc/permissions/com.google.android.backup*
    rm -rf $SYSTEM/product/etc/permissions/com.google.android.gms*
    rm -rf $SYSTEM/product/etc/sysconfig/microg*
    rm -rf $SYSTEM/product/etc/sysconfig/nogoolag*
    rm -rf $SYSTEM/bin/nanodroid*
    rm -rf $SYSTEM/bin/novl
    rm -rf $SYSTEM/bin/npem
    rm -rf $SYSTEM/bin/nprp
    rm -rf $SYSTEM/bin/nutl
    rm -rf $SYSTEM/xbin/nanodroid*
    rm -rf $SYSTEM/xbin/novl
    rm -rf $SYSTEM/xbin/npem
    rm -rf $SYSTEM/xbin/nprp
    rm -rf $SYSTEM/xbin/nutl
  fi;
}

# Limit AOSP app installation to SDK29 and SDK28
lim_aosp_install() {
  if [ "$android_sdk" == "$supported_sdk_v29" ] || [ "$android_sdk" == "$supported_sdk_v28" ]; then
    pre_installed;
  fi;
}

# Remove pre-installed system files
pre_installed_v29() {
  if [ "$android_sdk" == "$supported_sdk_v29" ]; then
    zip_pkg() {
      rm -rf $SYSTEM_APP/GoogleCalendarSyncAdapter
      rm -rf $SYSTEM_APP/GoogleContactsSyncAdapter
      rm -rf $SYSTEM_APP/ExtShared
      rm -rf $SYSTEM_APP/GoogleExtShared
      rm -rf $SYSTEM_PRIV_APP/CarrierSetup
      rm -rf $SYSTEM_PRIV_APP/ConfigUpdater
      rm -rf $SYSTEM_PRIV_APP/GmsCoreSetupPrebuilt
      rm -rf $SYSTEM_PRIV_APP/ExtServices
      rm -rf $SYSTEM_PRIV_APP/GoogleExtServices
      rm -rf $SYSTEM_PRIV_APP/GoogleServicesFramework
      rm -rf $SYSTEM_PRIV_APP/Phonesky
      rm -rf $SYSTEM_PRIV_APP/PrebuiltGmsCoreQt
      rm -rf $SYSTEM_FRAMEWORK/com.google.android.dialer.support.jar
      rm -rf $SYSTEM_FRAMEWORK/com.google.android.maps.jar
      rm -rf $SYSTEM_FRAMEWORK/com.google.android.media.effects.jar
      rm -rf $SYSTEM_ETC_CONFIG/dialer_experience.xml
      rm -rf $SYSTEM_ETC_CONFIG/google.xml
      rm -rf $SYSTEM_ETC_CONFIG/google_build.xml
      rm -rf $SYSTEM_ETC_CONFIG/google_exclusives_enable.xml
      rm -rf $SYSTEM_ETC_CONFIG/google-hiddenapi-package-whitelist.xml
      rm -rf $SYSTEM_ETC_CONFIG/pixel_experience_2017.xml
      rm -rf $SYSTEM_ETC_CONFIG/pixel_experience_2018.xml
      rm -rf $SYSTEM_ETC_CONFIG/pixel_experience_2019_midyear.xml
      rm -rf $SYSTEM_ETC_CONFIG/pixel_experience_2019.xml
      rm -rf $SYSTEM_ETC_CONFIG/whitelist_com.android.omadm.service.xml
      rm -rf $SYSTEM_ETC_DEFAULT/default-permissions.xml
      rm -rf $SYSTEM_ETC_DEFAULT/opengapps-permissions.xml
      rm -rf $SYSTEM_ETC_PERM/com.google.android.dialer.support.xml
      rm -rf $SYSTEM_ETC_PERM/com.google.android.maps.xml
      rm -rf $SYSTEM_ETC_PERM/com.google.android.media.effects.xml
      rm -rf $SYSTEM_ETC_PERM/privapp-permissions-google.xml
      rm -rf $SYSTEM_ETC_PERM/split-permissions-google.xml
      rm -rf $SYSTEM_ETC_PREF/google.xml
      rm -rf $SYSTEM_ADDOND/90bit_gapps.sh
      rm -rf $SYSTEM/etc/g.prop
    }
    # Delete pre-installed APKs from product
    zip_pkg;
    # Temporary set system pathmap
    tmp_pathmap;
    # Delete pre-installed APKs from system
    zip_pkg;
    # Set product pathmap for installation
    product_pathmap;
  fi;
}

pre_installed_v28() {
  if [ "$android_sdk" == "$supported_sdk_v28" ]; then
    rm -rf $SYSTEM_APP/FaceLock
    rm -rf $SYSTEM_APP/GoogleCalendarSyncAdapter
    rm -rf $SYSTEM_APP/GoogleContactsSyncAdapter
    rm -rf $SYSTEM_APP/ExtShared
    rm -rf $SYSTEM_APP/GoogleExtShared
    rm -rf $SYSTEM_PRIV_APP/CarrierSetup
    rm -rf $SYSTEM_PRIV_APP/ConfigUpdater
    rm -rf $SYSTEM_PRIV_APP/GmsCoreSetupPrebuilt
    rm -rf $SYSTEM_PRIV_APP/ExtServices
    rm -rf $SYSTEM_PRIV_APP/GoogleExtServices
    rm -rf $SYSTEM_PRIV_APP/GoogleServicesFramework
    rm -rf $SYSTEM_PRIV_APP/Phonesky
    rm -rf $SYSTEM_PRIV_APP/PrebuiltGmsCorePi
    rm -rf $SYSTEM_FRAMEWORK/com.google.android.dialer.support.jar
    rm -rf $SYSTEM_FRAMEWORK/com.google.android.maps.jar
    rm -rf $SYSTEM_FRAMEWORK/com.google.android.media.effects.jar
    rm -rf $SYSTEM_LIB/libfilterpack_facedetect.so
    rm -rf $SYSTEM_LIB/libfrsdk.so
    rm -rf $SYSTEM_LIB64/libfacenet.so
    rm -rf $SYSTEM_LIB64/libfilterpack_facedetect.so
    rm -rf $SYSTEM_LIB64/libfrsdk.so
    rm -rf $SYSTEM_ETC_CONFIG/dialer_experience.xml
    rm -rf $SYSTEM_ETC_CONFIG/google.xml
    rm -rf $SYSTEM_ETC_CONFIG/google_build.xml
    rm -rf $SYSTEM_ETC_CONFIG/google_exclusives_enable.xml
    rm -rf $SYSTEM_ETC_CONFIG/google-hiddenapi-package-whitelist.xml
    rm -rf $SYSTEM_ETC_DEFAULT/default-permissions.xml
    rm -rf $SYSTEM_ETC_DEFAULT/opengapps-permissions.xml
    rm -rf $SYSTEM_ETC_PERM/com.google.android.dialer.support.xml
    rm -rf $SYSTEM_ETC_PERM/com.google.android.maps.xml
    rm -rf $SYSTEM_ETC_PERM/com.google.android.media.effects.xml
    rm -rf $SYSTEM_ETC_PERM/privapp-permissions-google.xml
    rm -rf $SYSTEM_ETC_PREF/google.xml
    rm -rf $SYSTEM_ADDOND/90bit_gapps.sh
    rm -rf $SYSTEM/etc/g.prop
    rm -rf $SYSTEM/bin/pm.sh
  fi;
}

pre_installed_v27() {
  if [ "$android_sdk" == "$supported_sdk_v27" ]; then
    rm -rf $SYSTEM_APP/FaceLock
    rm -rf $SYSTEM_APP/GoogleCalendarSyncAdapter
    rm -rf $SYSTEM_APP/GoogleContactsSyncAdapter
    rm -rf $SYSTEM_APP/ExtShared
    rm -rf $SYSTEM_APP/GoogleExtShared
    rm -rf $SYSTEM_PRIV_APP/CarrierSetup
    rm -rf $SYSTEM_PRIV_APP/ConfigUpdater
    rm -rf $SYSTEM_PRIV_APP/GmsCoreSetupPrebuilt
    rm -rf $SYSTEM_PRIV_APP/ExtServices
    rm -rf $SYSTEM_PRIV_APP/GoogleExtServices
    rm -rf $SYSTEM_PRIV_APP/GoogleServicesFramework
    rm -rf $SYSTEM_PRIV_APP/Phonesky
    rm -rf $SYSTEM_PRIV_APP/PrebuiltGmsCorePix
    rm -rf $SYSTEM_FRAMEWORK/com.google.android.dialer.support.jar
    rm -rf $SYSTEM_FRAMEWORK/com.google.android.maps.jar
    rm -rf $SYSTEM_FRAMEWORK/com.google.android.media.effects.jar
    rm -rf $SYSTEM_LIB/libfilterpack_facedetect.so
    rm -rf $SYSTEM_LIB/libfrsdk.so
    rm -rf $SYSTEM_LIB64/libfacenet.so
    rm -rf $SYSTEM_LIB64/libfilterpack_facedetect.so
    rm -rf $SYSTEM_LIB64/libfrsdk.so
    rm -rf $SYSTEM_ETC_CONFIG/dialer_experience.xml
    rm -rf $SYSTEM_ETC_CONFIG/google.xml
    rm -rf $SYSTEM_ETC_CONFIG/google_build.xml
    rm -rf $SYSTEM_ETC_CONFIG/google_exclusives_enable.xml
    rm -rf $SYSTEM_ETC_DEFAULT/default-permissions.xml
    rm -rf $SYSTEM_ETC_DEFAULT/opengapps-permissions.xml
    rm -rf $SYSTEM_ETC_PERM/com.google.android.dialer.support.xml
    rm -rf $SYSTEM_ETC_PERM/com.google.android.maps.xml
    rm -rf $SYSTEM_ETC_PERM/com.google.android.media.effects.xml
    rm -rf $SYSTEM_ETC_PERM/privapp-permissions-google.xml
    rm -rf $SYSTEM_ETC_PREF/google.xml
    rm -rf $SYSTEM_ADDOND/90bit_gapps.sh
    rm -rf $SYSTEM/etc/g.prop
  fi;
}

pre_installed_v25() {
  if [ "$android_sdk" == "$supported_sdk_v25" ]; then
    rm -rf $SYSTEM_APP/FaceLock
    rm -rf $SYSTEM_APP/GoogleCalendarSyncAdapter
    rm -rf $SYSTEM_APP/GoogleContactsSyncAdapter
    rm -rf $SYSTEM_APP/ExtShared
    rm -rf $SYSTEM_APP/GoogleExtShared
    rm -rf $SYSTEM_PRIV_APP/ConfigUpdater
    rm -rf $SYSTEM_PRIV_APP/ExtServices
    rm -rf $SYSTEM_PRIV_APP/GoogleExtServices
    rm -rf $SYSTEM_PRIV_APP/GoogleLoginService
    rm -rf $SYSTEM_PRIV_APP/GoogleServicesFramework
    rm -rf $SYSTEM_PRIV_APP/Phonesky
    rm -rf $SYSTEM_PRIV_APP/PrebuiltGmsCore
    rm -rf $SYSTEM_FRAMEWORK/com.google.android.dialer.support.jar
    rm -rf $SYSTEM_FRAMEWORK/com.google.android.maps.jar
    rm -rf $SYSTEM_FRAMEWORK/com.google.android.media.effects.jar
    rm -rf $SYSTEM_LIB/libfilterpack_facedetect.so
    rm -rf $SYSTEM_LIB/libfrsdk.so
    rm -rf $SYSTEM_LIB64/libfacenet.so
    rm -rf $SYSTEM_LIB64/libfilterpack_facedetect.so
    rm -rf $SYSTEM_LIB64/libfrsdk.so
    rm -rf $SYSTEM_ETC_CONFIG/dialer_experience.xml
    rm -rf $SYSTEM_ETC_CONFIG/google.xml
    rm -rf $SYSTEM_ETC_CONFIG/google_build.xml
    rm -rf $SYSTEM_ETC_CONFIG/google_exclusives_enable.xml
    rm -rf $SYSTEM_ETC_DEFAULT/default-permissions.xml
    rm -rf $SYSTEM_ETC_DEFAULT/opengapps-permissions.xml
    rm -rf $SYSTEM_ETC_PERM/com.google.android.dialer.support.xml
    rm -rf $SYSTEM_ETC_PERM/com.google.android.maps.xml
    rm -rf $SYSTEM_ETC_PERM/com.google.android.media.effects.xml
    rm -rf $SYSTEM_ETC_PREF/google.xml
    rm -rf $SYSTEM_ADDOND/90bit_gapps.sh
    rm -rf $SYSTEM/etc/g.prop
  fi;
}

# Install packages in sparse mode
set_sparse() {
  # Set sparse format
  send_sparse_1() {
    file_list="$(find "$TMP_SYS/" -mindepth 1 -type f | cut -d/ -f5-)"
    dir_list="$(find "$TMP_SYS/" -mindepth 1 -type d | cut -d/ -f5-)"
    for file in $file_list; do
        install -D "$TMP_SYS/${file}" "$SYSTEM_APP/${file}"
        chmod 0644 "$SYSTEM_APP/${file}";
    done
    for dir in $dir_list; do
        chmod 0755 "$SYSTEM_APP/${dir}";
    done
    # Add AOSP apps installation for ROMs shipped with GApps
    if [ "$AOSP_PKG_INSTALL" == "true" ]; then
      file_list="$(find "$TMP_SYS_AOSP/" -mindepth 1 -type f | cut -d/ -f5-)"
      dir_list="$(find "$TMP_SYS_AOSP/" -mindepth 1 -type d | cut -d/ -f5-)"
      for file in $file_list; do
          install -D "$TMP_SYS_AOSP/${file}" "$SYSTEM_APP/${file}"
          chmod 0644 "$SYSTEM_APP/${file}";
      done
      for dir in $dir_list; do
          chmod 0755 "$SYSTEM_APP/${dir}";
      done
    fi;
  }

  send_sparse_2() {
    file_list="$(find "$TMP_PRIV/" -mindepth 1 -type f | cut -d/ -f5-)"
    dir_list="$(find "$TMP_PRIV/" -mindepth 1 -type d | cut -d/ -f5-)"
    for file in $file_list; do
        install -D "$TMP_PRIV/${file}" "$SYSTEM_PRIV_APP/${file}"
        chmod 0644 "$SYSTEM_PRIV_APP/${file}";
    done
    for dir in $dir_list; do
        chmod 0755 "$SYSTEM_PRIV_APP/${dir}";
    done
    # Add AOSP apps installation for ROMs shipped with GApps
    if [ "$AOSP_PKG_INSTALL" == "true" ]; then
      file_list="$(find "$TMP_PRIV_AOSP/" -mindepth 1 -type f | cut -d/ -f5-)"
      dir_list="$(find "$TMP_PRIV_AOSP/" -mindepth 1 -type d | cut -d/ -f5-)"
      for file in $file_list; do
          install -D "$TMP_PRIV_AOSP/${file}" "$SYSTEM_PRIV_APP/${file}"
          chmod 0644 "$SYSTEM_PRIV_APP/${file}";
      done
      for dir in $dir_list; do
          chmod 0755 "$SYSTEM_PRIV_APP/${dir}";
      done
    fi;
  }

  send_sparse_3() {
    file_list="$(find "$TMP_FRAMEWORK/" -mindepth 1 -type f | cut -d/ -f5-)"
    dir_list="$(find "$TMP_FRAMEWORK/" -mindepth 1 -type d | cut -d/ -f5-)"
    for file in $file_list; do
        install -D "$TMP_FRAMEWORK/${file}" "$SYSTEM_FRAMEWORK/${file}"
        chmod 0644 "$SYSTEM_FRAMEWORK/${file}";
    done
    for dir in $dir_list; do
        chmod 0755 "$SYSTEM_FRAMEWORK/${dir}";
    done
  }

  send_sparse_4() {
    file_list="$(find "$TMP_LIB/" -mindepth 1 -type f | cut -d/ -f5-)"
    dir_list="$(find "$TMP_LIB/" -mindepth 1 -type d | cut -d/ -f5-)"
    for file in $file_list; do
        install -D "$TMP_LIB/${file}" "$SYSTEM_LIB/${file}"
        chmod 0644 "$SYSTEM_LIB/${file}";
    done
    for dir in $dir_list; do
        chmod 0755 "$SYSTEM_LIB/${dir}";
    done
  }

  send_sparse_5() {
    file_list="$(find "$TMP_LIB64/" -mindepth 1 -type f | cut -d/ -f5-)"
    dir_list="$(find "$TMP_LIB64/" -mindepth 1 -type d | cut -d/ -f5-)"
    for file in $file_list; do
        install -D "$TMP_LIB64/${file}" "$SYSTEM_LIB64/${file}"
        chmod 0644 "$SYSTEM_LIB64/${file}";
    done
    for dir in $dir_list; do
        chmod 0755 "$SYSTEM_LIB64/${dir}";
    done
  }

  send_sparse_6() {
    file_list="$(find "$TMP_CONFIG/" -mindepth 1 -type f | cut -d/ -f5-)"
    dir_list="$(find "$TMP_CONFIG/" -mindepth 1 -type d | cut -d/ -f5-)"
    for file in $file_list; do
        install -D "$TMP_CONFIG/${file}" "$SYSTEM_ETC_CONFIG/${file}"
        chmod 0644 "$SYSTEM_ETC_CONFIG/${file}";
    done
    for dir in $dir_list; do
        chmod 0755 "$SYSTEM_ETC_CONFIG/${dir}";
    done
  }

  send_sparse_7() {
    file_list="$(find "$TMP_DEFAULT_PERM/" -mindepth 1 -type f | cut -d/ -f5-)"
    dir_list="$(find "$TMP_DEFAULT_PERM/" -mindepth 1 -type d | cut -d/ -f5-)"
    for file in $file_list; do
        install -D "$TMP_DEFAULT_PERM/${file}" "$SYSTEM_ETC_DEFAULT/${file}"
        chmod 0644 "$SYSTEM_ETC_DEFAULT/${file}";
    done
    for dir in $dir_list; do
        chmod 0755 "$SYSTEM_ETC_DEFAULT/${dir}";
    done
  }

  send_sparse_8() {
    file_list="$(find "$TMP_G_PREF/" -mindepth 1 -type f | cut -d/ -f5-)"
    dir_list="$(find "$TMP_G_PREF/" -mindepth 1 -type d | cut -d/ -f5-)"
    for file in $file_list; do
        install -D "$TMP_G_PREF/${file}" "$SYSTEM_ETC_PREF/${file}"
        chmod 0644 "$SYSTEM_ETC_PREF/${file}";
    done
    for dir in $dir_list; do
        chmod 0755 "$SYSTEM_ETC_PREF/${dir}";
    done
  }

  send_sparse_9() {
    file_list="$(find "$TMP_G_PERM/" -mindepth 1 -type f | cut -d/ -f5-)"
    dir_list="$(find "$TMP_G_PERM/" -mindepth 1 -type d | cut -d/ -f5-)"
    for file in $file_list; do
        install -D "$TMP_G_PERM/${file}" "$SYSTEM_ETC_PERM/${file}"
        chmod 0644 "$SYSTEM_ETC_PERM/${file}";
    done
    for dir in $dir_list; do
        chmod 0755 "$SYSTEM_ETC_PERM/${dir}";
    done
    # Ship privileged permissions XML files for AOSP apps
    if [ "$AOSP_PKG_INSTALL" == "true" ]; then
      file_list="$(find "$TMP_G_PERM_AOSP/" -mindepth 1 -type f | cut -d/ -f5-)"
      dir_list="$(find "$TMP_G_PERM_AOSP/" -mindepth 1 -type d | cut -d/ -f5-)"
      for file in $file_list; do
          install -D "$TMP_G_PERM_AOSP/${file}" "$SYSTEM_ETC_PERM/${file}"
          chmod 0644 "$SYSTEM_ETC_PERM/${file}";
      done
      for dir in $dir_list; do
          chmod 0755 "$SYSTEM_ETC_PERM/${dir}";
      done
    fi;
  }

  send_sparse_10() {
    cp -f $TMP/g.prop $SYSTEM/etc/g.prop
    chmod 0644 $SYSTEM/etc/g.prop
  }

  # execute sparse functions
  exec_sparse_format() {
    if [ "$ZIPTYPE" == "addon" ]; then
      send_sparse_1;
      send_sparse_2;
    else
      send_sparse_1;
      send_sparse_2;
      send_sparse_3;
      send_sparse_4;
      send_sparse_5;
      send_sparse_6;
      send_sparse_7;
      send_sparse_8;
      send_sparse_9;
      send_sparse_10;
    fi;
  }
  exec_sparse_format;
}

# Function 'send_sparse_11()' must be in a separate call function
set_sparse_backup() {
  # Do not merge 'send_sparse_11()' function in 'set_sparse()' function
  send_sparse_11() {
    file_list="$(find "$TMP_ADDON/" -mindepth 1 -type f | cut -d/ -f5-)"
    dir_list="$(find "$TMP_ADDON/" -mindepth 1 -type d | cut -d/ -f5-)"
    for file in $file_list; do
        install -D "$TMP_ADDON/${file}" "$SYSTEM_ADDOND/${file}"
        chmod 0755 "$SYSTEM_ADDOND/${file}";
    done
    for dir in $dir_list; do
        chmod 0755 "$SYSTEM_ADDOND/${dir}";
    done
  }
  send_sparse_11;
}

# Function 'send_sparse_12()' must be in a separate call function
set_sparse_excl() {
  # Do not merge 'send_sparse_12()' function in 'set_sparse()' function
  send_sparse_12() {
    file_list="$(find "$TMP_PRIV_SETUP/" -mindepth 1 -type f | cut -d/ -f5-)"
    dir_list="$(find "$TMP_PRIV_SETUP/" -mindepth 1 -type d | cut -d/ -f5-)"
    for file in $file_list; do
        install -D "$TMP_PRIV_SETUP/${file}" "$SYSTEM_PRIV_APP/${file}"
        chmod 0644 "$SYSTEM_PRIV_APP/${file}";
    done
    for dir in $dir_list; do
        chmod 0755 "$SYSTEM_PRIV_APP/${dir}";
    done
  }
  send_sparse_12;
}
# end sparse method

# Set installation functions for Android SDK 29
sdk_v29_install() {
  if [ "$android_sdk" == "$supported_sdk_v29" ]; then
    # Set default packages
    ZIP="
      zip/core/priv_app_ConfigUpdater.tar.xz
      zip/core/priv_app_GoogleExtServices.tar.xz
      zip/core/priv_app_GoogleServicesFramework.tar.xz
      zip/core/priv_app_Phonesky.tar.xz
      zip/core/priv_app_PrebuiltGmsCoreQt.tar.xz
      zip/sys/sys_app_GoogleCalendarSyncAdapter.tar.xz
      zip/sys/sys_app_GoogleContactsSyncAdapter.tar.xz
      zip/sys/sys_app_GoogleExtShared.tar.xz
      zip/sys_Config_Permission.tar.xz
      zip/sys_Default_Permission.tar.xz
      zip/sys_Framework.tar.xz
      zip/sys_Permissions.tar.xz
      zip/sys_Pref_Permission.tar.xz";

    # Unzip system files from installer
    unpack_zip;

    if [ "$AOSP_PKG_INSTALL" == "true" ]; then
      ZIP="
        zip/core/aosp/priv_app_Contacts.tar.xz
        zip/core/aosp/priv_app_Dialer.tar.xz
        zip/core/aosp/priv_app_ManagedProvisioning.tar.xz
        zip/core/aosp/priv_app_Provision.tar.xz
        zip/sys/aosp/sys_app_Messaging.tar.xz
        zip/sys_Permissions_AOSP.tar.xz";

      # Re-define unzip function for AOSP apps with similar target
      unpack_zip;
    fi;

    # Unpack system files
    extract_app() {
      echo "-----------------------------------" >> $LOG;
      echo "- Unpack SYS-APP Files" >> $LOG;
      tar tvf $ZIP_FILE/sys/sys_app_GoogleCalendarSyncAdapter.tar.xz >> $LOG;
      tar tvf $ZIP_FILE/sys/sys_app_GoogleContactsSyncAdapter.tar.xz >> $LOG;
      tar tvf $ZIP_FILE/sys/sys_app_GoogleExtShared.tar.xz >> $LOG;
      tar -xf $ZIP_FILE/sys/sys_app_GoogleCalendarSyncAdapter.tar.xz -C $TMP_SYS;
      tar -xf $ZIP_FILE/sys/sys_app_GoogleContactsSyncAdapter.tar.xz -C $TMP_SYS;
      tar -xf $ZIP_FILE/sys/sys_app_GoogleExtShared.tar.xz -C $TMP_SYS;
      if [ "$AOSP_PKG_INSTALL" == "true" ]; then
        tar tvf $ZIP_FILE/sys/aosp/sys_app_Messaging.tar.xz >> $LOG;
        tar -xf $ZIP_FILE/sys/aosp/sys_app_Messaging.tar.xz -C $TMP_SYS_AOSP;
      fi;
      echo "- Done" >> $LOG;
      echo "-----------------------------------" >> $LOG;
      echo "- Unpack PRIV-APP Files" >> $LOG;
      tar tvf $ZIP_FILE/core/priv_app_ConfigUpdater.tar.xz >> $LOG;
      tar tvf $ZIP_FILE/core/priv_app_GoogleExtServices.tar.xz >> $LOG;
      tar tvf $ZIP_FILE/core/priv_app_GoogleServicesFramework.tar.xz >> $LOG;
      tar tvf $ZIP_FILE/core/priv_app_Phonesky.tar.xz >> $LOG;
      tar tvf $ZIP_FILE/core/priv_app_PrebuiltGmsCoreQt.tar.xz >> $LOG;
      tar -xf $ZIP_FILE/core/priv_app_ConfigUpdater.tar.xz -C $TMP_PRIV;
      tar -xf $ZIP_FILE/core/priv_app_GoogleExtServices.tar.xz -C $TMP_PRIV;
      tar -xf $ZIP_FILE/core/priv_app_GoogleServicesFramework.tar.xz -C $TMP_PRIV;
      tar -xf $ZIP_FILE/core/priv_app_Phonesky.tar.xz -C $TMP_PRIV;
      tar -xf $ZIP_FILE/core/priv_app_PrebuiltGmsCoreQt.tar.xz -C $TMP_PRIV;
      if [ "$AOSP_PKG_INSTALL" == "true" ]; then
        tar tvf $ZIP_FILE/core/aosp/priv_app_Contacts.tar.xz >> $LOG;
        tar tvf $ZIP_FILE/core/aosp/priv_app_Dialer.tar.xz >> $LOG;
        tar tvf $ZIP_FILE/core/aosp/priv_app_ManagedProvisioning.tar.xz >> $LOG;
        tar tvf $ZIP_FILE/core/aosp/priv_app_Provision.tar.xz >> $LOG;
        tar -xf $ZIP_FILE/core/aosp/priv_app_Contacts.tar.xz -C $TMP_PRIV_AOSP;
        tar -xf $ZIP_FILE/core/aosp/priv_app_Dialer.tar.xz -C $TMP_PRIV_AOSP;
        tar -xf $ZIP_FILE/core/aosp/priv_app_ManagedProvisioning.tar.xz -C $TMP_PRIV_AOSP;
        tar -xf $ZIP_FILE/core/aosp/priv_app_Provision.tar.xz -C $TMP_PRIV_AOSP;
      fi;
      echo "- Done" >> $LOG;
      echo "-----------------------------------" >> $LOG;
      echo "- Unpack Framework Files" >> $LOG;
      tar tvf $ZIP_FILE/sys_Framework.tar.xz >> $LOG;
      tar -xf $ZIP_FILE/sys_Framework.tar.xz -C $TMP_FRAMEWORK;
      echo "- Done" >> $LOG;
      echo "-----------------------------------" >> $LOG;
      echo "- Unpack System Lib" >> $LOG;
      echo "- Done" >> $LOG;
      echo "-----------------------------------" >> $LOG;
      echo "- Unpack System Lib64" >> $LOG;
      echo "- Done" >> $LOG;
      echo "-----------------------------------" >> $LOG;
      echo "- Unpack System Files" >> $LOG;
      tar tvf $ZIP_FILE/sys_Config_Permission.tar.xz >> $LOG;
      tar tvf $ZIP_FILE/sys_Default_Permission.tar.xz >> $LOG;
      tar tvf $ZIP_FILE/sys_Permissions.tar.xz >> $LOG;
      tar tvf $ZIP_FILE/sys_Pref_Permission.tar.xz >> $LOG;
      tar -xf $ZIP_FILE/sys_Config_Permission.tar.xz -C $TMP_CONFIG;
      tar -xf $ZIP_FILE/sys_Default_Permission.tar.xz -C $TMP_DEFAULT_PERM;
      tar -xf $ZIP_FILE/sys_Permissions.tar.xz -C $TMP_G_PERM;
      tar -xf $ZIP_FILE/sys_Pref_Permission.tar.xz -C $TMP_G_PREF;
      if [ "$AOSP_PKG_INSTALL" == "true" ]; then
        tar tvf $ZIP_FILE/sys_Permissions_AOSP.tar.xz >> $LOG;
        tar -xf $ZIP_FILE/sys_Permissions_AOSP.tar.xz -C $TMP_G_PERM_AOSP;
      fi;
      echo "- Done" >> $LOG;
      echo "-----------------------------------" >> $LOG;
      echo "- Installation Complete" >> $LOG;
      echo "-----------------------------------" >> $LOG;
      echo "Finish at $( date +"%m-%d-%Y %H:%M:%S" )" >> $LOG;
      echo "-----------------------------------" >> $LOG;
    }

    # Set selinux context
    selinux_context_s1() {
      chcon -h u:object_r:system_file:s0 "$SYSTEM_APP/GoogleCalendarSyncAdapter";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_APP/GoogleContactsSyncAdapter";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_APP/GoogleExtShared";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_APP/GoogleCalendarSyncAdapter/GoogleCalendarSyncAdapter.apk";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_APP/GoogleContactsSyncAdapter/GoogleContactsSyncAdapter.apk";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_APP/GoogleExtShared/GoogleExtShared.apk";
      if [ "$AOSP_PKG_INSTALL" == "true" ]; then
        chcon -h u:object_r:system_file:s0 "$SYSTEM_APP/Messaging";
        chcon -h u:object_r:system_file:s0 "$SYSTEM_APP/Messaging/Messaging.apk";
      fi;
    }

    selinux_context_sp2() {
      chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/ConfigUpdater";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/GoogleExtServices";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/GoogleServicesFramework";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/Phonesky";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/PrebuiltGmsCoreQt";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/ConfigUpdater/ConfigUpdater.apk";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/GoogleExtServices/GoogleExtServices.apk";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/GoogleServicesFramework/GoogleServicesFramework.apk";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/Phonesky/Phonesky.apk";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/PrebuiltGmsCoreQt/PrebuiltGmsCoreQt.apk";
      if [ "$AOSP_PKG_INSTALL" == "true" ]; then
        chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/Contacts";
        chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/Dialer";
        chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/ManagedProvisioning";
        chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/Provision";
        chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/Contacts/Contacts.apk";
        chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/Dialer/Dialer.apk";
        chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/ManagedProvisioning/ManagedProvisioning.apk";
        chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/Provision/Provision.apk";
      fi;
    }

    selinux_context_sf3() {
      chcon -h u:object_r:system_file:s0 "$SYSTEM_FRAMEWORK/com.google.android.dialer.support.jar";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_FRAMEWORK/com.google.android.maps.jar";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_FRAMEWORK/com.google.android.media.effects.jar";
    }

    selinux_context_sl4() {
      return 0;
    }

    selinux_context_sl5() {
      return 0;
    }

    selinux_context_se6() {
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_DEFAULT";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_DEFAULT/default-permissions.xml";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_DEFAULT/opengapps-permissions.xml";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_PERM/com.google.android.dialer.support.xml";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_PERM/com.google.android.maps.xml";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_PERM/com.google.android.media.effects.xml";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_PERM/privapp-permissions-google.xml";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_PERM/split-permissions-google.xml";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_PREF";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_PREF/google.xml";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_CONFIG/dialer_experience.xml";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_CONFIG/google.xml";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_CONFIG/google_build.xml";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_CONFIG/google_exclusives_enable.xml";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_CONFIG/google-hiddenapi-package-whitelist.xml";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_CONFIG/pixel_experience_2017.xml";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_CONFIG/pixel_experience_2018.xml";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_CONFIG/pixel_experience_2019_midyear.xml";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_CONFIG/pixel_experience_2019.xml";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_CONFIG/whitelist_com.android.omadm.service.xml";
      chcon -h u:object_r:system_file:s0 "$SYSTEM/etc/g.prop";
      if [ "$AOSP_PKG_INSTALL" == "true" ]; then
        chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_PERM/com.android.contacts.xml";
        chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_PERM/com.android.dialer.xml";
        chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_PERM/com.android.managedprovisioning.xml";
        chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_PERM/com.android.provision.xml";
      fi;
    }
    # end selinux method

    # APK optimization using zipalign tool
    apk_opt() {
      $ZIPALIGN_TOOL -p -v 4 $SYSTEM_APP/GoogleCalendarSyncAdapter/GoogleCalendarSyncAdapter.apk $ZIPALIGN_OUTFILE/GoogleCalendarSyncAdapter.apk >> $ZIPALIGN_LOG;
      $ZIPALIGN_TOOL -p -v 4 $SYSTEM_APP/GoogleContactsSyncAdapter/GoogleContactsSyncAdapter.apk $ZIPALIGN_OUTFILE/GoogleContactsSyncAdapter.apk >> $ZIPALIGN_LOG;
      $ZIPALIGN_TOOL -p -v 4 $SYSTEM_APP/GoogleExtShared/GoogleExtShared.apk $ZIPALIGN_OUTFILE/GoogleExtShared.apk >> $ZIPALIGN_LOG;
      $ZIPALIGN_TOOL -p -v 4 $SYSTEM_PRIV_APP/ConfigUpdater/ConfigUpdater.apk $ZIPALIGN_OUTFILE/ConfigUpdater.apk >> $ZIPALIGN_LOG;
      $ZIPALIGN_TOOL -p -v 4 $SYSTEM_PRIV_APP/GoogleExtServices/GoogleExtServices.apk $ZIPALIGN_OUTFILE/GoogleExtServices.apk >> $ZIPALIGN_LOG;
      $ZIPALIGN_TOOL -p -v 4 $SYSTEM_PRIV_APP/GoogleServicesFramework/GoogleServicesFramework.apk $ZIPALIGN_OUTFILE/GoogleServicesFramework.apk >> $ZIPALIGN_LOG;
      $ZIPALIGN_TOOL -p -v 4 $SYSTEM_PRIV_APP/Phonesky/Phonesky.apk $ZIPALIGN_OUTFILE/Phonesky.apk >> $ZIPALIGN_LOG;
      $ZIPALIGN_TOOL -p -v 4 $SYSTEM_PRIV_APP/PrebuiltGmsCoreQt/PrebuiltGmsCoreQt.apk $ZIPALIGN_OUTFILE/PrebuiltGmsCoreQt.apk >> $ZIPALIGN_LOG;
      if [ "$AOSP_PKG_INSTALL" == "true" ]; then
        $ZIPALIGN_TOOL -p -v 4 $SYSTEM_APP/Messaging/Messaging.apk $ZIPALIGN_OUTFILE/Messaging.apk >> $ZIPALIGN_LOG;
        $ZIPALIGN_TOOL -p -v 4 $SYSTEM_PRIV_APP/Contacts/Contacts.apk $ZIPALIGN_OUTFILE/Contacts.apk >> $ZIPALIGN_LOG;
        $ZIPALIGN_TOOL -p -v 4 $SYSTEM_PRIV_APP/Dialer/Dialer.apk $ZIPALIGN_OUTFILE/Dialer.apk >> $ZIPALIGN_LOG;
        $ZIPALIGN_TOOL -p -v 4 $SYSTEM_PRIV_APP/ManagedProvisioning/ManagedProvisioning.apk $ZIPALIGN_OUTFILE/ManagedProvisioning.apk >> $ZIPALIGN_LOG;
        $ZIPALIGN_TOOL -p -v 4 $SYSTEM_PRIV_APP/Provision/Provision.apk $ZIPALIGN_OUTFILE/Provision.apk >> $ZIPALIGN_LOG;
      fi;
    }

    pre_opt() {
      rm -rf $SYSTEM_APP/GoogleCalendarSyncAdapter/GoogleCalendarSyncAdapter.apk
      rm -rf $SYSTEM_APP/GoogleContactsSyncAdapter/GoogleContactsSyncAdapter.apk
      rm -rf $SYSTEM_APP/GoogleExtShared/GoogleExtShared.apk
      rm -rf $SYSTEM_PRIV_APP/ConfigUpdater/ConfigUpdater.apk
      rm -rf $SYSTEM_PRIV_APP/GoogleExtServices/GoogleExtServices.apk
      rm -rf $SYSTEM_PRIV_APP/GoogleServicesFramework/GoogleServicesFramework.apk
      rm -rf $SYSTEM_PRIV_APP/Phonesky/Phonesky.apk
      rm -rf $SYSTEM_PRIV_APP/PrebuiltGmsCoreQt/PrebuiltGmsCoreQt.apk
      if [ "$AOSP_PKG_INSTALL" == "true" ]; then
        rm -rf $SYSTEM_APP/Messaging/Messaging.apk
        rm -rf $SYSTEM_PRIV_APP/Contacts/Contacts.apk
        rm -rf $SYSTEM_PRIV_APP/Dialer/Dialer.apk
        rm -rf $SYSTEM_PRIV_APP/ManagedProvisioning/ManagedProvisioning.apk
        rm -rf $SYSTEM_PRIV_APP/Provision/Provision.apk
      fi;
    }

    add_opt() {
      cp -f $ZIPALIGN_OUTFILE/GoogleCalendarSyncAdapter.apk $SYSTEM_APP/GoogleCalendarSyncAdapter/GoogleCalendarSyncAdapter.apk
      cp -f $ZIPALIGN_OUTFILE/GoogleContactsSyncAdapter.apk $SYSTEM_APP/GoogleContactsSyncAdapter/GoogleContactsSyncAdapter.apk
      cp -f $ZIPALIGN_OUTFILE/GoogleExtShared.apk $SYSTEM_APP/GoogleExtShared/GoogleExtShared.apk
      cp -f $ZIPALIGN_OUTFILE/ConfigUpdater.apk $SYSTEM_PRIV_APP/ConfigUpdater/ConfigUpdater.apk
      cp -f $ZIPALIGN_OUTFILE/GoogleExtServices.apk $SYSTEM_PRIV_APP/GoogleExtServices/GoogleExtServices.apk
      cp -f $ZIPALIGN_OUTFILE/GoogleServicesFramework.apk $SYSTEM_PRIV_APP/GoogleServicesFramework/GoogleServicesFramework.apk
      cp -f $ZIPALIGN_OUTFILE/Phonesky.apk $SYSTEM_PRIV_APP/Phonesky/Phonesky.apk
      cp -f $ZIPALIGN_OUTFILE/PrebuiltGmsCoreQt.apk $SYSTEM_PRIV_APP/PrebuiltGmsCoreQt/PrebuiltGmsCoreQt.apk
      if [ "$AOSP_PKG_INSTALL" == "true" ]; then
        cp -f $ZIPALIGN_OUTFILE/Messaging.apk $SYSTEM_APP/Messaging/Messaging.apk
        cp -f $ZIPALIGN_OUTFILE/Contacts.apk $SYSTEM_PRIV_APP/Contacts/Contacts.apk
        cp -f $ZIPALIGN_OUTFILE/Dialer.apk $SYSTEM_PRIV_APP/Dialer/Dialer.apk
        cp -f $ZIPALIGN_OUTFILE/ManagedProvisioning.apk $SYSTEM_PRIV_APP/ManagedProvisioning/ManagedProvisioning.apk
        cp -f $ZIPALIGN_OUTFILE/Provision.apk $SYSTEM_PRIV_APP/Provision/Provision.apk
      fi;
    }

    perm_opt() {
      chmod 0644 $SYSTEM_APP/GoogleCalendarSyncAdapter/GoogleCalendarSyncAdapter.apk
      chmod 0644 $SYSTEM_APP/GoogleContactsSyncAdapter/GoogleContactsSyncAdapter.apk
      chmod 0644 $SYSTEM_APP/GoogleExtShared/GoogleExtShared.apk
      chmod 0644 $SYSTEM_PRIV_APP/ConfigUpdater/ConfigUpdater.apk
      chmod 0644 $SYSTEM_PRIV_APP/GoogleExtServices/GoogleExtServices.apk
      chmod 0644 $SYSTEM_PRIV_APP/GoogleServicesFramework/GoogleServicesFramework.apk
      chmod 0644 $SYSTEM_PRIV_APP/Phonesky/Phonesky.apk
      chmod 0644 $SYSTEM_PRIV_APP/PrebuiltGmsCoreQt/PrebuiltGmsCoreQt.apk
      if [ "$AOSP_PKG_INSTALL" == "true" ]; then
        chmod 0644 $SYSTEM_APP/Messaging/Messaging.apk
        chmod 0644 $SYSTEM_PRIV_APP/Contacts/Contacts.apk
        chmod 0644 $SYSTEM_PRIV_APP/Dialer/Dialer.apk
        chmod 0644 $SYSTEM_PRIV_APP/ManagedProvisioning/ManagedProvisioning.apk
        chmod 0644 $SYSTEM_PRIV_APP/Provision/Provision.apk
      fi;
    }
    # end opt method

    # execute installation functions
    sdk_v29() {
      extract_app;
      set_sparse;
      selinux_context_s1;
      selinux_context_sp2;
      selinux_context_sf3;
      selinux_context_sl4;
      selinux_context_sl5;
      selinux_context_se6;
      apk_opt;
      pre_opt;
      add_opt;
      perm_opt;
      # Re-run selinux functions for optimized APKs
      selinux_context_s1;
      selinux_context_sp2;
      # end selinux functions
    }
    sdk_v29;
    # Print installed files to sdk log
    cat $LOG >> $sdk_v29;
  else
    echo "Target Android SDK Version : $android_sdk" >> $sdk_v29;
  fi;
}

# Set installation functions for Android SDK 28
sdk_v28_install() {
  if [ "$android_sdk" == "$supported_sdk_v28" ]; then
    # Set default packages
    ZIP="
      zip/core/priv_app_ConfigUpdater.tar.xz
      zip/core/priv_app_GoogleExtServices.tar.xz
      zip/core/priv_app_GoogleServicesFramework.tar.xz
      zip/core/priv_app_Phonesky.tar.xz
      zip/core/priv_app_PrebuiltGmsCorePi.tar.xz
      zip/sys/sys_app_FaceLock.tar.xz
      zip/sys/sys_app_GoogleCalendarSyncAdapter.tar.xz
      zip/sys/sys_app_GoogleContactsSyncAdapter.tar.xz
      zip/sys/sys_app_GoogleExtShared.tar.xz
      zip/sys_Config_Permission.tar.xz
      zip/sys_Default_Permission.tar.xz
      zip/sys_Framework.tar.xz
      zip/sys_Permissions.tar.xz
      zip/sys_Pref_Permission.tar.xz
      zip/facelock_lib32.tar.xz
      zip/facelock_lib64.tar.xz";

    # Unzip system files from installer
    unpack_zip;

    if [ "$AOSP_PKG_INSTALL" == "true" ]; then
      ZIP="
        zip/core/aosp/priv_app_Contacts.tar.xz
        zip/core/aosp/priv_app_Dialer.tar.xz
        zip/core/aosp/priv_app_ManagedProvisioning.tar.xz
        zip/core/aosp/priv_app_Provision.tar.xz
        zip/sys/aosp/sys_app_Messaging.tar.xz
        zip/sys_Permissions_AOSP.tar.xz";

      # Re-define unzip function for AOSP apps with similar target
      unpack_zip;
    fi;

    # Unpack system files
    extract_app() {
      echo "-----------------------------------" >> $LOG;
      echo "- Unpack SYS-APP Files" >> $LOG;
      tar tvf $ZIP_FILE/sys/sys_app_FaceLock.tar.xz >> $LOG;
      tar tvf $ZIP_FILE/sys/sys_app_GoogleCalendarSyncAdapter.tar.xz >> $LOG;
      tar tvf $ZIP_FILE/sys/sys_app_GoogleContactsSyncAdapter.tar.xz >> $LOG;
      tar tvf $ZIP_FILE/sys/sys_app_GoogleExtShared.tar.xz >> $LOG;
      tar -xf $ZIP_FILE/sys/sys_app_FaceLock.tar.xz -C $TMP_SYS;
      tar -xf $ZIP_FILE/sys/sys_app_GoogleCalendarSyncAdapter.tar.xz -C $TMP_SYS;
      tar -xf $ZIP_FILE/sys/sys_app_GoogleContactsSyncAdapter.tar.xz -C $TMP_SYS;
      tar -xf $ZIP_FILE/sys/sys_app_GoogleExtShared.tar.xz -C $TMP_SYS;
      if [ "$AOSP_PKG_INSTALL" == "true" ]; then
        tar tvf $ZIP_FILE/sys/aosp/sys_app_Messaging.tar.xz >> $LOG;
        tar -xf $ZIP_FILE/sys/aosp/sys_app_Messaging.tar.xz -C $TMP_SYS_AOSP;
      fi;
      echo "- Done" >> $LOG;
      echo "-----------------------------------" >> $LOG;
      echo "- Unpack PRIV-APP Files" >> $LOG;
      tar tvf $ZIP_FILE/core/priv_app_ConfigUpdater.tar.xz >> $LOG;
      tar tvf $ZIP_FILE/core/priv_app_GoogleExtServices.tar.xz >> $LOG;
      tar tvf $ZIP_FILE/core/priv_app_GoogleServicesFramework.tar.xz >> $LOG;
      tar tvf $ZIP_FILE/core/priv_app_Phonesky.tar.xz >> $LOG;
      tar tvf $ZIP_FILE/core/priv_app_PrebuiltGmsCorePi.tar.xz >> $LOG;
      tar -xf $ZIP_FILE/core/priv_app_ConfigUpdater.tar.xz -C $TMP_PRIV;
      tar -xf $ZIP_FILE/core/priv_app_GoogleExtServices.tar.xz -C $TMP_PRIV;
      tar -xf $ZIP_FILE/core/priv_app_GoogleServicesFramework.tar.xz -C $TMP_PRIV;
      tar -xf $ZIP_FILE/core/priv_app_Phonesky.tar.xz -C $TMP_PRIV;
      tar -xf $ZIP_FILE/core/priv_app_PrebuiltGmsCorePi.tar.xz -C $TMP_PRIV;
      if [ "$AOSP_PKG_INSTALL" == "true" ]; then
        tar tvf $ZIP_FILE/core/aosp/priv_app_Contacts.tar.xz >> $LOG;
        tar tvf $ZIP_FILE/core/aosp/priv_app_Dialer.tar.xz >> $LOG;
        tar tvf $ZIP_FILE/core/aosp/priv_app_ManagedProvisioning.tar.xz >> $LOG;
        tar tvf $ZIP_FILE/core/aosp/priv_app_Provision.tar.xz >> $LOG;
        tar -xf $ZIP_FILE/core/aosp/priv_app_Contacts.tar.xz -C $TMP_PRIV_AOSP;
        tar -xf $ZIP_FILE/core/aosp/priv_app_Dialer.tar.xz -C $TMP_PRIV_AOSP;
        tar -xf $ZIP_FILE/core/aosp/priv_app_ManagedProvisioning.tar.xz -C $TMP_PRIV_AOSP;
        tar -xf $ZIP_FILE/core/aosp/priv_app_Provision.tar.xz -C $TMP_PRIV_AOSP;
      fi;
      echo "- Done" >> $LOG;
      echo "-----------------------------------" >> $LOG;
      echo "- Unpack Framework Files" >> $LOG;
      tar tvf $ZIP_FILE/sys_Framework.tar.xz >> $LOG;
      tar -xf $ZIP_FILE/sys_Framework.tar.xz -C $TMP_FRAMEWORK;
      echo "- Done" >> $LOG;
      echo "-----------------------------------" >> $LOG;
      echo "- Unpack System Lib" >> $LOG;
      tar tvf $ZIP_FILE/facelock_lib32.tar.xz >> $LOG;
      tar -xf $ZIP_FILE/facelock_lib32.tar.xz -C $TMP_LIB;
      echo "- Done" >> $LOG;
      echo "-----------------------------------" >> $LOG;
      echo "- Unpack System Lib64" >> $LOG;
      tar tvf $ZIP_FILE/facelock_lib64.tar.xz >> $LOG;
      tar -xf $ZIP_FILE/facelock_lib64.tar.xz -C $TMP_LIB64;
      echo "- Done" >> $LOG;
      echo "-----------------------------------" >> $LOG;
      echo "- Unpack System Files" >> $LOG;
      tar tvf $ZIP_FILE/sys_Config_Permission.tar.xz >> $LOG;
      tar tvf $ZIP_FILE/sys_Default_Permission.tar.xz >> $LOG;
      tar tvf $ZIP_FILE/sys_Permissions.tar.xz >> $LOG;
      tar tvf $ZIP_FILE/sys_Pref_Permission.tar.xz >> $LOG;
      tar -xf $ZIP_FILE/sys_Config_Permission.tar.xz -C $TMP_CONFIG;
      tar -xf $ZIP_FILE/sys_Default_Permission.tar.xz -C $TMP_DEFAULT_PERM;
      tar -xf $ZIP_FILE/sys_Permissions.tar.xz -C $TMP_G_PERM;
      tar -xf $ZIP_FILE/sys_Pref_Permission.tar.xz -C $TMP_G_PREF;
      if [ "$AOSP_PKG_INSTALL" == "true" ]; then
        tar tvf $ZIP_FILE/sys_Permissions_AOSP.tar.xz >> $LOG;
        tar -xf $ZIP_FILE/sys_Permissions_AOSP.tar.xz -C $TMP_G_PERM_AOSP;
      fi;
      echo "- Done" >> $LOG;
      echo "-----------------------------------" >> $LOG;
      echo "- Installation Complete" >> $LOG;
      echo "-----------------------------------" >> $LOG;
      echo "Finish at $( date +"%m-%d-%Y %H:%M:%S" )" >> $LOG;
      echo "-----------------------------------" >> $LOG;
    }

    # Set selinux context
    selinux_context_s1() {
      chcon -h u:object_r:system_file:s0 "$SYSTEM_APP/FaceLock";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_APP/GoogleCalendarSyncAdapter";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_APP/GoogleContactsSyncAdapter";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_APP/GoogleExtShared";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_APP/FaceLock/FaceLock.apk";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_APP/GoogleCalendarSyncAdapter/GoogleCalendarSyncAdapter.apk";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_APP/GoogleContactsSyncAdapter/GoogleContactsSyncAdapter.apk";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_APP/GoogleExtShared/GoogleExtShared.apk";
      if [ "$AOSP_PKG_INSTALL" == "true" ]; then
        chcon -h u:object_r:system_file:s0 "$SYSTEM_APP/Messaging";
        chcon -h u:object_r:system_file:s0 "$SYSTEM_APP/Messaging/Messaging.apk";
      fi;
    }

    selinux_context_sp2() {
      chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/ConfigUpdater";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/GoogleExtServices";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/GoogleServicesFramework";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/Phonesky";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/PrebuiltGmsCorePi";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/ConfigUpdater/ConfigUpdater.apk";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/GoogleExtServices/GoogleExtServices.apk";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/GoogleServicesFramework/GoogleServicesFramework.apk";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/Phonesky/Phonesky.apk";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/PrebuiltGmsCorePi/PrebuiltGmsCorePi.apk";
      if [ "$AOSP_PKG_INSTALL" == "true" ]; then
        chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/Contacts";
        chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/Dialer";
        chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/ManagedProvisioning";
        chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/Provision";
        chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/Contacts/Contacts.apk";
        chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/Dialer/Dialer.apk";
        chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/ManagedProvisioning/ManagedProvisioning.apk";
        chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/Provision/Provision.apk";
      fi;
    }

    selinux_context_sf3() {
      chcon -h u:object_r:system_file:s0 "$SYSTEM_FRAMEWORK/com.google.android.dialer.support.jar";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_FRAMEWORK/com.google.android.maps.jar";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_FRAMEWORK/com.google.android.media.effects.jar";
    }

    selinux_context_sl4() {
      chcon -h u:object_r:system_lib_file:s0 "$SYSTEM_LIB/libfilterpack_facedetect.so";
      chcon -h u:object_r:system_lib_file:s0 "$SYSTEM_LIB/libfrsdk.so";
    }

    selinux_context_sl5() {
      chcon -h u:object_r:system_lib_file:s0 "$SYSTEM_LIB64/libfacenet.so";
      chcon -h u:object_r:system_lib_file:s0 "$SYSTEM_LIB64/libfilterpack_facedetect.so";
      chcon -h u:object_r:system_lib_file:s0 "$SYSTEM_LIB64/libfrsdk.so";
    }

    selinux_context_se6() {
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_DEFAULT";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_DEFAULT/default-permissions.xml";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_DEFAULT/opengapps-permissions.xml";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_PERM/com.google.android.dialer.support.xml";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_PERM/com.google.android.maps.xml";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_PERM/com.google.android.media.effects.xml";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_PERM/privapp-permissions-google.xml";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_PREF";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_PREF/google.xml";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_CONFIG/dialer_experience.xml";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_CONFIG/google.xml";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_CONFIG/google_build.xml";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_CONFIG/google_exclusives_enable.xml";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_CONFIG/google-hiddenapi-package-whitelist.xml";
      chcon -h u:object_r:system_file:s0 "$SYSTEM/etc/g.prop";
      if [ "$AOSP_PKG_INSTALL" == "true" ]; then
        chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_PERM/com.android.contacts.xml";
        chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_PERM/com.android.dialer.xml";
        chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_PERM/com.android.managedprovisioning.xml";
        chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_PERM/com.android.provision.xml";
      fi;
    }
    # end selinux method

    # APK optimization using zipalign tool
    apk_opt() {
      $ZIPALIGN_TOOL -p -v 4 $SYSTEM_APP/FaceLock/FaceLock.apk $ZIPALIGN_OUTFILE/FaceLock.apk >> $ZIPALIGN_LOG;
      $ZIPALIGN_TOOL -p -v 4 $SYSTEM_APP/GoogleCalendarSyncAdapter/GoogleCalendarSyncAdapter.apk $ZIPALIGN_OUTFILE/GoogleCalendarSyncAdapter.apk >> $ZIPALIGN_LOG;
      $ZIPALIGN_TOOL -p -v 4 $SYSTEM_APP/GoogleContactsSyncAdapter/GoogleContactsSyncAdapter.apk $ZIPALIGN_OUTFILE/GoogleContactsSyncAdapter.apk >> $ZIPALIGN_LOG;
      $ZIPALIGN_TOOL -p -v 4 $SYSTEM_APP/GoogleExtShared/GoogleExtShared.apk $ZIPALIGN_OUTFILE/GoogleExtShared.apk >> $ZIPALIGN_LOG;
      $ZIPALIGN_TOOL -p -v 4 $SYSTEM_PRIV_APP/ConfigUpdater/ConfigUpdater.apk $ZIPALIGN_OUTFILE/ConfigUpdater.apk >> $ZIPALIGN_LOG;
      $ZIPALIGN_TOOL -p -v 4 $SYSTEM_PRIV_APP/GoogleExtServices/GoogleExtServices.apk $ZIPALIGN_OUTFILE/GoogleExtServices.apk >> $ZIPALIGN_LOG;
      $ZIPALIGN_TOOL -p -v 4 $SYSTEM_PRIV_APP/GoogleServicesFramework/GoogleServicesFramework.apk $ZIPALIGN_OUTFILE/GoogleServicesFramework.apk >> $ZIPALIGN_LOG;
      $ZIPALIGN_TOOL -p -v 4 $SYSTEM_PRIV_APP/Phonesky/Phonesky.apk $ZIPALIGN_OUTFILE/Phonesky.apk >> $ZIPALIGN_LOG;
      $ZIPALIGN_TOOL -p -v 4 $SYSTEM_PRIV_APP/PrebuiltGmsCorePi/PrebuiltGmsCorePi.apk $ZIPALIGN_OUTFILE/PrebuiltGmsCorePi.apk >> $ZIPALIGN_LOG;
      if [ "$AOSP_PKG_INSTALL" == "true" ]; then
        $ZIPALIGN_TOOL -p -v 4 $SYSTEM_APP/Messaging/Messaging.apk $ZIPALIGN_OUTFILE/Messaging.apk >> $ZIPALIGN_LOG;
        $ZIPALIGN_TOOL -p -v 4 $SYSTEM_PRIV_APP/Contacts/Contacts.apk $ZIPALIGN_OUTFILE/Contacts.apk >> $ZIPALIGN_LOG;
        $ZIPALIGN_TOOL -p -v 4 $SYSTEM_PRIV_APP/Dialer/Dialer.apk $ZIPALIGN_OUTFILE/Dialer.apk >> $ZIPALIGN_LOG;
        $ZIPALIGN_TOOL -p -v 4 $SYSTEM_PRIV_APP/ManagedProvisioning/ManagedProvisioning.apk $ZIPALIGN_OUTFILE/ManagedProvisioning.apk >> $ZIPALIGN_LOG;
        $ZIPALIGN_TOOL -p -v 4 $SYSTEM_PRIV_APP/Provision/Provision.apk $ZIPALIGN_OUTFILE/Provision.apk >> $ZIPALIGN_LOG;
      fi;
    }

    pre_opt() {
      rm -rf $SYSTEM_APP/FaceLock/FaceLock.apk
      rm -rf $SYSTEM_APP/GoogleCalendarSyncAdapter/GoogleCalendarSyncAdapter.apk
      rm -rf $SYSTEM_APP/GoogleContactsSyncAdapter/GoogleContactsSyncAdapter.apk
      rm -rf $SYSTEM_APP/GoogleExtShared/GoogleExtShared.apk
      rm -rf $SYSTEM_PRIV_APP/ConfigUpdater/ConfigUpdater.apk
      rm -rf $SYSTEM_PRIV_APP/GoogleExtServices/GoogleExtServices.apk
      rm -rf $SYSTEM_PRIV_APP/GoogleServicesFramework/GoogleServicesFramework.apk
      rm -rf $SYSTEM_PRIV_APP/Phonesky/Phonesky.apk
      rm -rf $SYSTEM_PRIV_APP/PrebuiltGmsCorePi/PrebuiltGmsCorePi.apk
      if [ "$AOSP_PKG_INSTALL" == "true" ]; then
        rm -rf $SYSTEM_APP/Messaging/Messaging.apk
        rm -rf $SYSTEM_PRIV_APP/Contacts/Contacts.apk
        rm -rf $SYSTEM_PRIV_APP/Dialer/Dialer.apk
        rm -rf $SYSTEM_PRIV_APP/ManagedProvisioning/ManagedProvisioning.apk
        rm -rf $SYSTEM_PRIV_APP/Provision/Provision.apk
      fi;
    }

    add_opt() {
      cp -f $ZIPALIGN_OUTFILE/FaceLock.apk $SYSTEM_APP/FaceLock/FaceLock.apk
      cp -f $ZIPALIGN_OUTFILE/GoogleCalendarSyncAdapter.apk $SYSTEM_APP/GoogleCalendarSyncAdapter/GoogleCalendarSyncAdapter.apk
      cp -f $ZIPALIGN_OUTFILE/GoogleContactsSyncAdapter.apk $SYSTEM_APP/GoogleContactsSyncAdapter/GoogleContactsSyncAdapter.apk
      cp -f $ZIPALIGN_OUTFILE/GoogleExtShared.apk $SYSTEM_APP/GoogleExtShared/GoogleExtShared.apk
      cp -f $ZIPALIGN_OUTFILE/ConfigUpdater.apk $SYSTEM_PRIV_APP/ConfigUpdater/ConfigUpdater.apk
      cp -f $ZIPALIGN_OUTFILE/GoogleExtServices.apk $SYSTEM_PRIV_APP/GoogleExtServices/GoogleExtServices.apk
      cp -f $ZIPALIGN_OUTFILE/GoogleServicesFramework.apk $SYSTEM_PRIV_APP/GoogleServicesFramework/GoogleServicesFramework.apk
      cp -f $ZIPALIGN_OUTFILE/Phonesky.apk $SYSTEM_PRIV_APP/Phonesky/Phonesky.apk
      cp -f $ZIPALIGN_OUTFILE/PrebuiltGmsCorePi.apk $SYSTEM_PRIV_APP/PrebuiltGmsCorePi/PrebuiltGmsCorePi.apk
      if [ "$AOSP_PKG_INSTALL" == "true" ]; then
        cp -f $ZIPALIGN_OUTFILE/Messaging.apk $SYSTEM_APP/Messaging/Messaging.apk
        cp -f $ZIPALIGN_OUTFILE/Contacts.apk $SYSTEM_PRIV_APP/Contacts/Contacts.apk
        cp -f $ZIPALIGN_OUTFILE/Dialer.apk $SYSTEM_PRIV_APP/Dialer/Dialer.apk
        cp -f $ZIPALIGN_OUTFILE/ManagedProvisioning.apk $SYSTEM_PRIV_APP/ManagedProvisioning/ManagedProvisioning.apk
        cp -f $ZIPALIGN_OUTFILE/Provision.apk $SYSTEM_PRIV_APP/Provision/Provision.apk
      fi;
    }

    perm_opt() {
      chmod 0644 $SYSTEM_APP/FaceLock/FaceLock.apk
      chmod 0644 $SYSTEM_APP/GoogleCalendarSyncAdapter/GoogleCalendarSyncAdapter.apk
      chmod 0644 $SYSTEM_APP/GoogleContactsSyncAdapter/GoogleContactsSyncAdapter.apk
      chmod 0644 $SYSTEM_APP/GoogleExtShared/GoogleExtShared.apk
      chmod 0644 $SYSTEM_PRIV_APP/ConfigUpdater/ConfigUpdater.apk
      chmod 0644 $SYSTEM_PRIV_APP/GoogleExtServices/GoogleExtServices.apk
      chmod 0644 $SYSTEM_PRIV_APP/GoogleServicesFramework/GoogleServicesFramework.apk
      chmod 0644 $SYSTEM_PRIV_APP/Phonesky/Phonesky.apk
      chmod 0644 $SYSTEM_PRIV_APP/PrebuiltGmsCorePi/PrebuiltGmsCorePi.apk
      if [ "$AOSP_PKG_INSTALL" == "true" ]; then
        chmod 0644 $SYSTEM_APP/Messaging/Messaging.apk
        chmod 0644 $SYSTEM_PRIV_APP/Contacts/Contacts.apk
        chmod 0644 $SYSTEM_PRIV_APP/Dialer/Dialer.apk
        chmod 0644 $SYSTEM_PRIV_APP/ManagedProvisioning/ManagedProvisioning.apk
        chmod 0644 $SYSTEM_PRIV_APP/Provision/Provision.apk
      fi;
    }
    # end opt method

    # execute installation functions
    sdk_v28() {
      extract_app;
      set_sparse;
      selinux_context_s1;
      selinux_context_sp2;
      selinux_context_sf3;
      selinux_context_sl4;
      selinux_context_sl5;
      selinux_context_se6;
      apk_opt;
      pre_opt;
      add_opt;
      perm_opt;
      # Re-run selinux functions for optimized APKs
      selinux_context_s1;
      selinux_context_sp2;
      # end selinux functions
    }
    sdk_v28;
    # Print installed files to sdk log
    cat $LOG >> $sdk_v28;
  else
    echo "Target Android SDK Version : $android_sdk" >> $sdk_v28;
  fi;
}

# Set installation functions for Android SDK 27
sdk_v27_install() {
  if [ "$android_sdk" == "$supported_sdk_v27" ]; then
    # Set default packages
    ZIP="
      zip/core/priv_app_ConfigUpdater.tar.xz
      zip/core/priv_app_GoogleExtServices.tar.xz
      zip/core/priv_app_GoogleServicesFramework.tar.xz
      zip/core/priv_app_Phonesky.tar.xz
      zip/core/priv_app_PrebuiltGmsCorePix.tar.xz
      zip/sys/sys_app_FaceLock.tar.xz
      zip/sys/sys_app_GoogleCalendarSyncAdapter.tar.xz
      zip/sys/sys_app_GoogleContactsSyncAdapter.tar.xz
      zip/sys/sys_app_GoogleExtShared.tar.xz
      zip/sys_Config_Permission.tar.xz
      zip/sys_Default_Permission.tar.xz
      zip/sys_Framework.tar.xz
      zip/sys_Permissions.tar.xz
      zip/sys_Pref_Permission.tar.xz
      zip/facelock_lib32.tar.xz
      zip/facelock_lib64.tar.xz";

    # Unzip system files from installer
    unpack_zip;

    if [ "$AOSP_PKG_INSTALL" == "true" ]; then
      ZIP="
        zip/core/aosp/priv_app_Contacts.tar.xz
        zip/core/aosp/priv_app_Dialer.tar.xz
        zip/core/aosp/priv_app_ManagedProvisioning.tar.xz
        zip/core/aosp/priv_app_Provision.tar.xz
        zip/sys/aosp/sys_app_Messaging.tar.xz
        zip/sys_Permissions_AOSP.tar.xz";

      # Re-define unzip function for AOSP apps with similar target
      unpack_zip;
    fi;

    # Unpack system files
    extract_app() {
      echo "-----------------------------------" >> $LOG;
      echo "- Unpack SYS-APP Files" >> $LOG;
      tar tvf $ZIP_FILE/sys/sys_app_FaceLock.tar.xz >> $LOG;
      tar tvf $ZIP_FILE/sys/sys_app_GoogleCalendarSyncAdapter.tar.xz >> $LOG;
      tar tvf $ZIP_FILE/sys/sys_app_GoogleContactsSyncAdapter.tar.xz >> $LOG;
      tar tvf $ZIP_FILE/sys/sys_app_GoogleExtShared.tar.xz >> $LOG;
      tar -xf $ZIP_FILE/sys/sys_app_FaceLock.tar.xz -C $TMP_SYS;
      tar -xf $ZIP_FILE/sys/sys_app_GoogleCalendarSyncAdapter.tar.xz -C $TMP_SYS;
      tar -xf $ZIP_FILE/sys/sys_app_GoogleContactsSyncAdapter.tar.xz -C $TMP_SYS;
      tar -xf $ZIP_FILE/sys/sys_app_GoogleExtShared.tar.xz -C $TMP_SYS;
      if [ "$AOSP_PKG_INSTALL" == "true" ]; then
        tar tvf $ZIP_FILE/sys/aosp/sys_app_Messaging.tar.xz >> $LOG;
        tar -xf $ZIP_FILE/sys/aosp/sys_app_Messaging.tar.xz -C $TMP_SYS_AOSP;
      fi;
      echo "- Done" >> $LOG;
      echo "-----------------------------------" >> $LOG;
      echo "- Unpack PRIV-APP Files" >> $LOG;
      tar tvf $ZIP_FILE/core/priv_app_ConfigUpdater.tar.xz >> $LOG;
      tar tvf $ZIP_FILE/core/priv_app_GoogleExtServices.tar.xz >> $LOG;
      tar tvf $ZIP_FILE/core/priv_app_GoogleServicesFramework.tar.xz >> $LOG;
      tar tvf $ZIP_FILE/core/priv_app_Phonesky.tar.xz >> $LOG;
      tar tvf $ZIP_FILE/core/priv_app_PrebuiltGmsCorePix.tar.xz >> $LOG;
      tar -xf $ZIP_FILE/core/priv_app_ConfigUpdater.tar.xz -C $TMP_PRIV;
      tar -xf $ZIP_FILE/core/priv_app_GoogleExtServices.tar.xz -C $TMP_PRIV;
      tar -xf $ZIP_FILE/core/priv_app_GoogleServicesFramework.tar.xz -C $TMP_PRIV;
      tar -xf $ZIP_FILE/core/priv_app_Phonesky.tar.xz -C $TMP_PRIV;
      tar -xf $ZIP_FILE/core/priv_app_PrebuiltGmsCorePix.tar.xz -C $TMP_PRIV;
      if [ "$AOSP_PKG_INSTALL" == "true" ]; then
        tar tvf $ZIP_FILE/core/aosp/priv_app_Contacts.tar.xz >> $LOG;
        tar tvf $ZIP_FILE/core/aosp/priv_app_Dialer.tar.xz >> $LOG;
        tar tvf $ZIP_FILE/core/aosp/priv_app_ManagedProvisioning.tar.xz >> $LOG;
        tar tvf $ZIP_FILE/core/aosp/priv_app_Provision.tar.xz >> $LOG;
        tar -xf $ZIP_FILE/core/aosp/priv_app_Contacts.tar.xz -C $TMP_PRIV_AOSP;
        tar -xf $ZIP_FILE/core/aosp/priv_app_Dialer.tar.xz -C $TMP_PRIV_AOSP;
        tar -xf $ZIP_FILE/core/aosp/priv_app_ManagedProvisioning.tar.xz -C $TMP_PRIV_AOSP;
        tar -xf $ZIP_FILE/core/aosp/priv_app_Provision.tar.xz -C $TMP_PRIV_AOSP;
      fi;
      echo "- Done" >> $LOG;
      echo "-----------------------------------" >> $LOG;
      echo "- Unpack Framework Files" >> $LOG;
      tar tvf $ZIP_FILE/sys_Framework.tar.xz >> $LOG;
      tar -xf $ZIP_FILE/sys_Framework.tar.xz -C $TMP_FRAMEWORK;
      echo "- Done" >> $LOG;
      echo "-----------------------------------" >> $LOG;
      echo "- Unpack System Lib" >> $LOG;
      tar tvf $ZIP_FILE/facelock_lib32.tar.xz >> $LOG;
      tar -xf $ZIP_FILE/facelock_lib32.tar.xz -C $TMP_LIB;
      echo "- Done" >> $LOG;
      echo "-----------------------------------" >> $LOG;
      echo "- Unpack System Lib64" >> $LOG;
      tar tvf $ZIP_FILE/facelock_lib64.tar.xz >> $LOG;
      tar -xf $ZIP_FILE/facelock_lib64.tar.xz -C $TMP_LIB64;
      echo "- Done" >> $LOG;
      echo "-----------------------------------" >> $LOG;
      echo "- Unpack System Files" >> $LOG;
      tar tvf $ZIP_FILE/sys_Config_Permission.tar.xz >> $LOG;
      tar tvf $ZIP_FILE/sys_Default_Permission.tar.xz >> $LOG;
      tar tvf $ZIP_FILE/sys_Permissions.tar.xz >> $LOG;
      tar tvf $ZIP_FILE/sys_Pref_Permission.tar.xz >> $LOG;
      tar -xf $ZIP_FILE/sys_Config_Permission.tar.xz -C $TMP_CONFIG;
      tar -xf $ZIP_FILE/sys_Default_Permission.tar.xz -C $TMP_DEFAULT_PERM;
      tar -xf $ZIP_FILE/sys_Permissions.tar.xz -C $TMP_G_PERM;
      tar -xf $ZIP_FILE/sys_Pref_Permission.tar.xz -C $TMP_G_PREF;
      if [ "$AOSP_PKG_INSTALL" == "true" ]; then
        tar tvf $ZIP_FILE/sys_Permissions_AOSP.tar.xz >> $LOG;
        tar -xf $ZIP_FILE/sys_Permissions_AOSP.tar.xz -C $TMP_G_PERM_AOSP;
      fi;
      echo "- Done" >> $LOG;
      echo "-----------------------------------" >> $LOG;
      echo "- Installation Complete" >> $LOG;
      echo "-----------------------------------" >> $LOG;
      echo "Finish at $( date +"%m-%d-%Y %H:%M:%S" )" >> $LOG;
      echo "-----------------------------------" >> $LOG;
    }

    # Set selinux context
    selinux_context_s1() {
      chcon -h u:object_r:system_file:s0 "$SYSTEM_APP/FaceLock";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_APP/GoogleCalendarSyncAdapter";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_APP/GoogleContactsSyncAdapter";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_APP/GoogleExtShared";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_APP/FaceLock/FaceLock.apk";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_APP/GoogleCalendarSyncAdapter/GoogleCalendarSyncAdapter.apk";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_APP/GoogleContactsSyncAdapter/GoogleContactsSyncAdapter.apk";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_APP/GoogleExtShared/GoogleExtShared.apk";
      if [ "$AOSP_PKG_INSTALL" == "true" ]; then
        chcon -h u:object_r:system_file:s0 "$SYSTEM_APP/Messaging";
        chcon -h u:object_r:system_file:s0 "$SYSTEM_APP/Messaging/Messaging.apk";
      fi;
    }

    selinux_context_sp2() {
      chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/ConfigUpdater";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/GoogleExtServices";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/GoogleServicesFramework";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/Phonesky";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/PrebuiltGmsCorePix";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/ConfigUpdater/ConfigUpdater.apk";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/GoogleExtServices/GoogleExtServices.apk";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/GoogleServicesFramework/GoogleServicesFramework.apk";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/Phonesky/Phonesky.apk";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/PrebuiltGmsCorePix/PrebuiltGmsCorePix.apk";
      if [ "$AOSP_PKG_INSTALL" == "true" ]; then
        chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/Contacts";
        chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/Dialer";
        chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/ManagedProvisioning";
        chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/Provision";
        chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/Contacts/Contacts.apk";
        chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/Dialer/Dialer.apk";
        chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/ManagedProvisioning/ManagedProvisioning.apk";
        chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/Provision/Provision.apk";
      fi;
    }

    selinux_context_sf3() {
      chcon -h u:object_r:system_file:s0 "$SYSTEM_FRAMEWORK/com.google.android.dialer.support.jar";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_FRAMEWORK/com.google.android.maps.jar";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_FRAMEWORK/com.google.android.media.effects.jar";
    }

    selinux_context_sl4() {
      chcon -h u:object_r:system_lib_file:s0 "$SYSTEM_LIB/libfilterpack_facedetect.so";
      chcon -h u:object_r:system_lib_file:s0 "$SYSTEM_LIB/libfrsdk.so";
    }

    selinux_context_sl5() {
      chcon -h u:object_r:system_lib_file:s0 "$SYSTEM_LIB64/libfacenet.so";
      chcon -h u:object_r:system_lib_file:s0 "$SYSTEM_LIB64/libfilterpack_facedetect.so";
      chcon -h u:object_r:system_lib_file:s0 "$SYSTEM_LIB64/libfrsdk.so";
    }

    selinux_context_se6() {
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_DEFAULT";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_DEFAULT/default-permissions.xml";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_DEFAULT/opengapps-permissions.xml";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_PERM/com.google.android.dialer.support.xml";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_PERM/com.google.android.maps.xml";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_PERM/com.google.android.media.effects.xml";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_PERM/privapp-permissions-google.xml";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_PREF";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_PREF/google.xml";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_CONFIG/dialer_experience.xml";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_CONFIG/google.xml";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_CONFIG/google_build.xml";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_CONFIG/google_exclusives_enable.xml";
      chcon -h u:object_r:system_file:s0 "$SYSTEM/etc/g.prop";
      if [ "$AOSP_PKG_INSTALL" == "true" ]; then
        chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_PERM/com.android.contacts.xml";
        chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_PERM/com.android.dialer.xml";
        chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_PERM/com.android.managedprovisioning.xml";
        chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_PERM/com.android.provision.xml";
      fi;
    }
    # end selinux method

    # Create FaceLock lib symlink
    bind_facelock_lib() {
      ln -sfnv $SYSTEM/lib64/libfacenet.so $SYSTEM/app/FaceLock/lib/arm64/libfacenet.so >> $LINKER;
      rm -rf $SYSTEM/app/FaceLock/lib/arm64/placeholder
    }

    # APK optimization using zipalign tool
    apk_opt() {
      $ZIPALIGN_TOOL -p -v 4 $SYSTEM_APP/FaceLock/FaceLock.apk $ZIPALIGN_OUTFILE/FaceLock.apk >> $ZIPALIGN_LOG;
      $ZIPALIGN_TOOL -p -v 4 $SYSTEM_APP/GoogleCalendarSyncAdapter/GoogleCalendarSyncAdapter.apk $ZIPALIGN_OUTFILE/GoogleCalendarSyncAdapter.apk >> $ZIPALIGN_LOG;
      $ZIPALIGN_TOOL -p -v 4 $SYSTEM_APP/GoogleContactsSyncAdapter/GoogleContactsSyncAdapter.apk $ZIPALIGN_OUTFILE/GoogleContactsSyncAdapter.apk >> $ZIPALIGN_LOG;
      $ZIPALIGN_TOOL -p -v 4 $SYSTEM_APP/GoogleExtShared/GoogleExtShared.apk $ZIPALIGN_OUTFILE/GoogleExtShared.apk >> $ZIPALIGN_LOG;
      $ZIPALIGN_TOOL -p -v 4 $SYSTEM_PRIV_APP/ConfigUpdater/ConfigUpdater.apk $ZIPALIGN_OUTFILE/ConfigUpdater.apk >> $ZIPALIGN_LOG;
      $ZIPALIGN_TOOL -p -v 4 $SYSTEM_PRIV_APP/GoogleExtServices/GoogleExtServices.apk $ZIPALIGN_OUTFILE/GoogleExtServices.apk >> $ZIPALIGN_LOG;
      $ZIPALIGN_TOOL -p -v 4 $SYSTEM_PRIV_APP/GoogleServicesFramework/GoogleServicesFramework.apk $ZIPALIGN_OUTFILE/GoogleServicesFramework.apk >> $ZIPALIGN_LOG;
      $ZIPALIGN_TOOL -p -v 4 $SYSTEM_PRIV_APP/Phonesky/Phonesky.apk $ZIPALIGN_OUTFILE/Phonesky.apk >> $ZIPALIGN_LOG;
      $ZIPALIGN_TOOL -p -v 4 $SYSTEM_PRIV_APP/PrebuiltGmsCorePix/PrebuiltGmsCorePix.apk $ZIPALIGN_OUTFILE/PrebuiltGmsCorePix.apk >> $ZIPALIGN_LOG;
      if [ "$AOSP_PKG_INSTALL" == "true" ]; then
        $ZIPALIGN_TOOL -p -v 4 $SYSTEM_APP/Messaging/Messaging.apk $ZIPALIGN_OUTFILE/Messaging.apk >> $ZIPALIGN_LOG;
        $ZIPALIGN_TOOL -p -v 4 $SYSTEM_PRIV_APP/Contacts/Contacts.apk $ZIPALIGN_OUTFILE/Contacts.apk >> $ZIPALIGN_LOG;
        $ZIPALIGN_TOOL -p -v 4 $SYSTEM_PRIV_APP/Dialer/Dialer.apk $ZIPALIGN_OUTFILE/Dialer.apk >> $ZIPALIGN_LOG;
        $ZIPALIGN_TOOL -p -v 4 $SYSTEM_PRIV_APP/ManagedProvisioning/ManagedProvisioning.apk $ZIPALIGN_OUTFILE/ManagedProvisioning.apk >> $ZIPALIGN_LOG;
        $ZIPALIGN_TOOL -p -v 4 $SYSTEM_PRIV_APP/Provision/Provision.apk $ZIPALIGN_OUTFILE/Provision.apk >> $ZIPALIGN_LOG;
      fi;
    }

    pre_opt() {
      rm -rf $SYSTEM_APP/FaceLock/FaceLock.apk
      rm -rf $SYSTEM_APP/GoogleCalendarSyncAdapter/GoogleCalendarSyncAdapter.apk
      rm -rf $SYSTEM_APP/GoogleContactsSyncAdapter/GoogleContactsSyncAdapter.apk
      rm -rf $SYSTEM_APP/GoogleExtShared/GoogleExtShared.apk
      rm -rf $SYSTEM_PRIV_APP/ConfigUpdater/ConfigUpdater.apk
      rm -rf $SYSTEM_PRIV_APP/GoogleExtServices/GoogleExtServices.apk
      rm -rf $SYSTEM_PRIV_APP/GoogleServicesFramework/GoogleServicesFramework.apk
      rm -rf $SYSTEM_PRIV_APP/Phonesky/Phonesky.apk
      rm -rf $SYSTEM_PRIV_APP/PrebuiltGmsCorePix/PrebuiltGmsCorePix.apk
      if [ "$AOSP_PKG_INSTALL" == "true" ]; then
        rm -rf $SYSTEM_APP/Messaging/Messaging.apk
        rm -rf $SYSTEM_PRIV_APP/Contacts/Contacts.apk
        rm -rf $SYSTEM_PRIV_APP/Dialer/Dialer.apk
        rm -rf $SYSTEM_PRIV_APP/ManagedProvisioning/ManagedProvisioning.apk
        rm -rf $SYSTEM_PRIV_APP/Provision/Provision.apk
      fi;
    }

    add_opt() {
      cp -f $ZIPALIGN_OUTFILE/FaceLock.apk $SYSTEM_APP/FaceLock/FaceLock.apk
      cp -f $ZIPALIGN_OUTFILE/GoogleCalendarSyncAdapter.apk $SYSTEM_APP/GoogleCalendarSyncAdapter/GoogleCalendarSyncAdapter.apk
      cp -f $ZIPALIGN_OUTFILE/GoogleContactsSyncAdapter.apk $SYSTEM_APP/GoogleContactsSyncAdapter/GoogleContactsSyncAdapter.apk
      cp -f $ZIPALIGN_OUTFILE/GoogleExtShared.apk $SYSTEM_APP/GoogleExtShared/GoogleExtShared.apk
      cp -f $ZIPALIGN_OUTFILE/ConfigUpdater.apk $SYSTEM_PRIV_APP/ConfigUpdater/ConfigUpdater.apk
      cp -f $ZIPALIGN_OUTFILE/GoogleExtServices.apk $SYSTEM_PRIV_APP/GoogleExtServices/GoogleExtServices.apk
      cp -f $ZIPALIGN_OUTFILE/GoogleServicesFramework.apk $SYSTEM_PRIV_APP/GoogleServicesFramework/GoogleServicesFramework.apk
      cp -f $ZIPALIGN_OUTFILE/Phonesky.apk $SYSTEM_PRIV_APP/Phonesky/Phonesky.apk
      cp -f $ZIPALIGN_OUTFILE/PrebuiltGmsCorePix.apk $SYSTEM_PRIV_APP/PrebuiltGmsCorePix/PrebuiltGmsCorePix.apk
      if [ "$AOSP_PKG_INSTALL" == "true" ]; then
        cp -f $ZIPALIGN_OUTFILE/Messaging.apk $SYSTEM_APP/Messaging/Messaging.apk
        cp -f $ZIPALIGN_OUTFILE/Contacts.apk $SYSTEM_PRIV_APP/Contacts/Contacts.apk
        cp -f $ZIPALIGN_OUTFILE/Dialer.apk $SYSTEM_PRIV_APP/Dialer/Dialer.apk
        cp -f $ZIPALIGN_OUTFILE/ManagedProvisioning.apk $SYSTEM_PRIV_APP/ManagedProvisioning/ManagedProvisioning.apk
        cp -f $ZIPALIGN_OUTFILE/Provision.apk $SYSTEM_PRIV_APP/Provision/Provision.apk
      fi;
    }

    perm_opt() {
      chmod 0644 $SYSTEM_APP/FaceLock/FaceLock.apk
      chmod 0644 $SYSTEM_APP/GoogleCalendarSyncAdapter/GoogleCalendarSyncAdapter.apk
      chmod 0644 $SYSTEM_APP/GoogleContactsSyncAdapter/GoogleContactsSyncAdapter.apk
      chmod 0644 $SYSTEM_APP/GoogleExtShared/GoogleExtShared.apk
      chmod 0644 $SYSTEM_PRIV_APP/ConfigUpdater/ConfigUpdater.apk
      chmod 0644 $SYSTEM_PRIV_APP/GoogleExtServices/GoogleExtServices.apk
      chmod 0644 $SYSTEM_PRIV_APP/GoogleServicesFramework/GoogleServicesFramework.apk
      chmod 0644 $SYSTEM_PRIV_APP/Phonesky/Phonesky.apk
      chmod 0644 $SYSTEM_PRIV_APP/PrebuiltGmsCorePix/PrebuiltGmsCorePix.apk
      if [ "$AOSP_PKG_INSTALL" == "true" ]; then
        chmod 0644 $SYSTEM_APP/Messaging/Messaging.apk
        chmod 0644 $SYSTEM_PRIV_APP/Contacts/Contacts.apk
        chmod 0644 $SYSTEM_PRIV_APP/Dialer/Dialer.apk
        chmod 0644 $SYSTEM_PRIV_APP/ManagedProvisioning/ManagedProvisioning.apk
        chmod 0644 $SYSTEM_PRIV_APP/Provision/Provision.apk
      fi;
    }
    # end opt method

    # execute installation functions
    sdk_v27() {
      extract_app;
      set_sparse;
      selinux_context_s1;
      selinux_context_sp2;
      selinux_context_sf3;
      selinux_context_sl4;
      selinux_context_sl5;
      selinux_context_se6;
      bind_facelock_lib;
      apk_opt;
      pre_opt;
      add_opt;
      perm_opt;
      # Re-run selinux functions for optimized APKs
      selinux_context_s1;
      selinux_context_sp2;
      # end selinux functions
    }
    sdk_v27;
    # Print installed files to sdk log
    cat $LOG >> $sdk_v27;
  else
    echo "Target Android SDK Version : $android_sdk" >> $sdk_v27;
  fi;
}

# Set installation functions for Android SDK 25
sdk_v25_install() {
  if [ "$android_sdk" == "$supported_sdk_v25" ]; then
    # Set default packages
    ZIP="
      zip/core/priv_app_ConfigUpdater.tar.xz
      zip/core/priv_app_GoogleExtServices.tar.xz
      zip/core/priv_app_GoogleLoginService.tar.xz
      zip/core/priv_app_GoogleServicesFramework.tar.xz
      zip/core/priv_app_Phonesky.tar.xz
      zip/core/priv_app_PrebuiltGmsCore.tar.xz
      zip/sys/sys_app_FaceLock.tar.xz
      zip/sys/sys_app_GoogleCalendarSyncAdapter.tar.xz
      zip/sys/sys_app_GoogleContactsSyncAdapter.tar.xz
      zip/sys/sys_app_GoogleExtShared.tar.xz
      zip/sys_Config_Permission.tar.xz
      zip/sys_Default_Permission.tar.xz
      zip/sys_Framework.tar.xz
      zip/sys_Permissions.tar.xz
      zip/sys_Pref_Permission.tar.xz
      zip/facelock_lib32.tar.xz
      zip/facelock_lib64.tar.xz";

    # Unzip system files from installer
    unpack_zip;

    if [ "$AOSP_PKG_INSTALL" == "true" ]; then
      ZIP="
        zip/core/aosp/priv_app_Contacts.tar.xz
        zip/core/aosp/priv_app_Dialer.tar.xz
        zip/core/aosp/priv_app_ManagedProvisioning.tar.xz
        zip/core/aosp/priv_app_Provision.tar.xz
        zip/sys/aosp/sys_app_Messaging.tar.xz
        zip/sys_Permissions_AOSP.tar.xz";

      # Re-define unzip function for AOSP apps with similar target
      unpack_zip;
    fi;

    # Unpack system files
    extract_app() {
      echo "-----------------------------------" >> $LOG;
      echo "- Unpack SYS-APP Files" >> $LOG;
      tar tvf $ZIP_FILE/sys/sys_app_FaceLock.tar.xz >> $LOG;
      tar tvf $ZIP_FILE/sys/sys_app_GoogleCalendarSyncAdapter.tar.xz >> $LOG;
      tar tvf $ZIP_FILE/sys/sys_app_GoogleContactsSyncAdapter.tar.xz >> $LOG;
      tar tvf $ZIP_FILE/sys/sys_app_GoogleExtShared.tar.xz >> $LOG;
      tar -xf $ZIP_FILE/sys/sys_app_FaceLock.tar.xz -C $TMP_SYS;
      tar -xf $ZIP_FILE/sys/sys_app_GoogleCalendarSyncAdapter.tar.xz -C $TMP_SYS;
      tar -xf $ZIP_FILE/sys/sys_app_GoogleContactsSyncAdapter.tar.xz -C $TMP_SYS;
      tar -xf $ZIP_FILE/sys/sys_app_GoogleExtShared.tar.xz -C $TMP_SYS;
      if [ "$AOSP_PKG_INSTALL" == "true" ]; then
        tar tvf $ZIP_FILE/sys/aosp/sys_app_Messaging.tar.xz >> $LOG;
        tar -xf $ZIP_FILE/sys/aosp/sys_app_Messaging.tar.xz -C $TMP_SYS_AOSP;
      fi;
      echo "- Done" >> $LOG;
      echo "-----------------------------------" >> $LOG;
      echo "- Unpack PRIV-APP Files" >> $LOG;
      tar tvf $ZIP_FILE/core/priv_app_ConfigUpdater.tar.xz >> $LOG;
      tar tvf $ZIP_FILE/core/priv_app_GoogleExtServices.tar.xz >> $LOG;
      tar tvf $ZIP_FILE/core/priv_app_GoogleLoginService.tar.xz >> $LOG;
      tar tvf $ZIP_FILE/core/priv_app_GoogleServicesFramework.tar.xz >> $LOG;
      tar tvf $ZIP_FILE/core/priv_app_Phonesky.tar.xz >> $LOG;
      tar tvf $ZIP_FILE/core/priv_app_PrebuiltGmsCore.tar.xz >> $LOG;
      tar -xf $ZIP_FILE/core/priv_app_ConfigUpdater.tar.xz -C $TMP_PRIV;
      tar -xf $ZIP_FILE/core/priv_app_GoogleExtServices.tar.xz -C $TMP_PRIV;
      tar -xf $ZIP_FILE/core/priv_app_GoogleLoginService.tar.xz -C $TMP_PRIV;
      tar -xf $ZIP_FILE/core/priv_app_GoogleServicesFramework.tar.xz -C $TMP_PRIV;
      tar -xf $ZIP_FILE/core/priv_app_Phonesky.tar.xz -C $TMP_PRIV;
      tar -xf $ZIP_FILE/core/priv_app_PrebuiltGmsCore.tar.xz -C $TMP_PRIV;
      if [ "$AOSP_PKG_INSTALL" == "true" ]; then
        tar tvf $ZIP_FILE/core/aosp/priv_app_Contacts.tar.xz >> $LOG;
        tar tvf $ZIP_FILE/core/aosp/priv_app_Dialer.tar.xz >> $LOG;
        tar tvf $ZIP_FILE/core/aosp/priv_app_ManagedProvisioning.tar.xz >> $LOG;
        tar tvf $ZIP_FILE/core/aosp/priv_app_Provision.tar.xz >> $LOG;
        tar -xf $ZIP_FILE/core/aosp/priv_app_Contacts.tar.xz -C $TMP_PRIV_AOSP;
        tar -xf $ZIP_FILE/core/aosp/priv_app_Dialer.tar.xz -C $TMP_PRIV_AOSP;
        tar -xf $ZIP_FILE/core/aosp/priv_app_ManagedProvisioning.tar.xz -C $TMP_PRIV_AOSP;
        tar -xf $ZIP_FILE/core/aosp/priv_app_Provision.tar.xz -C $TMP_PRIV_AOSP;
      fi;
      echo "- Done" >> $LOG;
      echo "-----------------------------------" >> $LOG;
      echo "- Unpack Framework Files" >> $LOG;
      tar tvf $ZIP_FILE/sys_Framework.tar.xz >> $LOG;
      tar -xf $ZIP_FILE/sys_Framework.tar.xz -C $TMP_FRAMEWORK;
      echo "- Done" >> $LOG;
      echo "-----------------------------------" >> $LOG;
      echo "- Unpack System Lib" >> $LOG;
      tar tvf $ZIP_FILE/facelock_lib32.tar.xz >> $LOG;
      tar -xf $ZIP_FILE/facelock_lib32.tar.xz -C $TMP_LIB;
      echo "- Done" >> $LOG;
      echo "-----------------------------------" >> $LOG;
      echo "- Unpack System Lib64" >> $LOG;
      tar tvf $ZIP_FILE/facelock_lib64.tar.xz >> $LOG;
      tar -xf $ZIP_FILE/facelock_lib64.tar.xz -C $TMP_LIB64;
      echo "- Done" >> $LOG;
      echo "-----------------------------------" >> $LOG;
      echo "- Unpack System Files" >> $LOG;
      tar tvf $ZIP_FILE/sys_Config_Permission.tar.xz >> $LOG;
      tar tvf $ZIP_FILE/sys_Default_Permission.tar.xz >> $LOG;
      tar tvf $ZIP_FILE/sys_Permissions.tar.xz >> $LOG;
      tar tvf $ZIP_FILE/sys_Pref_Permission.tar.xz >> $LOG;
      tar -xf $ZIP_FILE/sys_Config_Permission.tar.xz -C $TMP_CONFIG;
      tar -xf $ZIP_FILE/sys_Default_Permission.tar.xz -C $TMP_DEFAULT_PERM;
      tar -xf $ZIP_FILE/sys_Permissions.tar.xz -C $TMP_G_PERM;
      tar -xf $ZIP_FILE/sys_Pref_Permission.tar.xz -C $TMP_G_PREF;
      if [ "$AOSP_PKG_INSTALL" == "true" ]; then
        tar tvf $ZIP_FILE/sys_Permissions_AOSP.tar.xz >> $LOG;
        tar -xf $ZIP_FILE/sys_Permissions_AOSP.tar.xz -C $TMP_G_PERM_AOSP;
      fi;
      echo "- Done" >> $LOG;
      echo "-----------------------------------" >> $LOG;
      echo "- Installation Complete" >> $LOG;
      echo "-----------------------------------" >> $LOG;
      echo "Finish at $( date +"%m-%d-%Y %H:%M:%S" )" >> $LOG;
      echo "-----------------------------------" >> $LOG;
    }

    # Set selinux context
    selinux_context_s1() {
      chcon -h u:object_r:system_file:s0 "$SYSTEM_APP/FaceLock";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_APP/GoogleCalendarSyncAdapter";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_APP/GoogleContactsSyncAdapter";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_APP/GoogleExtShared";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_APP/FaceLock/FaceLock.apk";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_APP/GoogleCalendarSyncAdapter/GoogleCalendarSyncAdapter.apk";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_APP/GoogleContactsSyncAdapter/GoogleContactsSyncAdapter.apk";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_APP/GoogleExtShared/GoogleExtShared.apk";
      if [ "$AOSP_PKG_INSTALL" == "true" ]; then
        chcon -h u:object_r:system_file:s0 "$SYSTEM_APP/Messaging";
        chcon -h u:object_r:system_file:s0 "$SYSTEM_APP/Messaging/Messaging.apk";
      fi;
    }

    selinux_context_sp2() {
      chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/ConfigUpdater";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/GoogleExtServices";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/GoogleLoginService";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/GoogleServicesFramework";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/Phonesky";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/PrebuiltGmsCore";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/ConfigUpdater/ConfigUpdater.apk";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/GoogleExtServices/GoogleExtServices.apk";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/GoogleLoginService/GoogleLoginService.apk";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/GoogleServicesFramework/GoogleServicesFramework.apk";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/Phonesky/Phonesky.apk";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/PrebuiltGmsCore/PrebuiltGmsCore.apk";
      if [ "$AOSP_PKG_INSTALL" == "true" ]; then
        chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/Contacts";
        chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/Dialer";
        chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/ManagedProvisioning";
        chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/Provision";
        chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/Contacts/Contacts.apk";
        chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/Dialer/Dialer.apk";
        chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/ManagedProvisioning/ManagedProvisioning.apk";
        chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/Provision/Provision.apk";
      fi;
    }

    selinux_context_sf3() {
      chcon -h u:object_r:system_file:s0 "$SYSTEM_FRAMEWORK/com.google.android.dialer.support.jar";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_FRAMEWORK/com.google.android.maps.jar";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_FRAMEWORK/com.google.android.media.effects.jar";
    }

    selinux_context_sl4() {
      chcon -h u:object_r:system_lib_file:s0 "$SYSTEM_LIB/libfilterpack_facedetect.so";
      chcon -h u:object_r:system_lib_file:s0 "$SYSTEM_LIB/libfrsdk.so";
    }

    selinux_context_sl5() {
      chcon -h u:object_r:system_lib_file:s0 "$SYSTEM_LIB64/libfacenet.so";
      chcon -h u:object_r:system_lib_file:s0 "$SYSTEM_LIB64/libfilterpack_facedetect.so";
      chcon -h u:object_r:system_lib_file:s0 "$SYSTEM_LIB64/libfrsdk.so";
    }

    selinux_context_se6() {
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_DEFAULT";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_DEFAULT/default-permissions.xml";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_DEFAULT/opengapps-permissions.xml";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_PERM/com.google.android.dialer.support.xml";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_PERM/com.google.android.maps.xml";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_PERM/com.google.android.media.effects.xml";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_PREF";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_PREF/google.xml";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_CONFIG/dialer_experience.xml";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_CONFIG/google.xml";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_CONFIG/google_build.xml";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_CONFIG/google_exclusives_enable.xml";
      chcon -h u:object_r:system_file:s0 "$SYSTEM/etc/g.prop";
      if [ "$AOSP_PKG_INSTALL" == "true" ]; then
        chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_PERM/com.android.contacts.xml";
        chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_PERM/com.android.dialer.xml";
        chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_PERM/com.android.managedprovisioning.xml";
        chcon -h u:object_r:system_file:s0 "$SYSTEM_ETC_PERM/com.android.provision.xml";
      fi;
    }
    # end selinux method

    # Create FaceLock lib symlink
    bind_facelock_lib() {
      ln -sfnv $SYSTEM/lib64/libfacenet.so $SYSTEM/app/FaceLock/lib/arm64/libfacenet.so >> $LINKER;
      rm -rf $SYSTEM/app/FaceLock/lib/arm64/placeholder
    }

    # APK optimization using zipalign tool
    apk_opt() {
      $ZIPALIGN_TOOL -p -v 4 $SYSTEM_APP/FaceLock/FaceLock.apk $ZIPALIGN_OUTFILE/FaceLock.apk >> $ZIPALIGN_LOG;
      $ZIPALIGN_TOOL -p -v 4 $SYSTEM_APP/GoogleCalendarSyncAdapter/GoogleCalendarSyncAdapter.apk $ZIPALIGN_OUTFILE/GoogleCalendarSyncAdapter.apk >> $ZIPALIGN_LOG;
      $ZIPALIGN_TOOL -p -v 4 $SYSTEM_APP/GoogleContactsSyncAdapter/GoogleContactsSyncAdapter.apk $ZIPALIGN_OUTFILE/GoogleContactsSyncAdapter.apk >> $ZIPALIGN_LOG;
      $ZIPALIGN_TOOL -p -v 4 $SYSTEM_APP/GoogleExtShared/GoogleExtShared.apk $ZIPALIGN_OUTFILE/GoogleExtShared.apk >> $ZIPALIGN_LOG;
      $ZIPALIGN_TOOL -p -v 4 $SYSTEM_PRIV_APP/ConfigUpdater/ConfigUpdater.apk $ZIPALIGN_OUTFILE/ConfigUpdater.apk >> $ZIPALIGN_LOG;
      $ZIPALIGN_TOOL -p -v 4 $SYSTEM_PRIV_APP/GoogleExtServices/GoogleExtServices.apk $ZIPALIGN_OUTFILE/GoogleExtServices.apk >> $ZIPALIGN_LOG;
      $ZIPALIGN_TOOL -p -v 4 $SYSTEM_PRIV_APP/GoogleLoginService/GoogleLoginService.apk $ZIPALIGN_OUTFILE/GoogleLoginService.apk >> $ZIPALIGN_LOG;
      $ZIPALIGN_TOOL -p -v 4 $SYSTEM_PRIV_APP/GoogleServicesFramework/GoogleServicesFramework.apk $ZIPALIGN_OUTFILE/GoogleServicesFramework.apk >> $ZIPALIGN_LOG;
      $ZIPALIGN_TOOL -p -v 4 $SYSTEM_PRIV_APP/Phonesky/Phonesky.apk $ZIPALIGN_OUTFILE/Phonesky.apk >> $ZIPALIGN_LOG;
      $ZIPALIGN_TOOL -p -v 4 $SYSTEM_PRIV_APP/PrebuiltGmsCore/PrebuiltGmsCore.apk $ZIPALIGN_OUTFILE/PrebuiltGmsCore.apk >> $ZIPALIGN_LOG;
      if [ "$AOSP_PKG_INSTALL" == "true" ]; then
        $ZIPALIGN_TOOL -p -v 4 $SYSTEM_APP/Messaging/Messaging.apk $ZIPALIGN_OUTFILE/Messaging.apk >> $ZIPALIGN_LOG;
        $ZIPALIGN_TOOL -p -v 4 $SYSTEM_PRIV_APP/Contacts/Contacts.apk $ZIPALIGN_OUTFILE/Contacts.apk >> $ZIPALIGN_LOG;
        $ZIPALIGN_TOOL -p -v 4 $SYSTEM_PRIV_APP/Dialer/Dialer.apk $ZIPALIGN_OUTFILE/Dialer.apk >> $ZIPALIGN_LOG;
        $ZIPALIGN_TOOL -p -v 4 $SYSTEM_PRIV_APP/ManagedProvisioning/ManagedProvisioning.apk $ZIPALIGN_OUTFILE/ManagedProvisioning.apk >> $ZIPALIGN_LOG;
        $ZIPALIGN_TOOL -p -v 4 $SYSTEM_PRIV_APP/Provision/Provision.apk $ZIPALIGN_OUTFILE/Provision.apk >> $ZIPALIGN_LOG;
      fi;
    }

    pre_opt() {
      rm -rf $SYSTEM_APP/FaceLock/FaceLock.apk
      rm -rf $SYSTEM_APP/GoogleCalendarSyncAdapter/GoogleCalendarSyncAdapter.apk
      rm -rf $SYSTEM_APP/GoogleContactsSyncAdapter/GoogleContactsSyncAdapter.apk
      rm -rf $SYSTEM_APP/GoogleExtShared/GoogleExtShared.apk
      rm -rf $SYSTEM_PRIV_APP/ConfigUpdater/ConfigUpdater.apk
      rm -rf $SYSTEM_PRIV_APP/GoogleExtServices/GoogleExtServices.apk
      rm -rf $SYSTEM_PRIV_APP/GoogleLoginService/GoogleLoginService.apk
      rm -rf $SYSTEM_PRIV_APP/GoogleServicesFramework/GoogleServicesFramework.apk
      rm -rf $SYSTEM_PRIV_APP/Phonesky/Phonesky.apk
      rm -rf $SYSTEM_PRIV_APP/PrebuiltGmsCore/PrebuiltGmsCore.apk
      if [ "$AOSP_PKG_INSTALL" == "true" ]; then
        rm -rf $SYSTEM_APP/Messaging/Messaging.apk
        rm -rf $SYSTEM_PRIV_APP/Contacts/Contacts.apk
        rm -rf $SYSTEM_PRIV_APP/Dialer/Dialer.apk
        rm -rf $SYSTEM_PRIV_APP/ManagedProvisioning/ManagedProvisioning.apk
        rm -rf $SYSTEM_PRIV_APP/Provision/Provision.apk
      fi;
    }

    add_opt() {
      cp -f $ZIPALIGN_OUTFILE/FaceLock.apk $SYSTEM_APP/FaceLock/FaceLock.apk
      cp -f $ZIPALIGN_OUTFILE/GoogleCalendarSyncAdapter.apk $SYSTEM_APP/GoogleCalendarSyncAdapter/GoogleCalendarSyncAdapter.apk
      cp -f $ZIPALIGN_OUTFILE/GoogleContactsSyncAdapter.apk $SYSTEM_APP/GoogleContactsSyncAdapter/GoogleContactsSyncAdapter.apk
      cp -f $ZIPALIGN_OUTFILE/GoogleExtShared.apk $SYSTEM_APP/GoogleExtShared/GoogleExtShared.apk
      cp -f $ZIPALIGN_OUTFILE/ConfigUpdater.apk $SYSTEM_PRIV_APP/ConfigUpdater/ConfigUpdater.apk
      cp -f $ZIPALIGN_OUTFILE/GoogleExtServices.apk $SYSTEM_PRIV_APP/GoogleExtServices/GoogleExtServices.apk
      cp -f $ZIPALIGN_OUTFILE/GoogleLoginService.apk $SYSTEM_PRIV_APP/GoogleLoginService/GoogleLoginService.apk
      cp -f $ZIPALIGN_OUTFILE/GoogleServicesFramework.apk $SYSTEM_PRIV_APP/GoogleServicesFramework/GoogleServicesFramework.apk
      cp -f $ZIPALIGN_OUTFILE/Phonesky.apk $SYSTEM_PRIV_APP/Phonesky/Phonesky.apk
      cp -f $ZIPALIGN_OUTFILE/PrebuiltGmsCore.apk $SYSTEM_PRIV_APP/PrebuiltGmsCore/PrebuiltGmsCore.apk
      if [ "$AOSP_PKG_INSTALL" == "true" ]; then
        cp -f $ZIPALIGN_OUTFILE/Messaging.apk $SYSTEM_APP/Messaging/Messaging.apk
        cp -f $ZIPALIGN_OUTFILE/Contacts.apk $SYSTEM_PRIV_APP/Contacts/Contacts.apk
        cp -f $ZIPALIGN_OUTFILE/Dialer.apk $SYSTEM_PRIV_APP/Dialer/Dialer.apk
        cp -f $ZIPALIGN_OUTFILE/ManagedProvisioning.apk $SYSTEM_PRIV_APP/ManagedProvisioning/ManagedProvisioning.apk
        cp -f $ZIPALIGN_OUTFILE/Provision.apk $SYSTEM_PRIV_APP/Provision/Provision.apk
      fi;
    }

    perm_opt() {
      chmod 0644 $SYSTEM_APP/FaceLock/FaceLock.apk
      chmod 0644 $SYSTEM_APP/GoogleCalendarSyncAdapter/GoogleCalendarSyncAdapter.apk
      chmod 0644 $SYSTEM_APP/GoogleContactsSyncAdapter/GoogleContactsSyncAdapter.apk
      chmod 0644 $SYSTEM_APP/GoogleExtShared/GoogleExtShared.apk
      chmod 0644 $SYSTEM_PRIV_APP/ConfigUpdater/ConfigUpdater.apk
      chmod 0644 $SYSTEM_PRIV_APP/GoogleExtServices/GoogleExtServices.apk
      chmod 0644 $SYSTEM_PRIV_APP/GoogleLoginService/GoogleLoginService.apk
      chmod 0644 $SYSTEM_PRIV_APP/GoogleServicesFramework/GoogleServicesFramework.apk
      chmod 0644 $SYSTEM_PRIV_APP/Phonesky/Phonesky.apk
      chmod 0644 $SYSTEM_PRIV_APP/PrebuiltGmsCore/PrebuiltGmsCore.apk
      if [ "$AOSP_PKG_INSTALL" == "true" ]; then
        chmod 0644 $SYSTEM_APP/Messaging/Messaging.apk
        chmod 0644 $SYSTEM_PRIV_APP/Contacts/Contacts.apk
        chmod 0644 $SYSTEM_PRIV_APP/Dialer/Dialer.apk
        chmod 0644 $SYSTEM_PRIV_APP/ManagedProvisioning/ManagedProvisioning.apk
        chmod 0644 $SYSTEM_PRIV_APP/Provision/Provision.apk
      fi;
    }
    # end opt method

    # execute installation functions
    sdk_v25() {
      extract_app;
      set_sparse;
      selinux_context_s1;
      selinux_context_sp2;
      selinux_context_sf3;
      selinux_context_sl4;
      selinux_context_sl5;
      selinux_context_se6;
      bind_facelock_lib;
      apk_opt;
      pre_opt;
      add_opt;
      perm_opt;
      # Re-run selinux functions for optimized APKs
      selinux_context_s1;
      selinux_context_sp2;
      # end selinux functions
    }
    sdk_v25;
    # Print installed files to sdk log
    cat $LOG >> $sdk_v25;
  else
    echo "Target Android SDK Version : $android_sdk" >> $sdk_v25;
  fi;
}

# Fix wiping of runtime permissions on dirty install
runtime_permission() {
  rm -rf $SYSTEM/etc/data.prop
  cp -f $TMP/data.prop $SYSTEM/etc/data.prop
  chmod 0644 $SYSTEM/etc/data.prop
  chcon -h u:object_r:system_file:s0 "$SYSTEM/etc/data.prop";
}

# OTA survival script
backup_script() {
  ZIP="zip/sys_addon.tar.xz";
  unpack_zip;
  extract_backup_script() {
    tar tvf $ZIP_FILE/sys_addon.tar.xz >> $restore;
    tar -xf $ZIP_FILE/sys_addon.tar.xz -C $TMP_ADDON;
  }
  extract_backup_script;
  set_sparse_backup;
  chcon -h u:object_r:system_file:s0 "$SYSTEM_ADDOND/90bit_gapps.sh";
}

unpack_zip_initial() {
  for f in $ZIP_INITIAL; do
    unzip -o "$ZIPFILE" "$f" -d "$TMP";
  done
}

# Check whether SetupWizard config file present in device or not
get_setup_config() {
  if [ -f $INTERNAL/setup-config.prop ]; then
    setup_config="true";
  else
    setup_config="false";
  fi;
}

# Set SetupWizard package installation
set_setup_install() {
  if [ "$supported_setup_config" == "$supported_target" ]; then
    # Set config dependent packages
    ZIP_INITIAL="
      zip/core/priv_app_GoogleBackupTransport.tar.xz
      zip/core/priv_app_GoogleRestore.tar.xz
      zip/core/priv_app_SetupWizard.tar.xz";

    # Unzip system files from installer
    unpack_zip_initial;

    # Remove SetupWizard components
    pre_installed_initial() {
      if [ "$android_sdk" -gt "28" ]; then
        rm -rf $SYSTEM/product/app/ManagedProvisioning
        rm -rf $SYSTEM/product/app/Provision
        rm -rf $SYSTEM/product/priv-app/ManagedProvisioning
        rm -rf $SYSTEM/product/priv-app/Provision
      fi;
      rm -rf $SYSTEM_APP/ManagedProvisioning
      rm -rf $SYSTEM_APP/Provision
      rm -rf $SYSTEM_PRIV_APP/GoogleBackupTransport
      rm -rf $SYSTEM_PRIV_APP/GoogleRestore
      rm -rf $SYSTEM_PRIV_APP/ManagedProvisioning
      rm -rf $SYSTEM_PRIV_APP/Provision
      rm -rf $SYSTEM_PRIV_APP/SetupWizard
    }

    # Unpack SetupWizard components
    extract_app_initial() {
      tar tvf $ZIP_FILE/core/priv_app_GoogleBackupTransport.tar.xz >> $config_log;
      if [ "$android_sdk" -gt "25" ]; then # Unsupported component for SDK 25
        tar tvf $ZIP_FILE/core/priv_app_GoogleRestore.tar.xz >> $config_log;
      fi;
      tar tvf $ZIP_FILE/core/priv_app_SetupWizard.tar.xz >> $config_log;
      tar -xf $ZIP_FILE/core/priv_app_GoogleBackupTransport.tar.xz -C $TMP_PRIV_SETUP;
      if [ "$android_sdk" -gt "25" ]; then # Unsupported component for SDK 25
        tar -xf $ZIP_FILE/core/priv_app_GoogleRestore.tar.xz -C $TMP_PRIV_SETUP;
      fi;
      tar -xf $ZIP_FILE/core/priv_app_SetupWizard.tar.xz -C $TMP_PRIV_SETUP;
      set_sparse_excl;
    }

    # Selinux context for SetupWizard components
    selinux_context_sp2_initial() {
      chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/GoogleBackupTransport";
      if [ "$android_sdk" -gt "25" ]; then # Unsupported component for SDK 25
        chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/GoogleRestore";
      fi;
      chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/SetupWizard";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/GoogleBackupTransport/GoogleBackupTransport.apk";
      if [ "$android_sdk" -gt "25" ]; then # Unsupported component for SDK 25
        chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/GoogleRestore/GoogleRestore.apk";
      fi;
      chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/SetupWizard/SetupWizard.apk";
    }

    # SetupWizard components optimization using zipalign tool
    apk_opt_initial() {
      $ZIPALIGN_TOOL -p -v 4 $SYSTEM_PRIV_APP/GoogleBackupTransport/GoogleBackupTransport.apk $ZIPALIGN_OUTFILE/GoogleBackupTransport.apk >> $ZIPALIGN_LOG;
      if [ "$android_sdk" -gt "25" ]; then # Unsupported component for SDK 25
        $ZIPALIGN_TOOL -p -v 4 $SYSTEM_PRIV_APP/GoogleRestore/GoogleRestore.apk $ZIPALIGN_OUTFILE/GoogleRestore.apk >> $ZIPALIGN_LOG;
      fi;
      $ZIPALIGN_TOOL -p -v 4 $SYSTEM_PRIV_APP/SetupWizard/SetupWizard.apk $ZIPALIGN_OUTFILE/SetupWizard.apk >> $ZIPALIGN_LOG;
    }

    pre_opt_initial() {
      rm -rf $SYSTEM_PRIV_APP/GoogleBackupTransport/GoogleBackupTransport.apk
      if [ "$android_sdk" -gt "25" ]; then # Unsupported component for SDK 25
        rm -rf $SYSTEM_PRIV_APP/GoogleRestore/GoogleRestore.apk
      fi;
      rm -rf $SYSTEM_PRIV_APP/SetupWizard/SetupWizard.apk
    }

    add_opt_initial() {
      cp -f $ZIPALIGN_OUTFILE/GoogleBackupTransport.apk $SYSTEM_PRIV_APP/GoogleBackupTransport/GoogleBackupTransport.apk
      if [ "$android_sdk" -gt "25" ]; then # Unsupported component for SDK 25
        cp -f $ZIPALIGN_OUTFILE/GoogleRestore.apk $SYSTEM_PRIV_APP/GoogleRestore/GoogleRestore.apk
      fi;
      cp -f $ZIPALIGN_OUTFILE/SetupWizard.apk $SYSTEM_PRIV_APP/SetupWizard/SetupWizard.apk
    }

    perm_opt_initial() {
      chmod 0644 $SYSTEM_PRIV_APP/GoogleBackupTransport/GoogleBackupTransport.apk
      if [ "$android_sdk" -gt "25" ]; then # Unsupported component for SDK 25
        chmod 0644 $SYSTEM_PRIV_APP/GoogleRestore/GoogleRestore.apk
      fi;
      chmod 0644 $SYSTEM_PRIV_APP/SetupWizard/SetupWizard.apk
    }

    # end opt initial method

    # Initiate SetupWizard components installation
    on_config_install() {
      pre_installed_initial;
      extract_app_initial;
      selinux_context_sp2_initial;
      apk_opt_initial;
      pre_opt_initial;
      add_opt_initial;
      perm_opt_initial;
      # Re-run selinux function for optimized APKs
      selinux_context_sp2_initial;
      # end selinux function
    }
    on_config_install;
  else
    echo "ERROR: Config property set to 'false'" >> $SETUP_CONFIG;
  fi;
}

# Add Pixel specific component
set_pixel_install() {
  if [ "$android_product" == "$supported_product" ]; then
    # Set config dependent package
    ZIP_INITIAL="zip/core/priv_app_AndroidMigratePrebuilt.tar.xz";
    unpack_zip_initial;
    # Remove SetupWizard component
    rm -rf $SYSTEM_PRIV_APP/AndroidMigratePrebuilt
    # Unpack SetupWizard component
    tar tvf $ZIP_FILE/core/priv_app_AndroidMigratePrebuilt.tar.xz >> $config_log;
    tar -xf $ZIP_FILE/core/priv_app_AndroidMigratePrebuilt.tar.xz -C $TMP_PRIV_SETUP;
    set_sparse_excl;
    # Selinux context for SetupWizard component
    selinux_context_sp2_initial() {
      chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/AndroidMigratePrebuilt";
      chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/AndroidMigratePrebuilt/AndroidMigratePrebuilt.apk";
    }
    selinux_context_sp2_initial;
    # SetupWizard component optimization using zipalign tool
    $ZIPALIGN_TOOL -p -v 4 $SYSTEM_PRIV_APP/AndroidMigratePrebuilt/AndroidMigratePrebuilt.apk $ZIPALIGN_OUTFILE/AndroidMigratePrebuilt.apk >> $ZIPALIGN_LOG;
    rm -rf $SYSTEM_PRIV_APP/AndroidMigratePrebuilt/AndroidMigratePrebuilt.apk
    cp -f $ZIPALIGN_OUTFILE/AndroidMigratePrebuilt.apk $SYSTEM_PRIV_APP/AndroidMigratePrebuilt/AndroidMigratePrebuilt.apk
    chmod 0644 $SYSTEM_PRIV_APP/AndroidMigratePrebuilt/AndroidMigratePrebuilt.apk
    # Re-run selinux function for optimized APKs
    selinux_context_sp2_initial;
  fi;
}

# Install config dependent packages
on_setup_install() {
  if [ "$setup_config" == "true" ]; then
    set_setup_install;
    set_pixel_install;
  else
    echo "ERROR: Config file not found" >> $SETUP_CONFIG;
  fi;
}

# Check whether addon config file present in device or not
get_addon_config() {
  if [ -f $INTERNAL/addon-config.prop ]; then
    addon_config="true";
  else
    addon_config="false";
  fi;
}

# Set addon install target
target_sys() {
  ZIP="zip/sys/$ADDON_SYS";
  # Unzip system files from installer
  unpack_zip;
  # Unpack system files
  tar tvf $ZIP_FILE/sys/$ADDON_SYS >> $LOG;
  tar -xf $ZIP_FILE/sys/$ADDON_SYS -C $TMP_SYS;
  # Install package
  set_sparse;
  # Set selinux context
  chcon -h u:object_r:system_file:s0 "$SYSTEM_APP/$PKG_SYS";
  chcon -h u:object_r:system_file:s0 "$SYSTEM_APP/$PKG_SYS/$PKG_SYS.apk";
}

target_core() {
  ZIP="zip/core/$ADDON_CORE";
  # Unzip system files from installer
  unpack_zip;
  # Unpack system files
  tar tvf $ZIP_FILE/core/$ADDON_CORE >> $LOG;
  tar -xf $ZIP_FILE/core/$ADDON_CORE -C $TMP_PRIV;
  # Install package
  set_sparse;
  # Set selinux context
  chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/$PKG_CORE";
  chcon -h u:object_r:system_file:s0 "$SYSTEM_PRIV_APP/$PKG_CORE/$PKG_CORE.apk";
}

target_lib32() {
  ZIP="zip/markup_lib32.tar.xz";
  # Unzip system files from installer
  unpack_zip;
  # Unpack system files
  tar tvf $ZIP_FILE/markup_lib32.tar.xz >> $LOG;
  tar -xf $ZIP_FILE/markup_lib32.tar.xz -C $TMP_LIB;
  # Install package
  set_sparse;
  # Set selinux context
  chcon -h u:object_r:system_lib_file:s0 "$SYSTEM_LIB/libsketchology_native.so";
}

target_lib64() {
  ZIP="zip/markup_lib64.tar.xz";
  # Unzip system files from installer
  unpack_zip;
  # Unpack system files
  tar tvf $ZIP_FILE/markup_lib64.tar.xz >> $LOG;
  tar -xf $ZIP_FILE/markup_lib64.tar.xz -C $TMP_LIB64;
  # Install package
  set_sparse;
  # Set selinux context
  chcon -h u:object_r:system_lib_file:s0 "$SYSTEM_LIB64/libsketchology_native.so";
}

set_google_default() {
  if [ "$supported_dialer_config" == "$supported_target" ]; then
    # set Google Dialer as default; based on the work of osm0sis @ xda-developers
    setver="122"  # lowest version in MM, tagged at 6.0.0
    setsec="/data/system/users/0/settings_secure.xml"
    if [ -f "$setsec" ]; then
      if grep -q 'dialer_default_application' "$setsec"; then
        if ! grep -q 'dialer_default_application" value="com.google.android.dialer' "$setsec"; then
          curentry="$(grep -o 'dialer_default_application" value=.*$' "$setsec")"
          newentry='dialer_default_application" value="com.google.android.dialer" package="android" />\r'
          sed -i "s;${curentry};${newentry};" "$setsec"
        fi;
      else
        max="0"
        for i in $(grep -o 'id=.*$' "$setsec" | cut -d '"' -f 2); do
          test "$i" -gt "$max" && max="$i"
        done
        entry='<setting id="'"$((max + 1))"'" name="dialer_default_application" value="com.google.android.dialer" package="android" />\r'
        sed -i "/<settings version=\"/a\ \ ${entry}" "$setsec"
      fi;
    else
      if [ ! -d "/data/system/users/0" ]; then
        install -d "/data/system/users/0"
        chown -R 1000:1000 "/data/system"
        chmod -R 775 "/data/system"
        chmod 700 "/data/system/users/0"
      fi;
      { echo -e "<?xml version='1.0' encoding='UTF-8' standalone='yes' ?>\r"
      echo -e '<settings version="'$setver'">\r'
      echo -e '  <setting id="1" name="dialer_default_application" value="com.google.android.dialer" package="android" />\r'
      echo -e '</settings>'; } > "$setsec"
    fi;
    chown 1000:1000 "$setsec"
    chmod 600 "$setsec"
  fi;
}
  
# Set addon package installation
set_addon_install() {
  if [ "$supported_calculator_config" == "$supported_target" ]; then
    ui_print "Installing Calculator Google";
    # Remove AOSP Calculator
    rm -rf $SYSTEM/app/Calculator*
    rm -rf $SYSTEM/app/calculator*
    rm -rf $SYSTEM/priv-app/Calculator*
    rm -rf $SYSTEM/priv-app/calculator*
    rm -rf $SYSTEM/product/app/Calculator*
    rm -rf $SYSTEM/product/app/calculator*
    rm -rf $SYSTEM/product/priv-app/Calculator*
    rm -rf $SYSTEM/product/priv-app/calculator*
    # Set install variable
    ADDON_SYS="sys_app_CalculatorGooglePrebuilt.tar.xz";
    PKG_SYS="CalculatorGooglePrebuilt";
    # Install
    target_sys;
  fi;
  if [ "$supported_calendar_config" == "$supported_target" ]; then
    ui_print "Installing Calendar Google";
    # Backup
    test -d $SYSTEM/app/CalendarProvider && SYS_APP_CP="true" || SYS_APP_CP="false";
    test -d $SYSTEM/priv-app/CalendarProvider && SYS_PRIV_CP="true" || SYS_PRIV_CP="false";
    test -d $SYSTEM/product/app/CalendarProvider && PRO_APP_CP="true" || PRO_APP_CP="false";
    test -d $SYSTEM/product/priv-app/CalendarProvider && PRO_PRIV_CP="true" || PRO_PRIV_CP="false";
    if [ "$SYS_APP_CP" == "true" ]; then
      mv $SYSTEM/app/CalendarProvider $TMP/restore/CalendarProvider
    fi;
    if [ "$SYS_PRIV_CP" == "true" ]; then
      mv $SYSTEM/priv-app/CalendarProvider $TMP/restore/CalendarProvider
    fi;
    if [ "$PRO_APP_CP" == "true" ]; then
      mv $SYSTEM/product/app/CalendarProvider $TMP/restore/CalendarProvider
    fi;
    if [ "$PRO_PRIV_CP" == "true" ]; then
      mv $SYSTEM/product/priv-app/CalendarProvider $TMP/restore/CalendarProvider
    fi;
    # Remove AOSP Calendar
    rm -rf $SYSTEM/app/Calendar*
    rm -rf $SYSTEM/app/calendar*
    rm -rf $SYSTEM/app/Etar
    rm -rf $SYSTEM/priv-app/Calendar*
    rm -rf $SYSTEM/priv-app/calendar*
    rm -rf $SYSTEM/priv-app/Etar
    rm -rf $SYSTEM/product/app/Calendar*
    rm -rf $SYSTEM/product/app/calendar*
    rm -rf $SYSTEM/product/app/Etar
    rm -rf $SYSTEM/product/priv-app/Calendar*
    rm -rf $SYSTEM/product/priv-app/calendar*
    rm -rf $SYSTEM/product/priv-app/Etar
    # Set install variable
    ADDON_SYS="sys_app_CalendarGooglePrebuilt.tar.xz";
    PKG_SYS="CalendarGooglePrebuilt";
    # Install
    target_sys;
    # Restore
    if [ "$SYS_APP_CP" == "true" ]; then
      mv $TMP/restore/CalendarProvider $SYSTEM/app/CalendarProvider
    fi;
    if [ "$SYS_PRIV_CP" == "true" ]; then
      mv $TMP/restore/CalendarProvider $SYSTEM/priv-app/CalendarProvider
    fi;
    if [ "$PRO_APP_CP" == "true" ]; then
      mv $TMP/restore/CalendarProvider $SYSTEM/product/app/CalendarProvider
    fi;
    if [ "$PRO_PRIV_CP" == "true" ]; then
      mv $TMP/restore/CalendarProvider $SYSTEM/product/priv-app/CalendarProvider
    fi;
  fi;
  if [ "$supported_contacts_config" == "$supported_target" ]; then
    ui_print "Installing Contacts Google";
    # Backup
    test -d $SYSTEM/app/ContactsProvider && SYS_APP_CTT="true" || SYS_APP_CTT="false";
    test -d $SYSTEM/priv-app/ContactsProvider && SYS_PRIV_CTT="true" || SYS_PRIV_CTT="false";
    test -d $SYSTEM/product/app/ContactsProvider && PRO_APP_CTT="true" || PRO_APP_CTT="false";
    test -d $SYSTEM/product/priv-app/ContactsProvider && PRO_PRIV_CTT="true" || PRO_PRIV_CTT="false";
    if [ "$SYS_APP_CTT" == "true" ]; then
      mv $SYSTEM/app/ContactsProvider $TMP/restore/ContactsProvider
    fi;
    if [ "$SYS_PRIV_CTT" == "true" ]; then
      mv $SYSTEM/priv-app/ContactsProvider $TMP/restore/ContactsProvider
    fi;
    if [ "$PRO_APP_CTT" == "true" ]; then
      mv $SYSTEM/product/app/ContactsProvider $TMP/restore/ContactsProvider
    fi;
    if [ "$PRO_PRIV_CTT" == "true" ]; then
      mv $SYSTEM/product/priv-app/ContactsProvider $TMP/restore/ContactsProvider
    fi;
    # Remove AOSP Contacts
    rm -rf $SYSTEM/app/Contacts*
    rm -rf $SYSTEM/app/contacts*
    rm -rf $SYSTEM/priv-app/Contacts*
    rm -rf $SYSTEM/priv-app/contacts*
    rm -rf $SYSTEM/product/app/Contacts*
    rm -rf $SYSTEM/product/app/contacts*
    rm -rf $SYSTEM/product/priv-app/Contacts*
    rm -rf $SYSTEM/product/priv-app/contacts*
    # Set install variable
    ADDON_CORE="priv_app_ContactsGooglePrebuilt.tar.xz";
    PKG_CORE="ContactsGooglePrebuilt";
    # Install
    target_core;
    # Restore
    if [ "$SYS_APP_CTT" == "true" ]; then
      mv $TMP/restore/ContactsProvider $SYSTEM/app/ContactsProvider
    fi;
    if [ "$SYS_PRIV_CTT" == "true" ]; then
      mv $TMP/restore/ContactsProvider $SYSTEM/priv-app/ContactsProvider
    fi;
    if [ "$PRO_APP_CTT" == "true" ]; then
      mv $TMP/restore/ContactsProvider $SYSTEM/product/app/ContactsProvider
    fi;
    if [ "$PRO_PRIV_CTT" == "true" ]; then
      mv $TMP/restore/ContactsProvider $SYSTEM/product/priv-app/ContactsProvider
    fi;
  fi;
  if [ "$supported_deskclock_config" == "$supported_target" ]; then
    ui_print "Installing Deskclock Google";
    # Remove AOSP DeskClock
    rm -rf $SYSTEM/app/DeskClock*
    rm -rf $SYSTEM/app/Clock*
    rm -rf $SYSTEM/priv-app/DeskClock*
    rm -rf $SYSTEM/priv-app/Clock*
    rm -rf $SYSTEM/product/app/DeskClock*
    rm -rf $SYSTEM/product/app/Clock*
    rm -rf $SYSTEM/product/priv-app/DeskClock*
    rm -rf $SYSTEM/product/priv-app/Clock*
    # Set install variable
    ADDON_SYS="sys_app_DeskClockGooglePrebuilt.tar.xz";
    PKG_SYS="DeskClockGooglePrebuilt";
    # Install
    target_sys;
  fi;
  if [ "$supported_dialer_config" == "$supported_target" ]; then
    ui_print "Installing Dialer Google";
    # Remove AOSP Dialer
    rm -rf $SYSTEM/app/Dialer*
    rm -rf $SYSTEM/app/dialer*
    rm -rf $SYSTEM/priv-app/Dialer*
    rm -rf $SYSTEM/priv-app/dialer*
    rm -rf $SYSTEM/product/app/Dialer*
    rm -rf $SYSTEM/product/app/dialer*
    rm -rf $SYSTEM/product/priv-app/Dialer*
    rm -rf $SYSTEM/product/priv-app/dialer*
    # Set install variable
    ADDON_CORE="priv_app_DialerGooglePrebuilt.tar.xz";
    PKG_CORE="DialerGooglePrebuilt";
    # Install
    target_core;
    # Set Google Dialer as default
    set_google_default;
  fi;
  if [ "$supported_markup_config" == "$supported_target" ]; then
    ui_print "Installing Markup Google";
    # Remove pre-install Markup
    rm -rf $SYSTEM/app/MarkupGoogle*
    rm -rf $SYSTEM/priv-app/MarkupGoogle*
    rm -rf $SYSTEM/product/app/MarkupGoogle*
    rm -rf $SYSTEM/product/priv-app/MarkupGoogle*
    # Set install variable
    ADDON_SYS="sys_app_MarkupGooglePrebuilt.tar.xz";
    PKG_SYS="MarkupGooglePrebuilt";
    # Install
    target_sys;
    target_lib32;
    target_lib64;
  fi;
  if [ "$supported_messages_config" == "$supported_target" ]; then
    ui_print "Installing Messages Google";
    # Remove AOSP Messages
    rm -rf $SYSTEM/app/Messages*
    rm -rf $SYSTEM/app/messages*
    rm -rf $SYSTEM/app/Messaging*
    rm -rf $SYSTEM/app/messaging*
    rm -rf $SYSTEM/priv-app/Messages*
    rm -rf $SYSTEM/priv-app/messages*
    rm -rf $SYSTEM/priv-app/Messaging*
    rm -rf $SYSTEM/priv-app/messaging*
    rm -rf $SYSTEM/product/app/Messages*
    rm -rf $SYSTEM/product/app/messages*
    rm -rf $SYSTEM/product/app/Messaging*
    rm -rf $SYSTEM/product/app/messaging*
    rm -rf $SYSTEM/product/priv-app/Messages*
    rm -rf $SYSTEM/product/priv-app/messages*
    rm -rf $SYSTEM/product/priv-app/Messaging*
    rm -rf $SYSTEM/product/priv-app/messaging*
    # Set install variable
    ADDON_SYS="sys_app_MessagesGooglePrebuilt.tar.xz";
    PKG_SYS="MessagesGooglePrebuilt";
    ADDON_CORE="priv_app_CarrierServices.tar.xz";
    PKG_CORE="CarrierServices";
    # Install
    target_sys;
    target_core;
  fi;
  if [ "$supported_photos_config" == "$supported_target" ]; then
    ui_print "Installing Photos Google";
    # Remove pre-install Photos
    rm -rf $SYSTEM/app/Photos*
    rm -rf $SYSTEM/app/photos*
    rm -rf $SYSTEM/priv-app/Photos*
    rm -rf $SYSTEM/priv-app/photos*
    rm -rf $SYSTEM/product/app/Photos*
    rm -rf $SYSTEM/product/app/photos*
    rm -rf $SYSTEM/product/priv-app/Photos*
    rm -rf $SYSTEM/product/priv-app/photos*
    # Set install variable
    ADDON_SYS="sys_app_PhotosGooglePrebuilt.tar.xz";
    PKG_SYS="PhotosGooglePrebuilt";
    # Install
    target_sys;
  fi;
  if [ "$supported_soundpicker_config" == "$supported_target" ]; then
    ui_print "Installing SoundPicker Google";
    # Remove pre-install SoundPicker
    rm -rf $SYSTEM/app/SoundPicker*
    rm -rf $SYSTEM/priv-app/SoundPicker*
    rm -rf $SYSTEM/product/app/SoundPicker*
    rm -rf $SYSTEM/product/priv-app/SoundPicker*
    # Set install variable
    ADDON_SYS="sys_app_SoundPickerPrebuilt.tar.xz";
    PKG_SYS="SoundPickerPrebuilt";
    # Install
    target_sys;
  fi;
  if [ "$supported_assistant_config" == "$supported_target" ]; then
    ui_print "Installing Assistant Google";
    # Remove pre-install Assistant
    rm -rf $SYSTEM/app/Velvet*
    rm -rf $SYSTEM/app/velvet*
    rm -rf $SYSTEM/priv-app/Velvet*
    rm -rf $SYSTEM/priv-app/velvet*
    rm -rf $SYSTEM/product/app/Velvet*
    rm -rf $SYSTEM/product/app/velvet*
    rm -rf $SYSTEM/product/priv-app/Velvet*
    rm -rf $SYSTEM/product/priv-app/velvet*
    # Set install variable
    ADDON_CORE="priv_app_Velvet.tar.xz";
    PKG_CORE="Velvet";
    # Install
    target_core;
  fi;
  if [ "$supported_wellbeing_config" == "$supported_target" ]; then
    # Only Android SDK 29 and 28, support Google's Wellbeing
    if [ "$android_sdk" == "$supported_sdk_v29" ] || [ "$android_sdk" == "$supported_sdk_v28" ]; then
      ui_print "Installing Wellbeing Google";
      # Remove pre-install Wellbeing
      rm -rf $SYSTEM/app/Wellbeing*
      rm -rf $SYSTEM/app/wellbeing*
      rm -rf $SYSTEM/priv-app/Wellbeing*
      rm -rf $SYSTEM/priv-app/wellbeing*
      rm -rf $SYSTEM/product/app/Wellbeing*
      rm -rf $SYSTEM/product/app/wellbeing*
      rm -rf $SYSTEM/product/priv-app/Wellbeing*
      rm -rf $SYSTEM/product/priv-app/wellbeing*
      # Set install variable
      ADDON_CORE="priv_app_WellbeingPrebuilt.tar.xz";
      PKG_CORE="WellbeingPrebuilt";
      # Install
      target_core;
    fi;
  fi;
  ui_print " ";
  ui_print "Done";
}

# Install config dependent packages
on_addon_install() {
  if [ "$addon_config" == "true" ]; then
    set_addon_install;
  else
    echo "ERROR: Config file not found" >> $ADDON_CONFIG;
  fi;
}

# Enable Google Assistant
set_assistant() {
  insert_line $SYSTEM/build.prop "ro.opa.eligible_device=true" after 'net.bt.name=Android' 'ro.opa.eligible_device=true';
}

# Battery Optimization for GMS Core and its components
opt_v28() {
  if [ "$android_sdk" == "$supported_sdk_v28" ]; then
    cp -f $TMP/pm.sh $SYSTEM/bin/pm.sh
    chmod 0755 $SYSTEM/bin/pm.sh
    chcon -h u:object_r:system_file:s0 "$SYSTEM/bin/pm.sh";
  else
    echo "ERROR: Unsupported component for Android SDK $android_sdk" >> $OPTv28;
  fi;
}

# Delete existing GMS Doze entry from all XML files
# This function should be executed before 'post_install()' function
opt_v29() {
  if [ "$android_sdk" == "$supported_sdk_v29" ]; then
    sed -i '/allow-in-power-save package="com.google.android.gms"/d' $SYSTEM/etc/permissions/*.xml
    sed -i '/allow-in-power-save package="com.google.android.gms"/d' $SYSTEM/etc/sysconfig/*.xml
  else
    echo "ERROR: Unsupported component for Android SDK $android_sdk" >> $OPTv29;
  fi;
}

# Remove Privileged App Whitelist property with flag enforce
purge_whitelist_permission() {
  if [ -n "$(cat $SYSTEM/build.prop | grep control_privapp_permissions)" ]; then
    grep -v "$PROPFLAG" $SYSTEM/build.prop > $TMP/build.prop
    rm -rf $SYSTEM/build.prop
    cp -f $TMP/build.prop $SYSTEM/build.prop
    chmod 0644 $SYSTEM/build.prop
    rm -rf $TMP/build.prop
  else
    echo "ERROR: Unable to find Whitelist property in 'system'" >> $whitelist;
  fi;
  if [ -f "$SYSTEM/product/build.prop" ]; then
    if [ -n "$(cat $SYSTEM/product/build.prop | grep control_privapp_permissions)" ]; then
      mkdir $TMP/product
      grep -v "$PROPFLAG" $SYSTEM/product/build.prop > $TMP/product/build.prop
      rm -rf $SYSTEM/product/build.prop
      cp -f $TMP/product/build.prop $SYSTEM/product/build.prop
      chmod 0644 $SYSTEM/product/build.prop
      rm -rf $TMP/product/build.prop
    else
      echo "ERROR: Unable to find Whitelist property in 'Product'" >> $whitelist;
    fi;
  else
    echo "ERROR: unable to find product 'build.prop'" >> $whitelist;
  fi;
  if [ -f $SYSTEM/etc/prop.default ]; then
    if [ -n "$(cat $SYSTEM/etc/prop.default | grep control_privapp_permissions)" ]; then
      if [ -f "$ANDROID_ROOT/default.prop" ]; then
        SYMLINK="true";
      else
        SYMLINK="false";
      fi;
      grep -v "$PROPFLAG" $SYSTEM/etc/prop.default > $TMP/prop.default
      rm -rf $SYSTEM/etc/prop.default
      if [ "$SYMLINK" == "true" ]; then
        rm -rf $ANDROID_ROOT/default.prop
      fi;
      cp -f $TMP/prop.default $SYSTEM/etc/prop.default
      chmod 0644 $SYSTEM/etc/prop.default
      if [ "$SYMLINK" == "true" ]; then
        ln -sfnv $SYSTEM/etc/prop.default $ANDROID_ROOT/default.prop
      fi;
      rm -rf $TMP/prop.default
    else
      echo "ERROR: Unable to find Whitelist property in 'system_root'" >> $whitelist;
    fi;
  else
    echo "ERROR: unable to find 'prop.default'" >> $whitelist;
  fi;
  if [ "$device_vendorpartition" == "true" ]; then
    if [ -n "$(cat $VENDOR/build.prop | grep control_privapp_permissions)" ]; then
      grep -v "$PROPFLAG" $VENDOR/build.prop > $TMP/build.prop
      rm -rf $VENDOR/build.prop
      cp -f $TMP/build.prop $VENDOR/build.prop
      chmod 0644 $VENDOR/build.prop
      rm -rf $TMP/build.prop
    else
      echo "ERROR: Unable to find Whitelist property in 'vendor'" >> $whitelist;
    fi;
  else
    echo "ERROR: No vendor partition present" >> $whitelist;
  fi;
}

# Add Whitelist property with flag disable in system
set_whitelist_permission() {
  insert_line $SYSTEM/build.prop "ro.control_privapp_permissions=disable" after 'net.bt.name=Android' 'ro.control_privapp_permissions=disable';
}

# Apply safetynet patch
cts_patch_system() {
  # Ext Build fingerprint
  if [ -n "$(cat $SYSTEM/build.prop | grep ro.system.build.fingerprint)" ]; then
    grep -v "$CTS_DEFAULT_SYSTEM_EXT_BUILD_FINGERPRINT" $SYSTEM/build.prop > $TMP/build.prop
    rm -rf $SYSTEM/build.prop
    cp -f $TMP/build.prop $SYSTEM/build.prop
    chmod 0644 $SYSTEM/build.prop
    rm -rf $TMP/build.prop
    insert_line $SYSTEM/build.prop "$CTS_SYSTEM_EXT_BUILD_FINGERPRINT" after 'ro.system.build.date.utc=' "$CTS_SYSTEM_EXT_BUILD_FINGERPRINT";
  else
    echo "ERROR: Unable to find target property'ro.system.build.fingerprint'" >> $TARGET_SYSTEM;
  fi;
  # Build fingerprint
  if [ -n "$(cat $SYSTEM/build.prop | grep ro.build.fingerprint)" ]; then
    grep -v "$CTS_DEFAULT_SYSTEM_BUILD_FINGERPRINT" $SYSTEM/build.prop > $TMP/build.prop
    rm -rf $SYSTEM/build.prop
    cp -f $TMP/build.prop $SYSTEM/build.prop
    chmod 0644 $SYSTEM/build.prop
    rm -rf $TMP/build.prop
    insert_line $SYSTEM/build.prop "$CTS_SYSTEM_BUILD_FINGERPRINT" after 'ro.build.description=' "$CTS_SYSTEM_BUILD_FINGERPRINT";
  else
    echo "ERROR: Unable to find target property 'ro.build.fingerprint'" >> $TARGET_SYSTEM;
  fi;
  # Build security patch
  if [ -n "$(cat $SYSTEM/build.prop | grep ro.build.version.security_patch)" ]; then
    grep -v "$CTS_DEFAULT_SYSTEM_BUILD_SEC_PATCH" $SYSTEM/build.prop > $TMP/build.prop
    rm -rf $SYSTEM/build.prop
    cp -f $TMP/build.prop $SYSTEM/build.prop
    chmod 0644 $SYSTEM/build.prop
    rm -rf $TMP/build.prop
    insert_line $SYSTEM/build.prop "$CTS_SYSTEM_BUILD_SEC_PATCH" after 'ro.build.version.release=' "$CTS_SYSTEM_BUILD_SEC_PATCH";
  else
    echo "ERROR: Unable to find target property 'ro.build.version.security_patch'" >> $TARGET_SYSTEM;
  fi;
  # Build type
  if [ -n "$(cat $SYSTEM/build.prop | grep ro.build.type=userdebug)" ]; then
    grep -v "$CTS_DEFAULT_SYSTEM_BUILD_TYPE" $SYSTEM/build.prop > $TMP/build.prop
    rm -rf $SYSTEM/build.prop
    cp -f $TMP/build.prop $SYSTEM/build.prop
    chmod 0644 $SYSTEM/build.prop
    rm -rf $TMP/build.prop
    insert_line $SYSTEM/build.prop "$CTS_SYSTEM_BUILD_TYPE" after 'ro.build.date.utc=' "$CTS_SYSTEM_BUILD_TYPE";
  else
    echo "ERROR: Unable to find target property with type 'userdebug'" >> $TARGET_SYSTEM;
  fi;
}

# Apply safetynet patch
cts_patch_vendor() {
  if [ "$device_vendorpartition" == "true" ]; then
    # Build security patch
    if [ -n "$(cat $VENDOR/build.prop | grep ro.vendor.build.security_patch)" ]; then
      grep -v "$CTS_DEFAULT_VENDOR_BUILD_SEC_PATCH" $VENDOR/build.prop > $TMP/build.prop
      rm -rf $VENDOR/build.prop
      cp -f $TMP/build.prop $VENDOR/build.prop
      chmod 0644 $VENDOR/build.prop
      rm -rf $TMP/build.prop
      insert_line $VENDOR/build.prop "$CTS_VENDOR_BUILD_SEC_PATCH" after 'ro.product.first_api_level=' "$CTS_VENDOR_BUILD_SEC_PATCH";
    else
      echo "ERROR: Unable to find target property 'ro.vendor.build.security_patch'" >> $TARGET_VENDOR;
    fi;
    # Build fingerprint
    if [ -n "$(cat $VENDOR/build.prop | grep ro.vendor.build.fingerprint)" ]; then
      grep -v "$CTS_DEFAULT_VENDOR_BUILD_FINGERPRINT" $VENDOR/build.prop > $TMP/build.prop
      rm -rf $VENDOR/build.prop
      cp -f $TMP/build.prop $VENDOR/build.prop
      chmod 0644 $VENDOR/build.prop
      rm -rf $TMP/build.prop
      insert_line $VENDOR/build.prop "$CTS_VENDOR_BUILD_FINGERPRINT" after 'ro.vendor.build.date.utc=' "$CTS_VENDOR_BUILD_FINGERPRINT";
    else
      echo "ERROR: Unable to find target property 'ro.vendor.build.fingerprint'" >> $TARGET_VENDOR;
    fi;
    # Build bootimage
    if [ -n "$(cat $VENDOR/build.prop | grep ro.bootimage.build.fingerprint)" ]; then
      grep -v "$CTS_DEFAULT_VENDOR_BUILD_BOOTIMAGE" $VENDOR/build.prop > $TMP/build.prop
      rm -rf $VENDOR/build.prop
      cp -f $TMP/build.prop $VENDOR/build.prop
      chmod 0644 $VENDOR/build.prop
      rm -rf $TMP/build.prop
      insert_line $VENDOR/build.prop "$CTS_VENDOR_BUILD_BOOTIMAGE" after 'ro.bootimage.build.date.utc=' "$CTS_VENDOR_BUILD_BOOTIMAGE";
    else
      echo "ERROR: Unable to find target property 'ro.bootimage.build.fingerprint'" >> $TARGET_VENDOR;
    fi;
  else
    echo "ERROR: No vendor partition present" >> $PARTITION;
  fi;
}

# Apply Privileged permission patch
whitelist_patch() {
  purge_whitelist_permission;
  set_whitelist_permission;
}

# Check whether CTS config file present in device or not
get_cts_config() {
  if [ -f $INTERNAL/cts-config.prop ]; then
    cts_config="true";
  else
    cts_config="false";
  fi;
}

# Apply CTS patch function
cts_patch() {
  # Guard CTS function for samsung device
  if [ "$android_product" == "$supported_product" ]; then
    echo "CTS Patch disabled for Product : $android_product" >> $CTS_PATCH;
  else
    if [ "$cts_config" == "true" ]; then
      if [ "$supported_cts_config" == "$supported_target" ]; then
        if [ "$android_sdk" == "$supported_sdk_v29" ]; then
          cts_patch_system;
          cts_patch_vendor;
        else
          echo "ERROR: Safetynet patch is limited to 'Android 10' only" >> $CTS_PATCH;
        fi;
      else
        echo "ERROR: Config property set to 'false'" >> $CTS_PATCH;
      fi;
    else
      echo "ERROR: Config file not found" >> $CTS_PATCH;
    fi;
  fi;
}

# API fixes
sdk_fix() {
  if [ "$android_sdk" -ge "26" ]; then # Android 8.0+ uses 0600 for its permission on build.prop
    chmod 0600 $SYSTEM/build.prop
    if [ -f "$SYSTEM/etc/prop.default" ]; then
      chmod 0600 $SYSTEM/etc/prop.default
    fi;
    if [ -f "$SYSTEM/product/build.prop" ]; then
      chmod 0600 $SYSTEM/product/build.prop
    fi;
    if [ "$device_vendorpartition" = "true" ]; then
      chmod 0600 $VENDOR/build.prop
    fi;
  fi;
}

# SELinux security context
selinux_fix() {
  chcon -h u:object_r:system_file:s0 "$SYSTEM/build.prop";
  if [ -f $SYSTEM/etc/prop.default ]; then
    chcon -h u:object_r:system_file:s0 "$SYSTEM/etc/prop.default";
  fi;
  if [ -f "$SYSTEM/product/build.prop" ]; then
    chcon -h u:object_r:system_file:s0 "$SYSTEM/product/build.prop";
  fi;
  if [ "$device_vendorpartition" == "true" ]; then
    chcon -h u:object_r:vendor_file:s0 "$VENDOR/build.prop";
  fi;
}

# Print config installation
config_info() {
  ui_print " ";
  ui_print "Config Installation";
  if [ "$setup_config" == "true" ] || [ "$cts_config" == "true" ]; then
    ui_print "True";
  else
    ui_print "False";
  fi;
}

# Addon installation script
addon_inst() {
  rm -rf $SYSTEM/bin/curl
  cp -f $TMP/curl $SYSTEM/bin/curl
  chmod 0755 $SYSTEM/bin/curl
  chcon -h u:object_r:system_file:s0 "$SYSTEM/bin/curl";
  rm -rf $SYSTEM/bin/addon.sh
  cp -f $TMP/addon.sh $SYSTEM/bin/addon.sh
  chmod 0755 $SYSTEM/bin/addon.sh
  chcon -h u:object_r:system_file:s0 "$SYSTEM/bin/addon.sh";
}

# Addon OTA survival function
addon_restore() {
  if [ "$SYSTEM_DATA" == "true" ]; then
    if [ -f $INTERNAL/addon/VelvetPrebuilt.tar.xz ]; then
      if [ "$android_sdk" == "$supported_sdk_v29" ]; then
        tar -xf $INTERNAL/addon/VelvetPrebuilt.tar.xz -C $SYSTEM/product/priv-app
        chmod 0755 $SYSTEM/product/priv-app/Velvet
        chmod 0644 $SYSTEM/product/priv-app/Velvet/Velvet.apk
        chcon -h u:object_r:system_file:s0 "$SYSTEM/product/priv-app/Velvet";
        chcon -h u:object_r:system_file:s0 "$SYSTEM/product/priv-app/Velvet/Velvet.apk";
      else
        tar -xf $INTERNAL/addon/VelvetPrebuilt.tar.xz -C $SYSTEM/priv-app
        chmod 0755 $SYSTEM/priv-app/Velvet
        chmod 0644 $SYSTEM/priv-app/Velvet/Velvet.apk
        chcon -h u:object_r:system_file:s0 "$SYSTEM/priv-app/Velvet";
        chcon -h u:object_r:system_file:s0 "$SYSTEM/priv-app/Velvet/Velvet.apk";
      fi;
    fi;
    if [ -f $INTERNAL/addon/WellbeingPrebuilt.tar.xz ]; then
      if [ "$android_sdk" == "$supported_sdk_v29" ]; then
        tar -xf $INTERNAL/addon/WellbeingPrebuilt.tar.xz -C $SYSTEM/product/priv-app
        chmod 0755 $SYSTEM/product/priv-app/WellbeingPrebuilt
        chmod 0644 $SYSTEM/product/priv-app/WellbeingPrebuilt/WellbeingPrebuilt.apk
        chcon -h u:object_r:system_file:s0 "$SYSTEM/product/priv-app/WellbeingPrebuilt";
        chcon -h u:object_r:system_file:s0 "$SYSTEM/product/priv-app/WellbeingPrebuilt/WellbeingPrebuilt.apk";
      fi;
      if [ "$android_sdk" == "$supported_sdk_v28" ]; then
        tar -xf $INTERNAL/addon/WellbeingPrebuilt.tar.xz -C $SYSTEM/priv-app
        chmod 0755 $SYSTEM/priv-app/WellbeingPrebuilt
        chmod 0644 $SYSTEM/priv-app/WellbeingPrebuilt/WellbeingPrebuilt.apk
        chcon -h u:object_r:system_file:s0 "$SYSTEM/priv-app/WellbeingPrebuilt";
        chcon -h u:object_r:system_file:s0 "$SYSTEM/priv-app/WellbeingPrebuilt/WellbeingPrebuilt.apk";
      fi;
    fi;
  fi;
}

print_build_info() {
  ui_print "Done";
  ui_print " ";
  ui_print "****************** Software *******************";
  ui_print "Custom GApps    : $PKG";
  ui_print "Android version : $VER";
  ui_print "Android Arch    : $ARCH";
  ui_print "SDK version     : $VER_SDK";
  ui_print "Build date      : $DATE";
  ui_print "Build ID        : $ID";
  ui_print "Developed By    : $AUTH";
  ui_print "***********************************************";
  ui_print " ";
}

# Set build defaults
build_info() {
  PKG="BiTGApps"
  VER=""
  ARCH=""
  DATE=""
  ID=""
  VER_SDK=""
  AUTH="TheHitMan @ xda-developers"
}

ui_print "Mount Partitions";

ui_print " ";

# These set of functions should be executed before any other install function
function pre_install() {
  if [ "$ZIPTYPE" == "addon" ]; then
    selinux;
    clean_logs;
    logd;
    on_sdk;
    on_partition_check;
    ab_partition;
    super_partition;
    early_umount;
    mount_all;
    system_layout;
    mount_stat;
    profile;
    on_target;
    on_version_check;
    on_platform_check;
  else
    selinux;
    clean_logs;
    logd;
    on_sdk;
    on_partition_check;
    # fstab;
    ab_partition;
    super_partition;
    early_umount;
    mount_all;
    system_layout;
    # boot_SAR;
    # boot_AB;
    # boot_A;
    # boot_SYS;
    # on_AB;
    mount_stat;
    profile;
    on_target;
    on_version_check;
    check_sdk;
    check_version;
    on_platform_check;
    on_platform;
    build_platform;
    check_platform;
    on_data_check;
    clean_inst;
  fi;
}
pre_install;

diskfree() {
  # Get the available space left on the device
  size=`df -k $ANDROID_ROOT | tail -n 1 | tr -s ' ' | cut -d' ' -f4`
  CAPACITY="200000";

  # Disk space in human readable format (k=1024)
  ds_hr=`df -h $ANDROID_ROOT | tail -n 1 | tr -s ' ' | cut -d' ' -f4`

  # Check if the available space is greater than 200MB (200000KB)
  ui_print "Checking System Space";
  if [[ "$size" -gt "$CAPACITY" ]]; then
    ui_print "$ds_hr";
    ui_print " ";
  else
    ui_print " ";
    ui_print "No space left in device. Aborting...";
    on_abort "Current space : $ds_hr";
    ui_print " ";
  fi;
}
if [ "$ZIPTYPE" == "basic" ]; then
  diskfree;
fi;

if [ "$ZIPTYPE" == "basic" ]; then
  ui_print "Installing";
fi;

# Do not merge 'pre_install' functions here
# Begin installation
function post_install() {
  if [ "$ZIPTYPE" == "addon" ]; then
    build_defaults;
    product_pathmap;
    system_pathmap;
    recovery_actions;
    mk_component;
    on_addon_check;
    get_addon_config;
    on_addon_install;
    on_installed;
    recovery_cleanup;
  else
    build_defaults;
    product_pathmap;
    system_pathmap;
    recovery_actions;
    mk_component;
    on_gsf_check;
    set_aosp_default;
    lim_aosp_install;
    pre_installed_v29;
    pre_installed_v28;
    pre_installed_v27;
    pre_installed_v25;
    sdk_v29_install;
    sdk_v28_install;
    sdk_v27_install;
    sdk_v25_install;
    runtime_permission;
    on_setup_check;
    on_pixel_check;
    get_setup_config;
    on_setup_install;
    # backup_script;
    set_assistant;
    opt_v28;
    opt_v29;
    on_whitelist_check;
    whitelist_patch;
    on_cts_check;
    on_product_check;
    get_cts_config;
    cts_patch;
    sdk_fix;
    selinux_fix;
    # sqlite_opt;
    # addon_inst;
    # addon_restore;
    # config_info;
    on_installed;
    recovery_cleanup;
  fi;
}
post_install; # end installation

# Do not parse this function
if [ "$ZIPTYPE" == "basic" ]; then
  build_info;
  print_build_info;
fi;

# end method