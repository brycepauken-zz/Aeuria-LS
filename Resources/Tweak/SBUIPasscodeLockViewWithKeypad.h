#import <UIKit/UIKit.h>

#import "SBUIPasscodeLockViewBase.h"

@interface SBUIPasscodeLockViewWithKeypad : SBUIPasscodeLockViewBase

- (void)_noteBackspaceHit;
- (void)_noteStringEntered:(id)arg1 eligibleForPlayingSounds:(BOOL)arg2;

@end
