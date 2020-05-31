#!/sbin/sh
#
# ADDOND_VERSION=2
#
# BiTGApps Unified addon.d script
#

. /tmp/backuptool.functions

if [ -z $backuptool_ab ]; then
  SYS=$S
  TMP=/tmp
else
  SYS=/postinstall/system
  TMP=/postinstall/tmp
fi;

list_files() {
cat << EOF
app/FaceLock/FaceLock.apk
app/GoogleCalendarSyncAdapter/GoogleCalendarSyncAdapter.apk
app/GoogleContactsSyncAdapter/GoogleContactsSyncAdapter.apk
app/GoogleExtShared/GoogleExtShared.apk
app/MarkupGoogle/MarkupGoogle.apk
app/SoundPickerPrebuilt/SoundPickerPrebuilt.apk
priv-app/ConfigUpdater/ConfigUpdater.apk
priv-app/GoogleBackupTransport/GoogleBackupTransport.apk
priv-app/GoogleExtServices/GoogleExtServices.apk
priv-app/GoogleLoginService/GoogleLoginService.apk
priv-app/GoogleRestore/GoogleRestore.apk
priv-app/GoogleServicesFramework/GoogleServicesFramework.apk
priv-app/Phonesky/Phonesky.apk
priv-app/PrebuiltGmsCore/PrebuiltGmsCore.apk
priv-app/PrebuiltGmsCorePi/PrebuiltGmsCorePi.apk
priv-app/PrebuiltGmsCorePix/PrebuiltGmsCorePix.apk
priv-app/PrebuiltGmsCorePix/PrebuiltGmsCoreQt.apk
priv-app/SetupWizard/SetupWizard.apk
priv-app/Velvet/Velvet.apk
priv-app/WellbeingPrebuilt/WellbeingPrebuilt.apk
etc/default-permissions/default-permissions.xml
etc/default-permissions/opengapps-permissions.xml
etc/permissions/com.google.android.dialer.support.xml
etc/permissions/com.google.android.maps.xml
etc/permissions/com.google.android.media.effects.xml
etc/permissions/privapp-permissions-google.xml
etc/permissions/split-permissions-google.xml
etc/preferred-apps/google.xml
etc/sysconfig/dialer_experience.xml
etc/sysconfig/google.xml
etc/sysconfig/google_build.xml
etc/sysconfig/google_exclusives_enable.xml
etc/sysconfig/google-hiddenapi-package-whitelist.xml
etc/sysconfig/pixel_experience_2017.xml
etc/sysconfig/pixel_experience_2018.xml
etc/sysconfig/pixel_experience_2019_midyear.xml
etc/sysconfig/pixel_experience_2019.xml
etc/sysconfig/whitelist_com.android.omadm.service.xml
etc/g.prop
framework/com.google.android.dialer.support.jar
framework/com.google.android.maps.jar
framework/com.google.android.media.effects.jar
lib/libfilterpack_facedetect.so
lib/libfrsdk.so
lib/libsketchology_native.so
lib64/libfacenet.so
lib64/libfilterpack_facedetect.so
lib64/libfrsdk.so  
lib64/libjni_latinimegoogle.so
lib64/libsketchology_native.so
xbin/pm.sh
EOF
}

# Get ROM SDK from installed GApps
API="$(cd $SYS; grep "^ro.build.version.sdk" build.prop | cut -d '=' -f 2)"

case "$1" in
  backup)
    list_files | while read -r FILE DUMMY; do
      backup_file "$S"/"$FILE"
    done
  ;;
  restore)
    list_files | while read -r FILE REPLACEMENT; do
      R=""
      [ -n "$REPLACEMENT" ] && R="$S/$REPLACEMENT"
      [ -f "$C/$S/$FILE" ] && restore_file "$S"/"$FILE" "$R"
    done
  ;;
  pre-backup)
    # Stub
  ;;
  post-backup)
    # Stub
  ;;
  pre-restore)
    # Stub
    rm -rf $SYS/product/app/ManagedProvisioning
    rm -rf $SYS/product/app/Provision
    rm -rf $SYS/product/priv-app/ManagedProvisioning
    rm -rf $SYS/product/priv-app/Provision
    rm -rf $SYS/app/ExtShared
    rm -rf $SYS/app/ManagedProvisioning
    rm -rf $SYS/app/Provision
    rm -rf $SYS/priv-app/ExtServices
    rm -rf $SYS/priv-app/ManagedProvisioning
    rm -rf $SYS/priv-app/Provision
    rm -rf $SYS/app/GoogleCalendarSyncAdapter
    rm -rf $SYS/app/GoogleContactsSyncAdapter
    rm -rf $SYS/app/ExtShared
    rm -rf $SYS/app/GoogleExtShared
    rm -rf $SYS/app/GooglePrintRecommendationService
    rm -rf $SYS/app/MarkupGoogle
    rm -rf $SYS/app/SoundPickerPrebuilt
    rm -rf $SYS/priv-app/CarrierSetup
    rm -rf $SYS/priv-app/ConfigUpdater
    rm -rf $SYS/priv-app/GmsCoreSetupPrebuilt
    rm -rf $SYS/priv-app/ExtServices
    rm -rf $SYS/priv-app/GoogleExtServices
    rm -rf $SYS/priv-app/GoogleExtServicesPrebuilt
    rm -rf $SYS/priv-app/GoogleServicesFramework
    rm -rf $SYS/priv-app/Phonesky
    rm -rf $SYS/priv-app/PrebuiltGmsCoreQt
    rm -rf $SYS/framework/com.google.android.dialer.support.jar
    rm -rf $SYS/framework/com.google.android.maps.jar
    rm -rf $SYS/framework/com.google.android.media.effects.jar
    rm -rf $SYS/lib/libsketchology_native.so
    rm -rf $SYS/lib64/libjni_latinimegoogle.so
    rm -rf $SYS/lib64/libsketchology_native.so
    rm -rf $SYS/etc/sysconfig/dialer_experience.xml
    rm -rf $SYS/etc/sysconfig/google.xml
    rm -rf $SYS/etc/sysconfig/google_build.xml
    rm -rf $SYS/etc/sysconfig/google_vr_build.xml
    rm -rf $SYS/etc/sysconfig/google_exclusives_enable.xml
    rm -rf $SYS/etc/sysconfig/google-hiddenapi-package-whitelist.xml
    rm -rf $SYS/etc/sysconfig/nexus.xml
    rm -rf $SYS/etc/sysconfig/nga.xml
    rm -rf $SYS/etc/sysconfig/pixel_experience_2017.xml
    rm -rf $SYS/etc/sysconfig/pixel_experience_2018.xml
    rm -rf $SYS/etc/sysconfig/pixel_experience_2019_midyear.xml
    rm -rf $SYS/etc/sysconfig/pixel_experience_2019.xml
    rm -rf $SYS/etc/sysconfig/whitelist_com.android.omadm.service.xml
    rm -rf $SYS/etc/default-permissions/default-permissions.xml
    rm -rf $SYS/etc/default-permissions/opengapps-permissions.xml
    rm -rf $SYS/etc/permissions/com.google.android.dialer.support.xml
    rm -rf $SYS/etc/permissions/com.google.android.maps.xml
    rm -rf $SYS/etc/permissions/com.google.android.media.effects.xml
    rm -rf $SYS/etc/permissions/GoogleExtServices_permissions.xml
    rm -rf $SYS/etc/permissions/GooglePermissionController_permissions.xml
    rm -rf $SYS/etc/permissions/privapp-permissions-google.xml
    rm -rf $SYS/etc/permissions/privapp-permissions-google-p.xml
    rm -rf $SYS/etc/permissions/privapp-permissions-google-ps.xml
    rm -rf $SYS/etc/permissions/split-permissions-google.xml
    rm -rf $SYS/etc/preferred-apps/google.xml
    rm -rf $SYS/etc/g.prop
    rm -rf $SYS/product/app/arcore
    rm -rf $SYS/product/app/CalculatorGooglePrebuilt
    rm -rf $SYS/product/app/CalendarGooglePrebuilt
    rm -rf $SYS/product/app/Chrome
    rm -rf $SYS/product/app/GoogleContacts
    rm -rf $SYS/product/app/GoogleContactsSyncAdapter
    rm -rf $SYS/product/app/GoogleTTS
    rm -rf $SYS/product/app/LatinIMEGooglePrebuilt
    rm -rf $SYS/product/app/LocationHistoryPrebuilt
    rm -rf $SYS/product/app/MarkupGoogle
    rm -rf $SYS/product/app/NgaResources
    rm -rf $SYS/product/app/PrebuiltBugle
    rm -rf $SYS/product/app/Photos
    rm -rf $SYS/product/app/PrebuiltDeskClockGoogle
    rm -rf $SYS/product/app/SoundPickerPrebuilt
    rm -rf $SYS/product/app/TrichromeLibrary
    rm -rf $SYS/product/app/talkback
    rm -rf $SYS/product/app/WebViewGoogle
    rm -rf $SYS/product/priv-app/AndroidMigratePrebuilt
    rm -rf $SYS/product/priv-app/AndroidPlatformServices
    rm -rf $SYS/product/priv-app/CarrierServices
    rm -rf $SYS/product/priv-app/ConfigUpdater
    rm -rf $SYS/product/priv-app/ConnMetrics
    rm -rf $SYS/product/priv-app/GoogleDialer
    rm -rf $SYS/product/priv-app/GoogleFeedback
    rm -rf $SYS/product/priv-app/GoogleOneTimeInitializer
    rm -rf $SYS/product/priv-app/GooglePartnerSetup
    rm -rf $SYS/product/priv-app/GoogleServicesFramework
    rm -rf $SYS/product/priv-app/Phonesky
    rm -rf $SYS/product/priv-app/PixelSetupWizard
    rm -rf $SYS/product/priv-app/PrebuiltGmsCoreQt
    rm -rf $SYS/product/priv-app/RecorderPrebuilt
    rm -rf $SYS/product/priv-app/SetupWizardPrebuilt
    rm -rf $SYS/product/priv-app/TipsPrebuilt
    rm -rf $SYS/product/priv-app/TurboPrebuilt
    rm -rf $SYS/product/priv-app/Velvet
    rm -rf $SYS/product/priv-app/WallpaperPickerGoogleRelease
    rm -rf $SYS/product/priv-app/WellbeingPrebuilt
    rm -rf $SYS/product/framework/com.google.android.dialer.support.jar
    rm -rf $SYS/product/framework/com.google.android.maps.jar
    rm -rf $SYS/product/framework/com.google.android.media.effects.jar
    rm -rf $SYS/product/lib/libbarhopper.so
    rm -rf $SYS/product/lib/libsketchology_native.so
    rm -rf $SYS/product/lib64/libbarhopper.so
    rm -rf $SYS/product/lib64/libsketchology_native.so
    rm -rf $SYS/product/etc/sysconfig/dialer_experience.xml
    rm -rf $SYS/product/etc/sysconfig/google.xml
    rm -rf $SYS/product/etc/sysconfig/google_build.xml
    rm -rf $SYS/product/etc/sysconfig/google_vr_build.xml
    rm -rf $SYS/product/etc/sysconfig/google_exclusives_enable.xml
    rm -rf $SYS/product/etc/sysconfig/google-hiddenapi-package-whitelist.xml
    rm -rf $SYS/product/etc/sysconfig/nexus.xml
    rm -rf $SYS/product/etc/sysconfig/nga.xml
    rm -rf $SYS/product/etc/sysconfig/pixel_experience_2017.xml
    rm -rf $SYS/product/etc/sysconfig/pixel_experience_2018.xml
    rm -rf $SYS/product/etc/sysconfig/pixel_experience_2019_midyear.xml
    rm -rf $SYS/product/etc/sysconfig/pixel_experience_2019.xml
    rm -rf $SYS/product/etc/sysconfig/whitelist_com.android.omadm.service.xml
    rm -rf $SYS/product/etc/default-permissions/default-permissions.xml
    rm -rf $SYS/product/etc/default-permissions/opengapps-permissions.xml
    rm -rf $SYS/product/etc/permissions/com.google.android.dialer.support.xml
    rm -rf $SYS/product/etc/permissions/com.google.android.maps.xml
    rm -rf $SYS/product/etc/permissions/com.google.android.media.effects.xml
    rm -rf $SYS/product/etc/permissions/GoogleExtServices_permissions.xml
    rm -rf $SYS/product/etc/permissions/GooglePermissionController_permissions.xml
    rm -rf $SYS/product/etc/permissions/privapp-permissions-google.xml
    rm -rf $SYS/product/etc/permissions/privapp-permissions-google-p.xml
    rm -rf $SYS/product/etc/permissions/privapp-permissions-google-ps.xml
    rm -rf $SYS/product/etc/permissions/split-permissions-google.xml
    rm -rf $SYS/product/etc/preferred-apps/google.xml
  ;;
  post-restore)
    # Stub
    for i in $(list_files); do
      chown root:root "$SYS/$i"
      chmod 644 "$SYS/$i"
      chmod 755 "$(dirname "$SYS/$i")"
    done
    if [ "$API" -ge "26" ]; then # Android 8.0+ uses 0600 for its permission on build.prop
      chmod 600 "$SYS/build.prop"
    fi
    if [ "$API" = "27" ] || [ "$API" = "25" ]; then
      mkdir $SYS/app/FaceLock/lib
      mkdir $SYS/app/FaceLock/lib/arm64
      chmod 0755 $SYS/app/FaceLock/lib
      chmod 0755 $SYS/app/FaceLock/lib/arm64
      ln -sfnv /system/lib64/libfacenet.so /system/app/FaceLock/lib/arm64/libfacenet.so
    fi;
  ;;
esac
