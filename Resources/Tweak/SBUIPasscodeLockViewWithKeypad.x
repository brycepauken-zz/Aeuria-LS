#import "SBUIPasscodeLockViewWithKeypad.h"

#import "ALSCustomLockScreen.h"
#import "ALSCustomLockScreenContainer.h"
#import "SBLockScreenViewController.h"

@interface SBUIPasscodeLockViewWithKeypad()

- (void)_notifyDelegatePasscodeEntered;

@end

%hook SBUIPasscodeLockViewWithKeypad

- (void)_notifyDelegatePasscodeEntered {
    [[[[self lockScreenViewController] customLockScreenContainer] customLockScreen] setUserInteractionEnabled:NO];
    
    %orig;
}

%end