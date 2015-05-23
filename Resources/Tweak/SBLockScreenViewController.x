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

@interface SBUIPasscodeLockViewSimple4DigitKeypad

- (void)_noteStringEntered:(id)arg1 eligibleForPlayingSounds:(BOOL)arg2;

@end

@interface SBLockScreenViewController()

@property (nonatomic, strong) ALSCustomLockScreenContainer *customLockScreenContainer;

- (void)passcodeLockViewEmergencyCallButtonPressed:(id)arg1;
- (void)passcodeLockViewPasscodeEnteredViaMesa:(id)arg1;
- (void)passcodeLockViewPasscodeEntered:(id)arg1;
- (void)passcodeLockViewPasscodeDidChange:(id)arg1;

- (void)addCustomLockScreen;
- (id)customProperties;
- (id)findViewOfClass:(Class)class inView:(UIView *)view maxDepth:(int)depth;
- (void)setHintGestureRecognizersEnabled:(BOOL)enabled;
- (void)updateSecurityType;

@end

%hook SBLockScreenViewController

- (void)_mediaControlsDidHideOrShow:(id)arg1 {
    %orig;
    
    BOOL shouldHide = [[arg1 name] hasSuffix:@"Hide"];
    [[self customProperties] setObject:@(shouldHide) forKey:@"MediaControlsShouldHide"];
    [self.customLockScreenContainer mediaControlsBecameHidden:shouldHide];
}

%new
- (void)addCustomLockScreen {
    if([self customLockScreenHidden]) {
        return;
    }
    
    UIView *keyboardView = [self.customLockScreenContainer keyboardView];
    UIView *mediaControlsView = [self.customLockScreenContainer mediaControlsView];
    UIView *notificationView = [self.customLockScreenContainer notificationView];
    UITextField *passcodeTextField = [self.customLockScreenContainer passcodeTextField];
    
    BOOL shouldHideMediaControls = NO;
    NSNumber *shouldHideMediaControlsNum = [[self customProperties] objectForKey:@"MediaControlsShouldHide"];
    if(shouldHideMediaControlsNum) {
        shouldHideMediaControls = [shouldHideMediaControlsNum boolValue];
    }
    
    [self setHintGestureRecognizersEnabled:NO];
    [ALSHideableViewManager setShouldHide:YES];
    if(self.customLockScreenContainer) {
        if(self.customLockScreenContainer.superview) {
            [self.customLockScreenContainer removeFromSuperview];
        }
    }
    
    __weak SBLockScreenViewController *weakSelf = self;
    self.customLockScreenContainer = [[ALSCustomLockScreenContainer alloc] initWithFrame:[[self lockScreenView] bounds]];
    [self.customLockScreenContainer setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
    [self.customLockScreenContainer setKeyboardView:keyboardView];
    [self.customLockScreenContainer setMediaControlsView:mediaControlsView];
    [self.customLockScreenContainer setNotificationView:notificationView];
    [self.customLockScreenContainer setPasscodeTextField:passcodeTextField];
    [self.customLockScreenContainer setPasscodeEntered:^(NSString *passcode) {
        //create a proxy passcode handler (returns the entered passcode, forwards all other requests)
        id passcodeView = [[weakSelf lockScreenView] passcodeView];
        ALSProxyPasscodeHandler *proxyPasscodeHandler = [[ALSProxyPasscodeHandler alloc] init];
        [proxyPasscodeHandler setPasscode:passcode];
        [proxyPasscodeHandler setPasscodeView:passcodeView];
        [weakSelf passcodeLockViewPasscodeEntered:proxyPasscodeHandler];
    }];
    [self.customLockScreenContainer mediaControlsBecameHidden:shouldHideMediaControls];
    
    [self updateSecurityType];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self updateSecurityType];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self updateSecurityType];
    });
    
    [[[self lockScreenScrollView] superview] insertSubview:self.customLockScreenContainer belowSubview:[self lockScreenScrollView]];
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
- (id)customProperties {
    id customProperties;
    @synchronized(self) {
        customProperties = objc_getAssociatedObject(self, @selector(customProperties));
        if(!customProperties) {
            customProperties = [[NSMutableDictionary alloc] init];
            objc_setAssociatedObject(self, @selector(customProperties), customProperties, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
    return customProperties;
}

%new
- (void)failedBio {
    [[self.customLockScreenContainer customLockScreen] failedEntry];
}

%new
- (void)failedPasscode {
    [[self.customLockScreenContainer customLockScreen] failedEntry];
}

%new
- (id)findViewOfClass:(Class)class inView:(UIView *)view maxDepth:(int)depth {
    if (depth == 0 || [view isKindOfClass:[ALSCustomLockScreenContainer class]]) {
        return nil;
    }
    
    NSInteger count = depth;
    while(count > 0) {
        for(UIView *subview in view.subviews) {
            if ([subview isKindOfClass:class]) {
                return subview;
            }
        }
        
        count--;
        for(UIView *subview in view.subviews) {
            UIView *notificationView = [self findViewOfClass:class inView:subview maxDepth:count];
            if(notificationView) {
                return notificationView;
            }
        }
    }
    
    return nil;
}

%new
- (void)resetForScreenOff {
    if(self.customLockScreenContainer && self.customLockScreenContainer.superview) {
        [self.customLockScreenContainer removeFromSuperview];
    }
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
        [[self lockScreenScrollView] setShouldHideSubviews:YES];
        [self setHintGestureRecognizersEnabled:NO];
        return;
    }
    
    objc_setAssociatedObject(self, @selector(customLockScreenHidden), @(hidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [[self.customLockScreenContainer customLockScreen] setDisplayLinkPaused:hidden];
    if(hidden) {
        [self.customLockScreenContainer removeFromSuperview];
        [ALSHideableViewManager setShouldHide:NO];
        [[self lockScreenScrollView] setShouldHideSubviews:NO];
        [self setHintGestureRecognizersEnabled:YES];
    }
    else {
        [ALSHideableViewManager setShouldHide:YES];
        [[self lockScreenScrollView] setShouldHideSubviews:YES];
        [self setHintGestureRecognizersEnabled:NO];
        [self addCustomLockScreen];
    }
    [[self lockScreenScrollView] layoutSubviews];
}

%new
- (void)setHintGestureRecognizersEnabled:(BOOL)enabled {
    return;
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

%new
- (void)showEmergencyDialer {
    [self.customLockScreenContainer removeFromSuperview];
    [ALSHideableViewManager setShouldHide:NO];
    [[self lockScreenScrollView] setShouldHideSubviews:NO];
    [self setHintGestureRecognizersEnabled:YES];
    [[self lockScreenScrollView] setContentOffset:CGPointZero];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self passcodeLockViewEmergencyCallButtonPressed:nil];
    });
}

/*
 Called when the lock screen appears (other than the
 first time, which is handled by viewDidAppear).
 */
- (void)startLockScreenFadeInAnimationForSource:(int)arg1 {
    %orig;
    
    [self setHintGestureRecognizersEnabled:![[self lockScreenScrollView] isHidden]];
    [self addCustomLockScreen];
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
            [self.customLockScreenContainer setKeypadView:(SBUIPasscodeLockViewWithKeypad *)view];
            securityType = ALSLockScreenSecurityTypeCode;
            break;
        }
        else if([view isKindOfClass:[%c(SBUIPasscodeLockViewWithKeyboard) class]]) {
            for(UIView *keyboard in view.subviews) {
                if([keyboard isKindOfClass:[%c(SBPasscodeKeyboard) class]]) {
                    [self.customLockScreenContainer setKeyboardView:keyboard];
                    break;
                }
            }
            id passcodeTextField = [self findViewOfClass:[%c(SBUIPasscodeTextField) class] inView:view maxDepth:5];
            if(passcodeTextField) {
                [self.customLockScreenContainer setPasscodeTextField:passcodeTextField];
                [passcodeTextField setText:@""];
            }
            securityType = ALSLockScreenSecurityTypePhrase;
            break;
        }
    }
    [[self.customLockScreenContainer customLockScreen] setSecurityType:securityType];
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
