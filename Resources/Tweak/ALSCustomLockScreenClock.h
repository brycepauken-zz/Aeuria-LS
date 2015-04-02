#import <UIKit/UIKit.h>

/*
 The ALSCustomLockScreenClock represents our clock.
 */

typedef NS_ENUM(NSInteger, ALSClockType) {
    ALSClockTypeText,
    ALSClockTypeDigital,
    ALSClockTypeAnalog
};

@interface ALSCustomLockScreenClock : NSObject

- (instancetype)initWithRadius:(CGFloat)radius type:(ALSClockType)clockType;
- (UIBezierPath *)clockPathForHour:(NSInteger)hour minute:(NSInteger)minute;
- (void)preloadPathForHour:(NSInteger)hour minute:(NSInteger)minute;
- (CGFloat)radius;

@end
