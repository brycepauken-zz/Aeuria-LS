#import "ALSHideableViewManager.h"
#import "SBFLockScreenDateView.h"

/*
 The SBFLockScreenDateView class represents the date and time on the lock screen.
 While the clock is hidden when added to the lock screen scrollview, it's visible
 shortly beforehand, so we hide it here as well.
 */

%hook SBFLockScreenDateView

- (void)layoutSubviews {
    %orig;
    [ALSHideableViewManager addView:self];
    [self setHidden:[self isHidden]];
}

- (void)setHidden:(BOOL)hidden {
    [ALSHideableViewManager setViewHidden:hidden forView:self];
    %orig([ALSHideableViewManager shouldHide]?YES:[ALSHideableViewManager viewHidden:self]);
}

%end
