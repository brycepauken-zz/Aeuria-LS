#import <UIKit/UIKit.h>

@interface ALSCustomLockScreenContainer : UIView <UIScrollViewDelegate>

- (void)addMediaControlsView:(UIView *)mediaControlsView;
- (void)addNotificationView:(UIView *)notificationView;
- (void)notificationViewChanged;
- (void)resetView;
- (UIScrollView *)scrollView;
- (void)setPasscodeEntered:(void (^)(NSString *passcode))passcodeEntered;

@end
