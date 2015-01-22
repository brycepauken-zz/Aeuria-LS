#import "SBLockScreenViewController.h"

#import <objc/runtime.h>
#import "ALSCustomLockScreen.h"

@interface SBLockScreenViewController()

@property (nonatomic, strong) ALSCustomLockScreen *customLockScreen;

- (void)addCustomLockScreenToWindow:(UIWindow *)window;

@end

%hook SBLockScreenViewController

/*
 Called when the device is about to unlock.
 Just tell our custom lock screen to go away.
 */
- (void)finishUIUnlockFromSource:(int)source {
    if(self.customLockScreen) {
        [self.customLockScreen animateOut];
    }
}

/*
 Called when the main lock screen scroll view is scrolling.
 Passes a percentage argument that represents, on a scale of 0-1
 (not including bouncing past that scale), how far the user has
 scrolled from the default position to the passcode view.
 */
- (void)lockScreenViewDidScrollWithNewScrollPercentage:(CGFloat)percentage tracking:(BOOL)tracking {
    if(self.customLockScreen) {
        [self.customLockScreen updateScrollPercentage:percentage];
    }
}

/*
 Called when the lock screen appears (other than the
 first time, which is handled by viewDidAppear).
 */
- (void)startLockScreenFadeInAnimationForSource:(int)arg1 {
    %orig;
    
    UIView *lockScreenView = [self lockScreenView];
    if(lockScreenView) {
        NSArray *windows = [[UIApplication sharedApplication].windows sortedArrayUsingComparator:^NSComparisonResult(UIWindow *win1, UIWindow *win2) {
            return win2.windowLevel - win1.windowLevel;
        }];
        
        //hide all windows higher than the lock screen
        //(namely a window that appears temporarily as part of the fade in animation)
        for(int i=0;i<windows.count;i++) {
            if([windows objectAtIndex:i]==lockScreenView.window) {
                break;
            }
            [[windows objectAtIndex:i] setHidden:YES];
        }
        
        [self addCustomLockScreenToWindow:lockScreenView.window];
    }
}

/*
 Simply hides the statusbar on the lock screen.
 */
- (long long)statusBarStyle {
    return 3;
}

/*
 Called when the lock screen first appears. Add our
 custom lock screen to the top of its window.
 */
- (void)viewDidAppear:(BOOL)view {
    %orig;
    
    [self addCustomLockScreenToWindow:[[self view] window]];
}

/*
 Add our custom lock screen to the given window.
 We create the custom lock screen first if needed,
 make sure it's in the right window, and then add it.
 */
%new
- (void)addCustomLockScreenToWindow:(UIWindow *)window {
    if(!self.customLockScreen) {
        self.customLockScreen = [[ALSCustomLockScreen alloc] initWithFrame:window.bounds];
        [self.customLockScreen.layer setZPosition:MAXFLOAT];
    }
    else {
        [self.customLockScreen resetView];
    }
    
    if([self.customLockScreen superview]) {
        [self.customLockScreen removeFromSuperview];
    }
    
    [window addSubview:self.customLockScreen];
}

/*
 We use associated objects to hold our custom lock screen as a property.
 This is the getter.
 */
%new
- (id)customLockScreen {
    return objc_getAssociatedObject(self, @selector(customLockScreen));
}

/*
 We use associated objects to hold our custom lock screen as a property.
 This is the setter.
 */
%new
- (void)setCustomLockScreen:(id)customLockScreen {
    objc_setAssociatedObject(self, @selector(customLockScreen), customLockScreen, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

%end
