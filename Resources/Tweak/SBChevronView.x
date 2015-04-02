#import "SBChevronView.h"

/*
 The SBChevronView class represents the chevrons on the top and bottom
 of the lockscreen. We simply hide them.
 */

%hook SBChevronView

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
