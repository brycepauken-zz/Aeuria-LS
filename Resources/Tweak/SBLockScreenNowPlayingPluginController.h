#import <UIKit/UIKit.h>

@class SBLockScreenViewController;

@interface SBLockScreenNowPlayingPluginController : UIViewController {
    SBLockScreenViewController *_viewController;
}

- (void)_disableNowPlayingPlugin;
- (void)_updateNowPlayingPlugin;
- (BOOL)isNowPlayingPluginActive;

@end
