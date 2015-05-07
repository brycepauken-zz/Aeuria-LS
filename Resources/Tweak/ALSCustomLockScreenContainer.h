#import <UIKit/UIKit.h>

@interface ALSCustomLockScreenContainer : UIView <UIScrollViewDelegate>

- (void)addMediaControlsView:(UIView *)mediaControlsView fromSuperView:(UIView *)superView;
- (void)addNotificationView:(UIView *)notificationView fromSuperView:(UIView *)superView;
- (void)notificationViewChanged;
- (void)resetView;
- (UIScrollView *)scrollView;
- (void)setPasscodeEntered:(void (^)(NSString *passcode))passcodeEntered;

@end
