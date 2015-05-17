#import "SBUIPasscodeLockViewBase.h"

#import "SBLockScreenViewController.h"

@interface  SBUIPasscodeLockViewBase()

- (SBLockScreenViewController *)lockScreenViewController;

@end

%hook SBUIPasscodeLockViewBase

- (void)layoutSubviews {
    for(UIView *subview in self.subviews) {
        if([subview isKindOfClass:[UILabel class]]) {
            [subview setHidden:YES];
        }
    }
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

- (void)updateStatusTextForBioEvent:(unsigned long long)arg1 animated:(bool)arg2 {
    %orig;
    
    if(arg1 > 0) {
        [[self lockScreenViewController] failedBio];
    }
}

- (void)resetForScreenOff {
    %orig;
    
     [[self lockScreenViewController] resetForScreenOff];
}

%end