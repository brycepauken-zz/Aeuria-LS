#import <UIKit/UIKit.h>

/*
 The ALSCustomLockScreen view is our customized lock screen.
 It sits on top of the existing lock screen, which we still interact
 with for such purposes as forwarding passcodes so we don't have to handle them.
 */

@interface ALSCustomLockScreen : UIView <UIScrollViewDelegate>

- (void)failedEntry;
- (void)resetView;
- (void)setDisplayLinkPaused:(BOOL)paused;
- (void)setPasscodeEntered:(void (^)(NSString *passcode))passcodeEntered;
- (void)setSecurityType:(NSInteger)securityType;
- (BOOL)shouldShowWithNotifications;
- (void)updateScrollPercentage:(CGFloat)percentage;

@end
