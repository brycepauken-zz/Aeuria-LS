#import <UIKit/UIKit.h>

@interface ALSCustomLockScreenContainer : UIView <UIScrollViewDelegate>

- (void)addNotificationView:(UIView *)notificationView;
- (void)resetView;
- (void)setPasscodeEntered:(void (^)(NSString *passcode))passcodeEntered;

@end
