TARGET = iphone:clang
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = ChromaHomeBarX
ChromaHomeBarX_FILES = ChromaHomeBarX.xm
ChromaHomeBarX_FRAMEWORKS = UIKit QuartzCore
ChromaHomeBarX_CFLAGS = -fobjc-arc -Wno-deprecated-declarations -std=c++11

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
SUBPROJECTS += chromahomebarx
include $(THEOS_MAKE_PATH)/aggregate.mk
