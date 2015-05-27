#import "SBUIPasscodeLockViewBase.h"

#import "ALSHideableViewManager.h"
#import "SBLockScreenViewController.h"

%hook SBUIPasscodeLockViewBase

- (void)layoutSubviews {
    %orig;
    [ALSHideableViewManager addView:self];
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
    [ALSHideableViewManager setViewHidden:hidden forView:self];
    %orig([ALSHideableViewManager shouldHide]?YES:[ALSHideableViewManager viewHidden:self]);
}

- (void)updateStatusTextForBioEvent:(unsigned long long)arg1 animated:(bool)arg2 {
    %orig;
    
    if(arg1 > 0) {
        [[self lockScreenViewController] failedBio];
    }
}

%end