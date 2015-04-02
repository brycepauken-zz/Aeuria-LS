#import "SBLockScreenScrollView.h"

/*
 The SBLockScreenScrollView class represents the main scrollview
 present on the lock screen, and we hook it as a quick and easy way
 to hide a number of compontents that we don't want visible.
 */

%hook SBLockScreenScrollView

- (void)addSubview:(UIView *)view {
    %orig;
    
    [view setHidden:YES];
}

%end
