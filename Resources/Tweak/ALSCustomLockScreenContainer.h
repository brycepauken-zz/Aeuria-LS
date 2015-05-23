#import <UIKit/UIKit.h>

@class ALSCustomLockScreen;
@class SBLockScreenViewController;
@class SBUIPasscodeLockViewWithKeypad;

@interface ALSCustomLockScreenContainer : UIView <UIScrollViewDelegate>

@property (nonatomic, weak) UIView *keyboardView;
@property (nonatomic, weak) SBUIPasscodeLockViewWithKeypad *keypadView;
@property (nonatomic, weak) SBLockScreenViewController *lockScreenViewController;
@property (nonatomic, weak) UIView *mediaControlsView;
@property (nonatomic, weak) UIView *notificationView;
@property (nonatomic, weak) UITextField *passcodeTextField;

- (ALSCustomLockScreen *)customLockScreen;
- (void)mediaControlsBecameHidden:(BOOL)hidden;
- (void)notificationViewChanged;
- (void)resetView;
- (UIScrollView *)scrollView;
- (void)setPasscodeEntered:(void (^)(NSString *passcode))passcodeEntered;

@end
