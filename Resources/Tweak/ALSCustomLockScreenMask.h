#import <UIKit/UIKit.h>

/*
 The ALSCustomLockScreenMask provides the mask that determines
 which portions of our custom lock screen's colored overlay are transparent.
 */

@interface ALSCustomLockScreenMask : CAShapeLayer

- (instancetype)initWithFrame:(CGRect)frame;
- (void)resetMask;
- (void)updateMaskWithPercentage:(CGFloat)percentage;

@end
