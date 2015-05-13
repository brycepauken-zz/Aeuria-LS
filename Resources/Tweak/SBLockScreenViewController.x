/*
 The SBLockScreenViewController manages the lock screen.
 Hooking it allows us to add our custom lock screen above
 and respond to events from the original lock screen.
 */

#import "SBLockScreenViewController.h"

#import "ALSCustomLockScreen.h"
#import "ALSCustomLockScreenContainer.h"
#import "ALSCustomLockScreenMask.h"
#import "ALSHideableViewManager.h"
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
- (void)setHintGestureRecognizersEnabled:(BOOL)enabled;
- (void)updateSecurityType;

@end

%hook SBLockScreenViewController

%new
- (void)addCustomLockScreen {
    if([self customLockScreenHidden]) {
        return;
    }
    
    [self setHintGestureRecognizersEnabled:NO];
    [ALSHideableViewManager setShouldHide:YES];
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
    
    [self updateSecurityType];
    
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
    if([[self.customLockScreenContainer customLockScreen] shouldShowWithNotifications]) {
        [ALSHideableViewManager setShouldHide:YES];
        [[self lockScreenScrollView] setHidden:YES];
        [self setHintGestureRecognizersEnabled:NO];
        return;
    }
    
    objc_setAssociatedObject(self, @selector(customLockScreenHidden), @(hidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [[self.customLockScreenContainer customLockScreen] setDisplayLinkPaused:hidden];
    if(hidden) {
        [self.customLockScreenContainer removeFromSuperview];
        [ALSHideableViewManager setShouldHide:NO];
        [[self lockScreenScrollView] setHidden:NO];
        [self setHintGestureRecognizersEnabled:YES];
        if(self.customLockScreenContainer && self.customLockScreenContainer.superview) {
            [self.customLockScreenContainer removeFromSuperview];
        }
    }
    else {
        [ALSHideableViewManager setShouldHide:YES];
        [[self lockScreenScrollView] setHidden:YES];
        [self setHintGestureRecognizersEnabled:NO];
        [self addCustomLockScreen];
    }
}

%new
- (void)setHintGestureRecognizersEnabled:(BOOL)enabled {
    UIView *currentView = self.view;
    while(currentView) {
        for(UIGestureRecognizer *gestureRecognizer in currentView.gestureRecognizers) {
            if([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]] || [gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
                [gestureRecognizer setEnabled:enabled];
            }
        }
        currentView = currentView.superview;
    }
}

/*
 Called when the lock screen appears (other than the
 first time, which is handled by viewDidAppear).
 */
- (void)startLockScreenFadeInAnimationForSource:(int)arg1 {
    %orig;
    
    [self setHintGestureRecognizersEnabled:![[self lockScreenScrollView] isHidden]];
    [self updateSecurityType];
    [self.customLockScreenContainer resetView];
}

/*
 Simply hides the statusbar on the lock screen.
 */
- (long long)statusBarStyle {
    return 3;
}

%new
- (void)updateSecurityType {
    ALSLockScreenSecurityType securityType = ALSLockScreenSecurityTypeNone;
    for(UIView *view in [[self lockScreenScrollView] subviews]) {
        if([view isKindOfClass:[%c(SBUIPasscodeLockViewSimple4DigitKeypad) class]]) {
            securityType = ALSLockScreenSecurityTypeCode;
            break;
        }
        else if([view isKindOfClass:[%c(SBUIPasscodeLockViewWithKeyboard) class]]) {
            securityType = ALSLockScreenSecurityTypePhrase;
            break;
        }
    }
    [self.customLockScreenContainer.customLockScreen setSecurityType:securityType];
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
