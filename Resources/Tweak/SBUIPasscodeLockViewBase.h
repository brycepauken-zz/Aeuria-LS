#import <UIKit/UIKit.h>

@class SBLockScreenViewController;

@interface SBUIPasscodeLockViewBase : UIView {
    NSString *_passcode;
}

- (SBLockScreenViewController *)lockScreenViewController;
- (id)passcode;
- (BOOL)playsKeypadSounds;

@end
