#General Settings
ADDITIONAL_OBJCFLAGS = -fobjc-arc
ARCHS = armv7 arm64
TARGET = iphone:clang:latest:latest
THEOS_BUILD_DIR = ../Build

#The Tweak itself
TWEAK_NAME = AeuriaLS
AeuriaLS_FILES =\
   Tweak/ALSCustomLockScreen.x \
   Tweak/ALSCustomLockScreenClock.x \
   Tweak/ALSCustomLockScreenMask.x \
   Tweak/ALSPreferencesManager.x \
   Tweak/ALSProxyTarget.x \
   Tweak/SBChevronView.x \
   Tweak/SBFLockScreenDateView.x \
   Tweak/SBLockScreenScrollView.x \
   Tweak/SBLockScreenViewController.x \
   Tweak/SBWallpaperEffectView.x
AeuriaLS_FRAMEWORKS = CoreGraphics CoreText Foundation QuartzCore UIKit

#The Tweak's preferences
BUNDLE_NAME = AeuriaLSPreferences
AeuriaLSPreferences_FILES =\
   Preferences/ALSColorGradient.m \
   Preferences/ALSColorPanGestureRecognizer.m \
   Preferences/ALSColorPickerInnerShadow.m \
   Preferences/ALSPreferencesColorCell.m \
   Preferences/ALSPreferencesColorPicker.m \
   Preferences/ALSPreferencesHeader.m \
   Preferences/ALSPreferencesListController.m \
   Preferences/ALSPreferencesListItemsController.m \
   Preferences/ALSPreferencesProxyTarget.m \
   Preferences/ALSPreferencesSubListController.m
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
after-package::
#$(ECHO_NOTHING)rm -rf _$(ECHO_END)
	$(ECHO_NOTHING)mv $(THEOS_PACKAGE_DIR)/$(THEOS_PACKAGE_NAME)_$(_THEOS_INTERNAL_PACKAGE_VERSION)_$(THEOS_PACKAGE_ARCH).deb $(THEOS_PACKAGE_DIR)/$(TWEAK_NAME).deb$(ECHO_END)
#	$(ECHO_NOTHING)find $(THEOS_PACKAGE_DIR) ! -name '$(TWEAK_NAME).deb' -type f -exec rm -f {} +$(ECHO_END)
after-install::
	install.exec "killall -9 SpringBoard"