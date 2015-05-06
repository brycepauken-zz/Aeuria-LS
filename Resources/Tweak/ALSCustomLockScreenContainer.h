#import <UIKit/UIKit.h>

@interface ALSCustomLockScreenContainer : UIView <UIScrollViewDelegate>

- (void)resetView;
- (void)setPasscodeEntered:(void (^)(NSString *passcode))passcodeEntered;

@end
