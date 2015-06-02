#import <UIKit/UIKit.h>

/*
 The SBLockScreenViewController manages the lock screen.
 Hooking it allows us to respond to events from the lock screen.
 */

@interface SBLockScreenView : UIView

- (id)passcodeView;

@end

@interface SBLockScreenViewController : UIViewController

- (id)lockScreenScrollView;
- (id)lockScreenView;
- (long long)statusBarStyle;

- (id)customLockScreenContainer;
- (BOOL)customLockScreenHidden;
- (void)failedBio;
- (void)failedPasscode;
- (BOOL)isShowingMediaControls;
- (void)resetForScreenOff;
- (void)setCustomLockScreenHidden:(BOOL)hidden;
- (void)setNowPlayingPluginActive:(BOOL)active;
- (void)showEmergencyDialer;

@end
