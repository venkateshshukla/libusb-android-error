LOCAL_PATH := $(call my-dir)
LIB_PATH := ../crossbuild/ndk-$(ARCH)/sysroot/usr/lib
INCLUDE_PATH := $(LOCAL_PATH)/../crossbuild/ndk-$(ARCH)/sysroot/usr/include

include $(CLEAR_VARS)
LOCAL_MODULE    := prebuilt_libusb
LOCAL_SRC_FILES := $(LIB_PATH)/libusb-1.0.a
include $(PREBUILT_STATIC_LIBRARY)

include $(CLEAR_VARS)
LOCAL_MODULE := venky
LOCAL_SRC_FILES := open_device.c
LOCAL_LDLIBS := -llog
LOCAL_C_INCLUDES := $(INCLUDE_PATH)
LOCAL_WHOLE_STATIC_LIBRARIES := prebuilt_libusb
include $(BUILD_SHARED_LIBRARY)

