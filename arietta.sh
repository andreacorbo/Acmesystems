#! /bin/sh
# comment out YYLTYPE yylloc; in buildroot-at91/output/build/host-dtc-1-5-1/dtc-lexer.l
# comment out YYLTYPE yylloc; in buildroot-at91/output/build/$LINUX_TAG/scripts/dtc/dtc-lexer.l
# rootfs image size is in genimage.cfg
# sudo apt -y install sed make binutils build-essential diffutils gcc g++ bash patch gzip bzip2 perl tar cpio unzip rsync file bc findutils


### Defines local variables ####################################################
BOARD=arietta
ROOT=$PWD/$BOARD

BUILDROOT=buildroot-at91  # Buildroot dir.
BUILDROOT_TAG=linux4sam-2022.04
BUILDROOT_EXTERNAL=buildroot-external-microchip  # Microchip external dir.
BUILDROOT_TARGET=arietta-g25
BUILDROOT_DEFCONFIG=acmesystems_arietta_g25_256mb_defconfig

BOOTSTRAP=at91bootstrap
BOOTSTRAP_TAG=3.10.4
BOOTSTRAP_TARGET=arietta-256m
BOOTSTRAP_CONFIGS=contrib/board/acme/at91sam9x5_arietta/
BOOTSTRAP_DEFCONFIG=arietta-256m_defconfig

KERNEL=linux-5.15-mchp
KERNEL_TARGET=acme-arietta

COMPILER=arm-linux-gnueabi-

BOOT=boot  # Boot partition mountpoint.
ROOTFS=rootfs  # Rootfs partition mountpoint.

buildroot=false
bootstrap=false
kernel=false
write=false
target=false
config=false

while getopts "f b w k t: c:" options; do
  case "${options}" in
    f) buildroot=true;;
    b) bootstrap=true;;
    k) kernel=true;;
    w) write=true;;
    t) target=${OPTARG};;
    c) config=${OPTARG};;
  esac
done

if [ $target != false ]; then

  BUILD=$BOARD'-'$target

else

  BUILD=$BOARD

fi

CONFIGS=$PWD/configs/$BUILD  # Configs are stored outside the build dir.

if [ ! -d $CONFIGS ]; then

  mkdir $CONFIGS

  mkdir $CONFIGS/rootfs_overlay

fi


if $bootstrap; then
  ### Compiling AT91bootstrap ####################################################
  #
  #
  #
  #
  #
  if [ ! -d $ROOT/$BOOTSTRAP ]; then

    cd $ROOT

    git clone https://github.com/linux4sam/at91bootstrap.git

    cd $ROOT/$BOOTSTRAP

    git checkout tags/v$BOOTSTRAP_TAG

    TAG=$( echo $BOOTSTRAP_TAG | sed -e "s/[.]/_/g" )

    wget https://www.acmesystems.it/www/at91bootstrap_$TAG/acme.patch
    
    patch -p1 < acme.patch
    
  fi

    cp -fv $CONFIGS/$BOOTSTRAP_DEFCONFIG $ROOT/$BOOTSTRAP/$BOOTSTRAP_CONFIGS  # Copy the br defconfig

    cd $ROOT/$BOOTSTRAP

    make $BOOTSTRAP_DEFCONFIG

    make menuconfig

    make savedefconfig

    cp -fv defconfig $CONFIGS/$BOOTSTRAP_DEFCONFIG  # Backup the bs defconfig

    make CROSS_COMPILE=$COMPILER
fi


if $buildroot; then
  ### Creates RootFS ####################################################
  #
  #
  #
  #
  #
  if [ ! -d $ROOT/$BUILDROOT ]; then
    
    cd $ROOT
    
    git clone https://github.com/linux4sam/buildroot-external-microchip.git -b $BUILDROOT_TAG
    
    git clone https://github.com/linux4sam/buildroot-at91.git -b $BUILDROOT_TAG
    
    cd $ROOT/$BUILDROOT
    
    wget https://raw.githubusercontent.com/AcmeSystems/acmepatches/master/buildroot-at91-2020.04.patch
    
    patch -p1 < buildroot-at91-2020.04.patch
    #sed -i "s|BR2_LINUX_KERNEL_CUSTOM_REPO_VERSION=\"linux4sam_6.1\"|BR2_LINUX_KERNEL_CUSTOM_REPO_VERSION=\"linux4sam_6.2\"|g" ./configs/$BUILDROOT_DEFCONFIG'_defconfig'
    #sed -i "s|BR2_LINUX_KERNEL_DEFCONFIG=\"roadrunner\"|BR2_LINUX_KERNEL_DEFCONFIG=\"acme-roadrunner\"|g" ./configs/$BUILDROOT_DEFCONFIG'_defconfig'
    #sed -i "s|BR2_LINUX_KERNEL_INTREE_DTS_NAME=\"at91-sama5d2_roadrunner\"|BR2_LINUX_KERNEL_INTREE_DTS_NAME=\"acme-roadrunner\"|g" ./configs/$BUILDROOT_DEFCONFIG'_defconfig'
    #sed -i "s|\"at91-sama5d2_roadrunner.dtb\",|\"acme-roadrunner.dtb\",|g" ./configs/$BUILDROOT_DEFCONFIG'_defconfig'

    mkdir $ROOT/$BUILDROOT/TARGETS
  
  fi

  if [ ! -d $ROOT/$BUILDROOT/TARGETS/$BUILD ]; then

    mkdir $ROOT/$BUILDROOT/TARGETS/$BUILD

  fi

  rm -rfv $ROOT/$BUILDROOT/board/acmesystems/$BUILDROOT_TARGET/rootfs_overlay

  cp -rvL $CONFIGS/rootfs_overlay $ROOT/$BUILDROOT/board/acmesystems/$BUILDROOT_TARGET/  # Copy the root-overlays

  if [ $config != false ]; then

    cp -rvL $CONFIGS/root/$config/* $ROOT/$BUILDROOT/board/acmesystems/$BUILDROOT_TARGET/rootfs_overlay/root/  # Copy the specific root content
  
  fi

  #touch $ROOT/$BUILDROOT/board/acmesystems/$BUILDROOT_TARGET/rootfs_overlay/etc/hostname  # Create hostname file
  
  #echo $config > $ROOT/$BUILDROOT/board/acmesystems/$BUILDROOT_TARGET/rootfs_overlay/etc/hostname  # Set the hostname

  cp -fv $CONFIGS/genimage.cfg $ROOT/$BUILDROOT/board/acmesystems/$BUILDROOT_TARGET/  # Copy the genimage.cfg

  cp -fv $CONFIGS/$BUILDROOT_DEFCONFIG $ROOT/$BUILDROOT/configs/  # Copy the br defconfig

  cd $ROOT/$BUILDROOT

  make O=TARGETS/$BUILD $BUILDROOT_DEFCONFIG

  make O=TARGETS/$BUILD BR2_EXTERNAL=$ROOT/$BUILDROOT_EXTERNAL menuconfig

  make O=TARGETS/$BUILD savedefconfig

  cp -fv $ROOT/$BUILDROOT/configs/$BUILDROOT_DEFCONFIG $CONFIGS/  # Backup the br defconfig

  make O=TARGETS/$BUILD BR2_EXTERNAL=$ROOT/$BUILDROOT_EXTERNAL
fi


if $kernel; then
  ### Compiling Kernel ####################################################
  #
  #
  #
  #
  #

  if [ ! -d $ROOT/$KERNEL ]; then

    cd $ROOT

    wget https://github.com/linux4microchip/linux/archive/refs/heads/$KERNEL.zip

    unzip $KERNEL.zip
    
    mv linux-$KERNEL $KERNEL

  fi

  if [ ! -f  $CONFIGS/$KERNEL_TARGET'_defconfig' ]; then

    wget https://www.acmesystems.it/www/compile_kernel_5_15/$KERNEL_TARGET'_defconfig' -O $CONFIGS/$KERNEL_TARGET'_defconfig'
  
  fi

  if [ ! -f  $CONFIGS/$KERNEL_TARGET.dts ]; then

    wget https://www.acmesystems.it/www/compile_kernel_5_15/$KERNEL_TARGET.dts -O $CONFIGS/$KERNEL_TARGET.dts
  
  fi

  if [ ! -f  $CONFIGS/cmdline.txt ]; then
    
    wget https://www.acmesystems.it/www/compile_kernel_5_15/$KERNEL_TARGET'_cmdline.txt' -O $CONFIGS/cmdline.txt
  
  fi

  cp -fv $CONFIGS/$KERNEL_TARGET'_defconfig' $ROOT/$KERNEL/arch/arm/configs/$KERNEL_TARGET'_defconfig'

  cp -fv $CONFIGS/$KERNEL_TARGET.dts $ROOT/$KERNEL/arch/arm/boot/dts/$KERNEL_TARGET.dts

  cd $ROOT/$KERNEL

  make ARCH=arm CROSS_COMPILE=$COMPILER $KERNEL_TARGET'_defconfig'

  make ARCH=arm menuconfig

  make ARCH=arm savedefconfig

  mv arch/arm/configs/$KERNEL_TARGET'_defconfig' arch/arm/configs/$KERNEL_TARGET'_defconfig_original'

  cp -fv defconfig arch/arm/configs/$KERNEL_TARGET'_defconfig'

  cp -fv defconfig $CONFIGS/$KERNEL_TARGET'_defconfig'
    
  sed -i "s|#define ATMEL_MAX_UART.*|#define ATMEL_MAX_UART 10|g" drivers/tty/serial/atmel_serial.c
  
  rm -fv arch/arm/boot/dts/$KERNEL_TARGET.dtb
  
  make ARCH=arm CROSS_COMPILE=$COMPILER $KERNEL_TARGET.dtb

  make -j8 ARCH=arm CROSS_COMPILE=$COMPILER zImage

  make modules -j8 ARCH=arm CROSS_COMPILE=$COMPILER 

  make modules_install INSTALL_MOD_PATH=./modules ARCH=arm

fi


if $write; then
  ### Creates SD #################################################################
  #
  #
  #
  #
  #
  mkdir $ROOT/$BOOT

  mkdir $ROOT/$ROOTFS

  sudo mount -v /dev/mmcblk0p1 $ROOT/$BOOT

  sudo mount -v /dev/mmcblk0p2 $ROOT/$ROOTFS
  
  sudo rm -rfv $ROOT/$BOOT/*

  cp -fv $ROOT/$BOOTSTRAP/binaries/boot.bin $ROOT/$BOOT

  cp -fv $ROOT/$KERNEL/arch/arm/boot/dts/$KERNEL_TARGET.dtb $ROOT/$BOOT

  cp -fv $ROOT/$KERNEL/arch/arm/boot/zImage $ROOT/$BOOT  
  
  cp -fv $CONFIGS/cmdline.txt $ROOT/$BOOT/
  
  sudo find $ROOT/$ROOTFS -mindepth 1 -delete

  sudo tar xf $ROOT/$BUILDROOT/TARGETS/$BUILD/images/rootfs.tar -C $ROOT/$ROOTFS

  sudo rsync -avc $ROOT/$KERNEL/modules/lib/. $ROOT/$ROOTFS/lib/.

  sudo chown -R root:root $ROOT/$ROOTFS/lib

  sudo chown -R root:root $ROOT/$ROOTFS/root

  sudo chmod go-w $ROOT/$ROOTFS/root
  
  sudo chmod 700 $ROOT/$ROOTFS/root/.ssh

  sudo chmod 600 $ROOT/$ROOTFS/root/.ssh/authorized_keys

  sudo chmod 0600 $ROOT/$ROOTFS/etc/ssh/ssh_host_dsa_key

  sudo chmod 0600 $ROOT/$ROOTFS/etc/ssh/ssh_host_ecdsa_key

  sudo chmod 0600 $ROOT/$ROOTFS/etc/ssh/ssh_host_ed25519_key

  sudo chmod 0600 $ROOT/$ROOTFS/etc/ssh/ssh_host_rsa_key

  sudo umount -v /dev/mmcblk0p1

  sudo rm -rfv $ROOT/$BOOT

  sudo umount -v /dev/mmcblk0p2

  sudo rm -rfv $ROOT/$ROOTFS

fi
