#import <UIKit/UIKit.h>

/*
 The ALSCustomLockScreenClock represents our clock.
 */

typedef NS_ENUM(NSInteger, ALSClockType) {
    ALSClockTypeText,
    ALSClockTypeDigital,
    ALSClockTypeAnalog
};

@class ALSPreferencesManager;

@interface ALSCustomLockScreenClock : NSObject

- (instancetype)initWithRadius:(CGFloat)radius type:(ALSClockType)clockType preferencesManager:(ALSPreferencesManager *)preferencesManager;
- (UIBezierPath *)clockPathForHour:(NSInteger)hour minute:(NSInteger)minute;
- (void)preloadPathForHour:(NSInteger)hour minute:(NSInteger)minute;
- (CGFloat)radius;

@end
