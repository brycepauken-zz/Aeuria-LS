#import <UIKit/UIKit.h>

@class ALSCustomLockScreen;

@interface ALSCustomLockScreenContainer : UIView <UIScrollViewDelegate>

- (void)addMediaControlsView:(UIView *)mediaControlsView fromSuperView:(UIView *)superView;
- (void)addNotificationView:(UIView *)notificationView fromSuperView:(UIView *)superView;
- (ALSCustomLockScreen *)customLockScreen;;
- (void)notificationViewChanged;
- (void)resetView;
- (UIScrollView *)scrollView;
- (void)setPasscodeEntered:(void (^)(NSString *passcode))passcodeEntered;

@end
