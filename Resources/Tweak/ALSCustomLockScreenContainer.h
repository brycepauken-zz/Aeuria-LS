#import <UIKit/UIKit.h>

@class ALSCustomLockScreen;

@interface ALSCustomLockScreenContainer : UIView <UIScrollViewDelegate>

- (ALSCustomLockScreen *)customLockScreen;
- (void)notificationViewChanged;
- (void)resetView;
- (UIScrollView *)scrollView;
- (void)setKeyboardView:(UIView *)keyboardView;
- (void)setMediaControlsView:(UIView *)mediaControlsView;
- (void)setNotificationView:(UIView *)notificationView;
- (void)setPasscodeEntered:(void (^)(NSString *passcode))passcodeEntered;
- (void)setPasscodeTextField:(UITextField *)passcodeTextField;

@end
