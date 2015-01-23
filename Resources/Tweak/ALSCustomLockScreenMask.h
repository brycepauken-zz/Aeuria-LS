#import <UIKit/UIKit.h>

/*
 The ALSCustomLockScreenMask provides the mask that determines
 which portions of our custom lock screen's colored overlay are transparent.
 */

@interface ALSCustomLockScreenMask : CAShapeLayer

- (instancetype)initWithFrame:(CGRect)frame;
- (CGFloat)buttonRadius;
- (CGFloat)buttonPadding;
- (CGFloat)largeCircleInternalPadding;
- (CGFloat)largeCircleMinRadius;
- (CGFloat)largeCircleMaxRadius;
- (CGFloat)middleButtonVisiblePercentage;
- (void)setScrollPercentage:(CGFloat)percentage;
- (void)updateMaskWithLargeRadius:(CGFloat)largeRadius smallRadius:(CGFloat)smallRadius axesButtonsRadii:(CGFloat)axesButtonsRadii diagonalButtonsRadii:(CGFloat)diagonalButtonsRadii;

@end
