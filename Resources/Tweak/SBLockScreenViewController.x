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

@property (nonatomic, strong) UIView *backgroundColorOverlay;
@property (nonatomic, strong) ALSCustomLockScreenContainer *customLockScreenContainer;

- (void)passcodeLockViewEmergencyCallButtonPressed:(id)arg1;
- (void)passcodeLockViewPasscodeEnteredViaMesa:(id)arg1;
- (void)passcodeLockViewPasscodeEntered:(id)arg1;
- (void)passcodeLockViewPasscodeDidChange:(id)arg1;

- (void)addCustomLockScreen;
- (BOOL)customLockScreenHiddenForEmergency;
- (id)customProperties;
- (id)findViewOfClass:(Class)class inView:(UIView *)view maxDepth:(int)depth;
- (void)setCustomLockScreenHiddenForEmergency:(BOOL)hidden;
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
    if([self customLockScreenHiddenForEmergency]) {
        [self setCustomLockScreenHiddenForEmergency:NO];
        [self setCustomLockScreenHidden:[self customLockScreenHidden]];
    }
    
    if([self customLockScreenHidden]) {
        return;
    }
    
    UIView *keyboardView = [self.customLockScreenContainer keyboardView];
    CGFloat lockScreenDateVerticalCenter = [self.customLockScreenContainer lockScreenDateVerticalCenter];
    UIView *mediaControlsView = [self.customLockScreenContainer mediaControlsView];
    BOOL mediaControlsViewHidden = [self.customLockScreenContainer mediaControlsViewHidden];
    UIView *notificationView = [self.customLockScreenContainer notificationView];
    BOOL notificationViewHidden = [self.customLockScreenContainer notificationViewHidden];
    BOOL nowPlayingPluginActive = [self.customLockScreenContainer nowPlayingPluginActive];
    UITextField *passcodeTextField = [self.customLockScreenContainer passcodeTextField];
    NSInteger passcodeTextFieldCharacterCount = [self.customLockScreenContainer passcodeTextFieldCharacterCount];
    
    BOOL shouldHideMediaControls = NO;
    NSNumber *shouldHideMediaControlsNum = [[self customProperties] objectForKey:@"MediaControlsShouldHide"];
    if(shouldHideMediaControlsNum) {
        shouldHideMediaControls = [shouldHideMediaControlsNum boolValue];
    }
    
    [self setHintGestureRecognizersEnabled:NO];
    [ALSHideableViewManager setShouldHide:YES];
    if(self.customLockScreenContainer) {
        [self.customLockScreenContainer removeFromSuperview];
    }
    if(self.backgroundColorOverlay) {
        [self.backgroundColorOverlay removeFromSuperview];
    }
    
    __weak SBLockScreenViewController *weakSelf = self;
    self.customLockScreenContainer = [[ALSCustomLockScreenContainer alloc] initWithFrame:[[self lockScreenView] bounds]];
    [self.customLockScreenContainer setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
    [self.customLockScreenContainer setKeyboardView:keyboardView];
    [self.customLockScreenContainer setLockScreenDateVerticalCenter:lockScreenDateVerticalCenter];
    [self.customLockScreenContainer setLockScreenViewController:self];
    [self.customLockScreenContainer setMediaControlsView:mediaControlsView];
    [self.customLockScreenContainer setMediaControlsViewHidden:mediaControlsViewHidden];
    [self.customLockScreenContainer setNotificationView:notificationView];
    [self.customLockScreenContainer setNotificationViewHidden:notificationViewHidden];
    [self.customLockScreenContainer setNowPlayingPluginActive:nowPlayingPluginActive];
    [self.customLockScreenContainer setPasscodeTextField:passcodeTextField];
    [self.customLockScreenContainer setPasscodeTextFieldCharacterCount:passcodeTextFieldCharacterCount];
    [self.customLockScreenContainer setUserInteractionEnabled:NO];
    [self.customLockScreenContainer setPasscodeEntered:^(NSString *passcode) {
        //create a proxy passcode handler (returns the entered passcode, forwards all other requests)
        id passcodeView = [[weakSelf lockScreenView] passcodeView];
        ALSProxyPasscodeHandler *proxyPasscodeHandler = [[ALSProxyPasscodeHandler alloc] init];
        [proxyPasscodeHandler setPasscode:passcode];
        [proxyPasscodeHandler setPasscodeView:passcodeView];
        [weakSelf passcodeLockViewPasscodeEntered:proxyPasscodeHandler];
    }];
    [self.customLockScreenContainer mediaControlsBecameHidden:shouldHideMediaControls];
    
    //check if background color overlay should be added
    if(self.customLockScreenContainer.customLockScreen.shouldColorBackground) {
        UIView *backgroundColorOverlay = [[UIView alloc] initWithFrame:[[[self lockScreenScrollView] superview] bounds]];
        [backgroundColorOverlay setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
        [backgroundColorOverlay setBackgroundColor:[self.customLockScreenContainer.customLockScreen.backgroundColor colorWithAlphaComponent:self.customLockScreenContainer.customLockScreen.backgroundColorAlpha]];
        [[[self lockScreenScrollView] superview] insertSubview:backgroundColorOverlay atIndex:0];
        self.backgroundColorOverlay = backgroundColorOverlay;
    }
    
    [self updateSecurityType];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self updateSecurityType];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self updateSecurityType];
    });
    
    [[[self lockScreenScrollView] superview] insertSubview:self.customLockScreenContainer belowSubview:[self lockScreenScrollView]];
}

%new
- (id)backgroundColorOverlay {
    return objc_getAssociatedObject(self, @selector(backgroundColorOverlay));
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
- (BOOL)customLockScreenHiddenForEmergency {
    NSNumber *customLockScreenHiddenForEmergencyNum = objc_getAssociatedObject(self, @selector(customLockScreenHiddenForEmergency));
    if(!customLockScreenHiddenForEmergencyNum) {
        objc_setAssociatedObject(self, @selector(customLockScreenHiddenForEmergency), @(NO), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return NO;
    }
    return [customLockScreenHiddenForEmergencyNum boolValue];
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

%new
- (void)setBackgroundColorOverlay:(id)backgroundColorOverlay {
    objc_setAssociatedObject(self, @selector(backgroundColorOverlay), backgroundColorOverlay, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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
    [self setNeedsStatusBarAppearanceUpdate];
}

%new
- (void)setCustomLockScreenHiddenForEmergency:(BOOL)hidden {
    objc_setAssociatedObject(self, @selector(customLockScreenHiddenForEmergency), @(hidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
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
- (void)setNowPlayingPluginActive:(BOOL)active {
    [self.customLockScreenContainer setNowPlayingPluginActive:active];
}

%new
- (void)showEmergencyDialer {
    [self.customLockScreenContainer removeFromSuperview];
    [ALSHideableViewManager setShouldHide:NO];
    [[self lockScreenScrollView] setShouldHideSubviews:NO];
    [self setHintGestureRecognizersEnabled:YES];
    [[self lockScreenScrollView] setContentOffset:CGPointZero];
    [self setCustomLockScreenHiddenForEmergency:YES];
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
    if(![self customLockScreenContainer]) {
        [self addCustomLockScreen];
    }
    
    if([[self customLockScreenContainer] customLockScreen] && [[[self customLockScreenContainer] customLockScreen] shouldHideStatusBar]) {
        return 3;
    }
    return %orig;
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
 
 [[self performSelector:@selector(recursiveDescription)] writeToFile:@"/var/mobile/Documents/out1.txt" atomically:YES encoding:NSUTF8StringEncoding error:nil];
 
 */

%end
