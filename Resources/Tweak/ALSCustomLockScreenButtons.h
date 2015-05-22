#import "ALSCustomLockScreenElement.h"

@class ALSPreferencesManager;

@interface ALSCustomLockScreenButtons : ALSCustomLockScreenElement

- (UIBezierPath *)buttonsPathForRadius:(CGFloat)radius middleButtonStartingRadius:(CGFloat)middleButtonStartingRadius;
- (void)setClockInvisibleAt:(float)clockInvisibleAt;

@end
