#General Settings
ADDITIONAL_OBJCFLAGS = -fobjc-arc
ARCHS = armv7 arm64
TARGET = iphone:clang:latest:latest
THEOS_BUILD_DIR = ../Build

#The Tweak itself
TWEAK_NAME = AeuriaLS
AeuriaLS_FILES = $(wildcard Tweak/*.x)
AeuriaLS_FRAMEWORKS = CoreGraphics CoreText Foundation QuartzCore UIKit

#The Tweak's preferences
BUNDLE_NAME = AeuriaLSPreferences
AeuriaLSPreferences_FILES = $(wildcard Preferences/*.m)
AeuriaLSPreferences_FRAMEWORKS = CoreGraphics Foundation QuartzCore UIKit
AeuriaLSPreferences_INSTALL_PATH = /Library/PreferenceBundles
AeuriaLSPreferences_PRIVATE_FRAMEWORKS = AppSupport Preferences
AeuriaLSPreferences_RESOURCE_DIRS = Preferences/Resources

#Compiling
include theos/makefiles/common.mk
#THEOS_STAGING_DIR = $(THEOS_BUILD_DIR)/Staging
include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/bundle.mk
internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp Preferences/Resources/Main.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/AeuriaLSPreferences.plist$(ECHO_END)
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/var/mobile/Library/Preferences/$(ECHO_END)
	$(ECHO_NOTHING)cp Preferences/Resources/Defaults.plist $(THEOS_STAGING_DIR)/var/mobile/Library/Preferences/com.brycepauken.aeurials.defaults.plist$(ECHO_END)
after-package::
	$(ECHO_NOTHING)mv $(THEOS_PACKAGE_DIR)/$(THEOS_PACKAGE_NAME)_$(_THEOS_INTERNAL_PACKAGE_VERSION)_$(THEOS_PACKAGE_ARCH).deb $(THEOS_PACKAGE_DIR)/$(TWEAK_NAME).deb$(ECHO_END)
after-install::
	install.exec "killall -9 SpringBoard"