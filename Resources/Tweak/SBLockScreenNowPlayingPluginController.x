#import "SBLockScreenNowPlayingPluginController.h"

#import "SBLockScreenViewController.h"

%hook SBLockScreenNowPlayingPluginController

- (void)_disableNowPlayingPlugin {
    %orig;
    [[self valueForKey:@"_viewController"] setNowPlayingPluginActive:[self isNowPlayingPluginActive]];
}

- (void)_updateNowPlayingPlugin {
    %orig;
    [[self valueForKey:@"_viewController"] setNowPlayingPluginActive:[self isNowPlayingPluginActive]];
}

%end