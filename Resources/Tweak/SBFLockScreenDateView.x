#import "SBFLockScreenDateView.h"

/*
 The SBFLockScreenDateView class represents the date and time on the lock screen.
 While the clock is hidden when added to the lock screen scrollview, it's visible
 shortly beforehand, so we hide it here as well.
 */

%hook SBFLockScreenDateView

- (id)initWithFrame:(CGRect)frame {
    id selfID = %orig;
    if(selfID) {
        [selfID setHidden:YES];
    }
    return selfID;
}

- (void)setHidden:(BOOL)hidden {
    %orig(YES);
}

%end
