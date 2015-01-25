#import <UIKit/UIKit.h>

/*
 The SBLockScreenViewController manages the lock screen.
 Hooking it allows us to respond to events from the lock screen.
 */

@interface SBLockScreenViewController : NSObject

- (void)finishUIUnlockFromSource:(int)source;
- (id)lockScreenScrollView;
- (id)lockScreenView;
- (void)lockScreenViewDidScrollWithNewScrollPercentage:(CGFloat)percentage tracking:(BOOL)tracking;
- (void)startLockScreenFadeInAnimationForSource:(int)arg1;
- (long long)statusBarStyle;
- (UIView *)view;
- (void)viewWillAppear:(BOOL)view;

@end

