#import "SBUIPasscodeLockViewWithKeypad.h"

#import "SBLockScreenViewController.h"

@interface SBUIPasscodeLockViewWithKeypad()

- (void)_notifyDelegatePasscodeEntered;

@end

%hook SBUIPasscodeLockViewWithKeypad

- (void)_notifyDelegatePasscodeEntered {
    [[[self lockScreenViewController] customLockScreenContainer] setUserInteractionEnabled:NO];
    
    %orig;
}

%end