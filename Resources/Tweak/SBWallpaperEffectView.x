#import "SBWallpaperEffectView.h"
#import "ALSHideableViewManager.h"

/*
 The SBWallpaperEffectView class presents effects over the wallpaper.
 We simply hide them.
 */

%hook SBWallpaperEffectView

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
