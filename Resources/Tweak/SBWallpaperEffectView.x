#import "SBWallpaperEffectView.h"

/*
 The SBWallpaperEffectView class presents effects over the wallpaper.
 We simply hide them.
 */

%hook SBWallpaperEffectView

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
