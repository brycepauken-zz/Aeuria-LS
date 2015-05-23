#import "ALSCustomLockScreenElement.h"

@class ALSPreferencesManager;

@interface ALSCustomLockScreenButtons : ALSCustomLockScreenElement

- (UIBezierPath *)buttonsPathForRadius:(CGFloat)radius;
- (void)setClockInvisibleAt:(float)clockInvisibleAt;

@end
