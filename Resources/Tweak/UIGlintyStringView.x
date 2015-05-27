#import "UIGlintyStringView.h"

#import "ALSHideableViewManager.h"

%hook _UIGlintyStringView

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