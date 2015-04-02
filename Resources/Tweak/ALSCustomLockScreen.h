#import <UIKit/UIKit.h>

/*
 The ALSCustomLockScreen view is our customized lock screen.
 It sits on top of the existing lock screen, which we still interact
 with for such purposes as forwarding passcodes so we don't have to handle them.
 */

@interface ALSCustomLockScreen : UIView <UIScrollViewDelegate>

//- (void)animateOut;
//- (void)setKeypadDelegate:(id<SBUIPasscodeLockNumberPad>)keypadDelegate;
- (void)resetView;
- (void)updateScrollPercentage:(CGFloat)percentage;

@end
