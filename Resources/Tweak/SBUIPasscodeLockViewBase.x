#import "SBUIPasscodeLockViewBase.h"

#import "ALSHideableViewManager.h"
#import "SBLockScreenViewController.h"

%hook SBUIPasscodeLockViewBase

- (void)layoutSubviews {
    %orig;
    if(![self isKindOfClass:[%c(SBUIPasscodeLockViewWithKeyboard) class]]) {
        [ALSHideableViewManager addView:self];
    }
    else {
        for(UIView *subview in self.subviews) {
            if(![subview isKindOfClass:[%c(SBPasscodeKeyboard) class]]) {
                [ALSHideableViewManager addView:subview];
            }
        }
    }
    [self setHidden:[self isHidden]];
}

%new
- (id)lockScreenViewController {
    __weak static SBLockScreenViewController *lockScreenViewController;
    if(!lockScreenViewController) {
        UIView *currentView = self;
        while(currentView.superview && ![currentView isKindOfClass:[%c(SBLockScreenView) class]]) {
            currentView = currentView.superview;
        }
        if([currentView.nextResponder isKindOfClass:[%c(SBLockScreenViewController) class]]) {
            lockScreenViewController = (SBLockScreenViewController *)currentView.nextResponder;
        }
    }
    return lockScreenViewController;
}

- (void)resetForFailedPasscode {
    %orig;
    
    [[self lockScreenViewController] failedPasscode];
}

- (void)resetForScreenOff {
    %orig;
    
    [[self lockScreenViewController] resetForScreenOff];
}

- (void)setHidden:(BOOL)hidden {
    if(![self isKindOfClass:[%c(SBUIPasscodeLockViewWithKeyboard) class]]) {
        [ALSHideableViewManager setViewHidden:hidden forView:self];
        %orig([ALSHideableViewManager shouldHide]?YES:[ALSHideableViewManager viewHidden:self]);
    }
    else {
        for(UIView *subview in self.subviews) {
            if(![subview isKindOfClass:[%c(SBPasscodeKeyboard) class]]) {
                [ALSHideableViewManager setViewHidden:hidden forView:subview];
                [subview setHidden:([ALSHideableViewManager shouldHide]?YES:[ALSHideableViewManager viewHidden:subview])];
            }
        }
    }
        
}

- (void)updateStatusTextForBioEvent:(unsigned long long)arg1 animated:(bool)arg2 {
    %orig;
    
    if(arg1 > 0) {
        [[self lockScreenViewController] failedBio];
    }
}

%end