#import "ALSCustomLockScreenElement.h"

/*
 The ALSCustomLockScreenClock represents our clock.
 */

typedef NS_ENUM(NSInteger, ALSClockType) {
    ALSClockTypeText,
    ALSClockTypeDigital,
    ALSClockTypeAnalog
};

@interface ALSCustomLockScreenClock : ALSCustomLockScreenElement

- (instancetype)initWithRadius:(CGFloat)radius type:(ALSClockType)clockType preferencesManager:(ALSPreferencesManager *)preferencesManager;
- (UIBezierPath *)clockPathForHour:(NSInteger)hour minute:(NSInteger)minute date:(NSString *)date;
- (void)preloadPathForHour:(NSInteger)hour minute:(NSInteger)minute date:(NSString *)date;
- (CGFloat)radius;

@end
