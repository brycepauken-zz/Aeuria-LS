#import <UIKit/UIKit.h>

/*
 The ALSCustomLockScreenMask provides the mask that determines
 which portions of our custom lock screen's colored overlay are transparent.
 */

@class ALSPreferencesManager;

@interface ALSCustomLockScreenMask : CAShapeLayer

- (instancetype)initWithFrame:(CGRect)frame preferencesManager:(ALSPreferencesManager *)preferencesManager;
- (void)addDot;
- (void)buttonAtIndex:(int)index setHighlighted:(BOOL)highlighted;
- (BOOL)isAnimating;
- (void)removeAllDots;
- (void)resetMask;
- (void)updateMaskWithPercentage:(CGFloat)percentage;

@end
