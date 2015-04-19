/*
 The SBLockScreenViewController manages the lock screen.
 Hooking it allows us to add our custom lock screen above
 and respond to events from the original lock screen.
 */

#import "SBLockScreenViewController.h"

#import <objc/runtime.h>
#import "ALSCustomLockScreen.h"

@interface SBLockScreenViewController()

@property (nonatomic, strong) ALSCustomLockScreen *customLockScreen;

- (void)addCustomLockScreenAboveView:(UIView *)view;

@end

%hook SBLockScreenViewController

/*
 We use associated objects to hold our custom lock screen as a property.
 This is the getter.
 */
%new
- (id)customLockScreen {
    return objc_getAssociatedObject(self, @selector(customLockScreen));
}

/*- (void)layoutSubviews {
    %orig;
    
    for(UIView *view in [[self lockScreenView] subviews]) {
        if(![view isKindOfClass:[ALSCustomLockScreen class]]) {
            [view setHidden:YES];
        }
    }
}*/

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
 We use associated objects to hold our custom lock screen as a property.
 This is the setter.
 */
%new
- (void)setCustomLockScreen:(id)customLockScreen {
    objc_setAssociatedObject(self, @selector(customLockScreen), customLockScreen, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

/*
 Called when the lock screen appears (other than the
 first time, which is handled by viewDidAppear).
 */
- (void)startLockScreenFadeInAnimationForSource:(int)arg1 {
    %orig;
    
    [self.customLockScreen resetView];
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
    
    //get objects
    //recursive dbug description?
    
    if(self.customLockScreen && self.customLockScreen.superview) {
        [self.customLockScreen removeFromSuperview];
    }
    
    self.customLockScreen = [[ALSCustomLockScreen alloc] initWithFrame:[[self lockScreenView] bounds]];
    [self.customLockScreen setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
    [self.customLockScreen.layer setZPosition:MAXFLOAT];
    [[self lockScreenView] addSubview:self.customLockScreen];
}

/*
 
Example Alert
 
UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Title" message:@"Message" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
[alertView performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
 
 */

%end
