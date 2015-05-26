#import "ALSCustomLockScreenElement.h"

@class ALSPreferencesManager;

@interface ALSCustomLockScreenButtons : ALSCustomLockScreenElement

- (UIBezierPath *)buttonsPathForRadius:(CGFloat)radius horizontalCenterOffset:(CGFloat)horizontalCenterOffset verticalCenterOffset:(CGFloat)verticalCenterOffset;
- (void)setClockInvisibleAt:(float)clockInvisibleAt;

@end
