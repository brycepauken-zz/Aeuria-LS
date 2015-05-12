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

- (void)addCustomLockScreen;
- (BOOL)customLockScreenHidden;

@end

%hook SBLockScreenViewController

%new
- (void)addCustomLockScreen {
    if([self customLockScreenHidden]) {
        return;
    }
    
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
 We use associated objects to hold our custom lock screen as a property.
 This is the getter.
 */
%new
- (id)customLockScreenContainer {
    return objc_getAssociatedObject(self, @selector(customLockScreenContainer));
}

%new
- (BOOL)customLockScreenHidden {
    NSNumber *customLockScreenHiddenNum = objc_getAssociatedObject(self, @selector(customLockScreenHidden));
    if(!customLockScreenHiddenNum) {
        objc_setAssociatedObject(self, @selector(customLockScreenHidden), @(NO), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return NO;
    }
    return [customLockScreenHiddenNum boolValue];
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

%new
- (void)setCustomLockScreenHidden:(BOOL)hidden {
    objc_setAssociatedObject(self, @selector(customLockScreenHidden), @(hidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [[self.customLockScreenContainer customLockScreen] setDisplayLinkPaused:hidden];
    if(hidden) {
        [self.customLockScreenContainer removeFromSuperview];
        [[self lockScreenScrollView] setHidden:NO];
    }
    else {
        [[self lockScreenScrollView] setHidden:YES];
        [self addCustomLockScreen];
    }
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
    
    [self addCustomLockScreen];
}

/*
 
Example Alert
 
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Title" message:@"Message" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:NO];
 
Example Logging
 
    [[self performSelector:@selector(recursiveDescription)] writeToFile:@"/var/mobile/Documents/out1.txt" atomically:NO encoding:NSStringEncodingConversionAllowLossy error:nil];
 
 */

%end
