#import <UIKit/UIKit.h>

@class ALSCustomLockScreen;
@class MPUSystemMediaControlsView;
@class SBLockScreenViewController;
@class SBUIPasscodeLockViewWithKeypad;

@interface ALSCustomLockScreenContainer : UIView <UIScrollViewDelegate>

@property (nonatomic, weak) UIView *keyboardView;
@property (nonatomic, weak) SBUIPasscodeLockViewWithKeypad *keypadView;
@property (nonatomic) CGFloat lockScreenDateVerticalCenter;
@property (nonatomic, weak) SBLockScreenViewController *lockScreenViewController;
@property (nonatomic, weak) UIView *mediaControlsView;
@property (nonatomic) BOOL mediaControlsViewHidden;
@property (nonatomic, weak) UIView *notificationView;
@property (nonatomic) BOOL notificationViewHidden;
@property (nonatomic) BOOL nowPlayingPluginActive;
@property (nonatomic, weak) UITextField *passcodeTextField;
@property (nonatomic) NSInteger passcodeTextFieldCharacterCount;
@property (nonatomic) CGFloat percentage;

- (ALSCustomLockScreen *)customLockScreen;
- (void)lockScreenDateViewDidLayoutSubviews:(UIView *)lockScreenDateView;
- (void)mediaControlsDidHideOrShow;
- (void)notificationViewChanged;
- (void)resetView;
- (void)setNowPlayingPluginActive:(BOOL)active;
- (void)setPasscodeEntered:(void (^)(NSString *passcode))passcodeEntered;

@end
