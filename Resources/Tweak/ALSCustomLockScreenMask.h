#import <UIKit/UIKit.h>

/*
 The ALSCustomLockScreenMask provides the mask that determines
 which portions of our custom lock screen's colored overlay are transparent.
 */

@class ALSPreferencesManager;

@interface ALSCustomLockScreenMask : CAShapeLayer

- (instancetype)initWithFrame:(CGRect)frame preferencesManager:(ALSPreferencesManager *)preferencesManager;
- (void)addDotAndAnimate:(BOOL)animate;
- (void)buttonAtIndex:(int)index setHighlighted:(BOOL)highlighted;
- (BOOL)isAnimating;
- (BOOL)needsUpdate;
- (void)removeAllDotsWithCompletion:(void (^)())completion;
- (void)resetMask;
- (void)shakeDots;
- (void)updateMaskWithPercentage:(CGFloat)percentage;

@end
