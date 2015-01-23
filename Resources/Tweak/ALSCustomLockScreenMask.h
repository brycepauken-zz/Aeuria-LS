#import <UIKit/UIKit.h>

/*
 The ALSCustomLockScreenMask provides the mask that determines
 which portions of our custom lock screen's colored overlay are transparent.
 */

@interface ALSCustomLockScreenMask : CAShapeLayer

- (instancetype)initWithFrame:(CGRect)frame;
- (CGFloat)largeCircleInternalPadding;
- (CGFloat)largeCircleMinRadius;
- (void)updateScrollPercentage:(CGFloat)percentage;

@end
