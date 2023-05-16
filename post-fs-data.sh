mount -o rw,remount /data
MODPATH=${0%/*}
AML=/data/adb/modules/aml
ACDB=/data/adb/modules/acdb

# debug
exec 2>$MODPATH/debug-pfsd.log
set -x

# run
FILE=$MODPATH/sepolicy.pfsd
if [ -f $FILE ]; then
  magiskpolicy --live --apply $FILE
fi

# context
chcon -R u:object_r:system_lib_file:s0 $MODPATH/system/lib*
chcon -R u:object_r:vendor_file:s0 $MODPATH/system/vendor
chcon -R u:object_r:vendor_configs_file:s0 $MODPATH/system/vendor/etc
chcon -R u:object_r:vendor_configs_file:s0 $MODPATH/system/vendor/odm/etc
chcon -R u:object_r:vendor_configs_file:s0 $MODPATH/system/odm/etc
chcon u:object_r:same_process_hal_file:s0 $MODPATH/system/vendor/lib*/libhidltransport.so
chcon u:object_r:same_process_hal_file:s0 $MODPATH/system/vendor/lib*/libhwbinder.so
chcon u:object_r:mediacodec_exec:s0 $MODPATH/system/vendor/bin/hw/vendor.ozoaudio.media.c2@*-service

# magisk
MAGISKPATH=`magisk --path`
if [ "$MAGISKPATH" ]; then
  MAGISKTMP=$MAGISKPATH/.magisk
  MIRROR=$MAGISKTMP/mirror
  ODM=$MIRROR/odm
  MY_PRODUCT=$MIRROR/my_product
fi

# path
ETC=`realpath /system/etc`
VETC=`realpath /vendor/etc`
VOETC=`realpath /vendor/odm/etc`
OETC=`realpath /odm/etc`
MPETC=`realpath /my_product/etc`
MODETC=$MODPATH/system/etc
MODVETC=$MODPATH/system/vendor/etc
MODVOETC=$MODPATH/system/vendor/odm/etc
MODOETC=$MODPATH/system/odm/etc
MODMPETC=$MODPATH/system/my_product/etc

# conflict
if [ -d $AML ] && [ ! -f $AML/disable ]\
&& [ -d $ACDB ] && [ ! -f $ACDB/disable ]; then
  touch $ACDB/disable
fi

# directory
SKU=`ls $VETC/audio | grep sku_`
if [ "$SKU" ]; then
  for SKUS in $SKU; do
    mkdir -p $MODVETC/audio/$SKUS
  done
fi
PROP=`getprop ro.build.product`
if [ -d $VETC/audio/"$PROP" ]; then
  mkdir -p $MODVETC/audio/"$PROP"
fi

# audio files
NAME="*audio*effects*.conf -o -name *audio*effects*.xml"
rm -f `find $MODPATH/system -type f -name $NAME`
A=`find $ETC -maxdepth 1 -type f -name $NAME`
VA=`find $VETC -maxdepth 1 -type f -name $NAME`
VOA=`find $VOETC -maxdepth 1 -type f -name $NAME`
VAA=`find $VETC/audio -maxdepth 1 -type f -name $NAME`
VBA=`find $VETC/audio/"$PROP" -maxdepth 1 -type f -name $NAME`
OA=`find $OETC -maxdepth 1 -type f -name $NAME`
MPA=`find $MPETC -maxdepth 1 -type f -name $NAME`
if [ "$A" ]; then
  cp -f $A $MODETC
fi
if [ "$VA" ]; then
  cp -f $VA $MODVETC
fi
if [ "$VOA" ]; then
  cp -f $VOA $MODVOETC
fi
if [ "$VAA" ]; then
  cp -f $VAA $MODVETC/audio
fi
if [ "$VBA" ]; then
  cp -f $VBA $MODVETC/audio/"$PROP"
fi
if [ "$SKU" ]; then
  for SKUS in $SKU; do
    VSA=`find $VETC/audio/$SKUS -maxdepth 1 -type f -name $NAME`
    if [ "$VSA" ]; then
      cp -f $VSA $MODVETC/audio/$SKUS
    fi
  done
fi
if [ "$OA" ]; then
  cp -f $OA $MODOETC
fi
if [ "$MPA" ]; then
  cp -f $MPA $MODMPETC
fi
if [ ! -d $ODM ] && [ -d /odm/etc ]\
&& [ "$OETC" == /odm/etc ] && [ "$OA" ]; then
  cp -f $OA $MODVETC
fi
if [ ! -d $MY_PRODUCT ] && [ -d /my_product/etc ]\
&& [ "$MPA" ]; then
  cp -f $MPA $MODVETC
fi
rm -f `find $MODPATH/system -type f -name *audio*effects*spatializer*.xml`

# run
. $MODPATH/.aml.sh

# cleaning
FILE=$MODPATH/cleaner.sh
if [ -f $FILE ]; then
  . $FILE
  rm -f $FILE
fi


