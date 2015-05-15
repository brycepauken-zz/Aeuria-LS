#import <UIKit/UIKit.h>

@class ALSCustomLockScreen;

@interface ALSCustomLockScreenContainer : UIView <UIScrollViewDelegate>

- (void)addKeyboardView:(UIView *)keyboardView fromSuperView:(UIView *)superView;
- (void)addMediaControlsView:(UIView *)mediaControlsView fromSuperView:(UIView *)superView;
- (void)addNotificationView:(UIView *)notificationView fromSuperView:(UIView *)superView;
- (ALSCustomLockScreen *)customLockScreen;
- (void)notificationViewChanged;
- (void)removeAddedViews;
- (void)resetView;
- (UIScrollView *)scrollView;
- (void)setPasscodeEntered:(void (^)(NSString *passcode))passcodeEntered;
- (void)setPasscodeTextField:(UITextField *)passcodeTextField;

@end
