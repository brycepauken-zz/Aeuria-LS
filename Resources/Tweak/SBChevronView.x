#import "SBChevronView.h"
#import "ALSHideableViewManager.h"

/*
 The SBChevronView class represents the chevrons on the top and bottom
 of the lockscreen. We simply hide them.
 */

%hook SBChevronView

- (id)initWithFrame:(CGRect)frame {
    id selfID = %orig;
    if(selfID) {
        [ALSHideableViewManager addView:selfID];
        [selfID setHidden:[selfID isHidden]];
    }
    return selfID;
}

- (void)setHidden:(BOOL)hidden {
    [ALSHideableViewManager setViewHidden:hidden forView:self];
    %orig([ALSHideableViewManager shouldHide]?YES:[ALSHideableViewManager viewHidden:self]);
}

%end
