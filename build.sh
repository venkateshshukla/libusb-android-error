#!/bin/bash
set -e

# Set the path to android ndk and sdk
export ANDROID_NDK=/android_ndk
export ANDROID_SDK=/android_sdk

# Get architecture from user
export ARCH=${1-x86}

if [ "$ARCH" = "arm" ] ;
then
	BUILDCHAIN=arm-linux-androideabi
	export TARGET_ARCH_ABI=armeabi-v7a
elif [ "$ARCH" = "x86" ] ;
then
	BUILDCHAIN=i686-linux-android
	export TARGET_ARCH_ABI=x86
fi

pushd crossbuild

# Initialise cross toolchain
if [ ! -e ndk-$ARCH ] ; then
	$ANDROID_NDK_ROOT/build/tools/make-standalone-toolchain.sh --system=linux-x86_64 --arch=$ARCH --install-dir=ndk-$ARCH --platform=android-19
fi

# Declare necessary variables for cross compilation
export BUILDROOT=$PWD
export PATH=${BUILDROOT}/ndk-$ARCH/bin:$PATH
export PREFIX=${BUILDROOT}/ndk-$ARCH/sysroot/usr
export PKG_CONFIG_PATH=${PREFIX}/lib/pkgconfig
export CC=${BUILDCHAIN}-gcc
export CXX=${BUILDCHAIN}-g++

if [ ! -e libusb-1.0.9.tar.bz2 ] ; then
	wget http://sourceforge.net/projects/libusb/files/libusb-1.0/libusb-1.0.9/libusb-1.0.9.tar.bz2
fi

if [ ! -e libusb-1.0.9 ] ; then
	tar -jxf libusb-1.0.9.tar.bz2
fi

if ! grep -q __ANDROID__ libusb-1.0.9/libusb/io.c ; then
	# patch libusb to build with android-ndk
	patch -p1 < libusb-1.0.9-android.patch  libusb-1.0.9/libusb/io.c
fi

if [ ! -e $PKG_CONFIG_PATH/libusb-1.0.pc ] ; then
	mkdir -p libusb-build-$ARCH
	pushd libusb-build-$ARCH
	../libusb-1.0.9/configure --host=${BUILDCHAIN} --prefix=${PREFIX} --enable-static --disable-shared
	make
	make install
	popd
fi

popd # From crossbuild

ndk-build -B V=1
ant debug install
adb shell am start -n org.venky/.Home
adb logcat -v threadtime | grep `adb shell ps | grep org.venky | cut -c 11-14`

