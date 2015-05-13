#import "SBWallpaperEffectView.h"
#import "ALSHideableViewManager.h"

/*
 The SBWallpaperEffectView class presents effects over the wallpaper.
 We simply hide them.
 */

%hook SBWallpaperEffectView

- (void)layoutSubviews {
    %orig;
    [ALSHideableViewManager addView:self];
    [self setHidden:[self isHidden]];
}

- (void)setHidden:(BOOL)hidden {
    [ALSHideableViewManager setViewHidden:hidden forView:self];
    %orig(([ALSHideableViewManager shouldHide]&&[ALSHideableViewManager indexOfView:self]!=NSNotFound)?YES:[ALSHideableViewManager viewHidden:self]);
}

%end
