/*
 The SBLockScreenViewController manages the lock screen.
 Hooking it allows us to add our custom lock screen above
 and respond to events from the original lock screen.
 */

#import "SBLockScreenViewController.h"

#import "ALSCustomLockScreenContainer.h"
#import <objc/runtime.h>

@interface SBLockScreenViewController()

@property (nonatomic, strong) ALSCustomLockScreenContainer *customLockScreenContainer;

- (void)addCustomLockScreenScrollViewAboveView:(UIView *)view;

@end

%hook SBLockScreenViewController

/*
 We use associated objects to hold our custom lock screen as a property.
 This is the getter.
 */
%new
- (id)customLockScreenContainer {
    return objc_getAssociatedObject(self, @selector(customLockScreenContainer));
}

/*
 We use associated objects to hold our custom lock screen as a property.
 This is the setter.
 */
%new
- (void)setCustomLockScreenContainer:(id)customLockScreenContainer {
    objc_setAssociatedObject(self, @selector(customLockScreenContainer), customLockScreenContainer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

/*
 Called when the lock screen appears (other than the
 first time, which is handled by viewDidAppear).
 */
- (void)startLockScreenFadeInAnimationForSource:(int)arg1 {
    %orig;
    
    //[self.customLockScreen resetView];
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
    
    
    if(self.customLockScreenContainer && self.customLockScreenContainer.superview) {
        [self.customLockScreenContainer removeFromSuperview];
    }
    
    self.customLockScreenContainer = [[ALSCustomLockScreenContainer alloc] initWithFrame:[[self lockScreenView] bounds]];
    [self.customLockScreenContainer setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
    [self.customLockScreenContainer.layer setZPosition:MAXFLOAT];
    
    [[self lockScreenView] addSubview:self.customLockScreenContainer];
}

/*
 
Example Alert
 
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Title" message:@"Message" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
 
Example Logging
 
    [[self performSelector:@selector(recursiveDescription)] writeToFile:@"/var/mobile/Documents/out1.txt" atomically:NO encoding:NSStringEncodingConversionAllowLossy error:nil];
 
 */

%end
