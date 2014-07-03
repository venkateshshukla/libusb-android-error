#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include <android/log.h>
#include <jni.h>
#include <libusb-1.0/libusb.h>

#define LOG_TAG "venky: open_device"

#define LOG_D(...) __android_log_print(ANDROID_LOG_DEBUG, LOG_TAG, __VA_ARGS__)
#define LOG_E(...) __android_log_print(ANDROID_LOG_ERROR, LOG_TAG, __VA_ARGS__)
#define LOG_F(fn_name) __android_log_write(ANDROID_LOG_DEBUG, LOG_TAG, "Called : " fn_name )
#define LIBUSB_ERROR(x) LOG_E("%s\n", libusb_error_name(x))

#define VID 0x0403
#define PID 0x6001

static JavaVM *java_vm;

int open_usb_device();

jint JNI_OnLoad(JavaVM *vm, void *reserved)
{
	LOG_F ("JNI_OnLoad");
	java_vm = vm;

	// Get JNI Env for all function calls
	JNIEnv* env;
	if ((*vm)->GetEnv(vm, (void **) &env, JNI_VERSION_1_6) != JNI_OK) {
	    LOG_E ("GetEnv failed.");
	    return -1;
	}

	// Find the class calling native function
	jclass NativeUsb = (*env)->FindClass(env, "org/venky/Home");
	if (NativeUsb == NULL) {
		LOG_E ("FindClass failed : No class found.");
		return -1;
	}

	// Register native method for getUsbPermission
	JNINativeMethod nm[1] = {
		{ "openUsbDevice", "()I", open_usb_device}
	};

	if ((*env)->RegisterNatives(env, NativeUsb, nm , sizeof (nm) / sizeof (nm[0]))) {
	     LOG_E ("RegisterNatives Failed.");
	     return -1;
	}

	return JNI_VERSION_1_6;
}

int open_usb_device()
{
	int found = 0;
	libusb_context *context = NULL;
	libusb_device *dev, **devs;
	libusb_device_handle *handle = NULL;
	struct libusb_device_descriptor desc;
	int r, i, count;

	r = libusb_init(&context);
	if (r<0) goto OUT;

	libusb_set_debug(context, 2); //LIBUSB_LOG_LEVEL_WARNING

	count = libusb_get_device_list (context, &devs);
	r = count;
	if (count < 0) goto OUT;

	LOG_D ("Number of devices found : %d\n", count);

	for (i = 0; i < count; i++) {
		dev = devs[i];
		r = libusb_get_device_descriptor(dev, &desc);
		if (r < 0) goto OUT;
		if (desc.idVendor == VID && desc.idProduct == PID) {
			LOG_D ("We have found a matching device.\n");
			r = libusb_open(dev, &handle);
			if (r < 0) {
				goto OUT;
			}else {
				LOG_D ("Opening device successful.");
				found = 1;
			}
		} else {
			LOG_D ("Device not matched. VID : %04X, PID : %04X\n", desc.idVendor, desc.idProduct);
		}
	}
	libusb_free_device_list(devs, 1);
	libusb_exit(context);
	return (found == 0)? -1: 0;
OUT:
	LIBUSB_ERROR (r);
	if (devs) libusb_free_device_list(devs, 1);
	if (context) libusb_exit(context);
	return -1;
}

