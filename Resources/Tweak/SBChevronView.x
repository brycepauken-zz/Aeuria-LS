#import "SBChevronView.h"
#import "ALSHideableViewManager.h"

/*
 The SBChevronView class represents the chevrons on the top and bottom
 of the lockscreen. We simply hide them.
 */

%hook SBChevronView

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
