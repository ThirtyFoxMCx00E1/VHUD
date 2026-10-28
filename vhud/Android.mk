LOCAL_PATH := $(call my-dir)

# libVHUD32.so for armeabi-v7a, libVHUD64.so for arm64-v8a
include $(CLEAR_VARS)
LOCAL_CPP_EXTENSION := .cpp .cc
ifeq ($(TARGET_ARCH_ABI),armeabi-v7a)
    LOCAL_MODULE := VHUD32
    LOCAL_CFLAGS   += -mfloat-abi=softfp -mthumb
    LOCAL_CXXFLAGS += -mfloat-abi=softfp -mthumb
else
    LOCAL_MODULE := VHUD64
endif

# every .cpp in src/ (and one level below) + AML's logger/config helpers
LOCAL_SRC_FILES := $(patsubst $(LOCAL_PATH)/%,%,$(wildcard $(LOCAL_PATH)/src/*.cpp $(LOCAL_PATH)/src/*/*.cpp))
LOCAL_SRC_FILES += mod/logger.cpp mod/config.cpp

LOCAL_CFLAGS   += -O2 -DNDEBUG
LOCAL_CXXFLAGS += -O2 -DNDEBUG -std=c++17 -fexceptions
LOCAL_C_INCLUDES += $(LOCAL_PATH) $(LOCAL_PATH)/include $(LOCAL_PATH)/psdk $(LOCAL_PATH)/AArchASMHelper
LOCAL_LDLIBS += -llog -ldl -landroid -lEGL -lGLESv2
include $(BUILD_SHARED_LIBRARY)
