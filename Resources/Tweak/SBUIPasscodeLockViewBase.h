#import <UIKit/UIKit.h>

@interface SBUIPasscodeLockViewBase : UIView {
    NSString *_passcode;
}

- (id)passcode;
- (BOOL)playsKeypadSounds;

@end
