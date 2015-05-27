#import "SBSlideUpAppGrabberView.h"

#import "ALSHideableViewManager.h"

%hook SBSlideUpAppGrabberView

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