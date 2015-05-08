#import "SBLockScreenScrollView.h"

#import "ALSCustomLockScreenContainer.h"

/*
 The SBLockScreenScrollView class represents the main scrollview
 present on the lock screen, and we hook it as a quick and easy way
 to hide a number of compontents that we don't want visible.
 */

%hook SBLockScreenScrollView

- (void)layoutSubviews {
    [self setUserInteractionEnabled:NO];
    for(UIView *view in self.subviews) {
        [view setHidden:YES];
    }
}

%end
