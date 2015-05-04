#import <UIKit/UIKit.h>

@interface ALSCustomLockScreenContainer : UIView <UIScrollViewDelegate>

- (void)setPasscodeEntered:(void (^)(NSString *passcode))passcodeEntered;

@end
