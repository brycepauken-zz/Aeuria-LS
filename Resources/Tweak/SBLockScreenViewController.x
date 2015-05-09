/*
 The SBLockScreenViewController manages the lock screen.
 Hooking it allows us to add our custom lock screen above
 and respond to events from the original lock screen.
 */

#import "SBLockScreenViewController.h"

#import "ALSCustomLockScreen.h"
#import "ALSCustomLockScreenContainer.h"
#import "ALSProxyPasscodeHandler.h"
#import "SBLockScreenScrollView.h"
#import "SBUIPasscodeLockViewBase.h"
#import <objc/runtime.h>

@interface SBLockScreenViewController()

@property (nonatomic, strong) ALSCustomLockScreenContainer *customLockScreenContainer;

- (void)passcodeLockViewPasscodeEnteredViaMesa:(id)arg1;
- (void)passcodeLockViewPasscodeEntered:(id)arg1;
- (void)passcodeLockViewPasscodeDidChange:(id)arg1;

- (void)addCustomLockScreenScrollViewAboveView:(UIView *)view;

@end

%hook SBLockScreenViewController

- (void)passcodeLockViewPasscodeEntered:(id)arg1 {
    %orig;
}

/*
 We use associated objects to hold our custom lock screen as a property.
 This is the getter.
 */
%new
- (id)customLockScreenContainer {
    return objc_getAssociatedObject(self, @selector(customLockScreenContainer));
}

%new
- (void)failedBio {
    [self.customLockScreenContainer.customLockScreen failedEntry];
}

%new
- (void)failedPasscode {
    [self.customLockScreenContainer.customLockScreen failedEntry];
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
    
    [self.customLockScreenContainer resetView];
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
    
    __weak SBLockScreenViewController *weakSelf = self;
    self.customLockScreenContainer = [[ALSCustomLockScreenContainer alloc] initWithFrame:[[self lockScreenView] bounds]];
    [self.customLockScreenContainer setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
    [self.customLockScreenContainer setPasscodeEntered:^(NSString *passcode) {
        //create a proxy passcode handler (returns the entered passcode, forwards all other requests)
        id passcodeView = [[weakSelf lockScreenView] passcodeView];
        ALSProxyPasscodeHandler *proxyPasscodeHandler = [[ALSProxyPasscodeHandler alloc] init];
        [proxyPasscodeHandler setPasscode:passcode];
        [proxyPasscodeHandler setPasscodeView:passcodeView];
        [weakSelf passcodeLockViewPasscodeEntered:proxyPasscodeHandler];
    }];
    [self.customLockScreenContainer.layer setZPosition:MAXFLOAT];
    
    [[[self lockScreenScrollView] superview] addSubview:self.customLockScreenContainer];
}

/*
 
Example Alert
 
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Title" message:@"Message" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
 
Example Logging
 
    [[self performSelector:@selector(recursiveDescription)] writeToFile:@"/var/mobile/Documents/out1.txt" atomically:NO encoding:NSStringEncodingConversionAllowLossy error:nil];
 
 */

%end
