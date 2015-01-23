#import <UIKit/UIKit.h>

/*
 The ALSClockView is a circular view that shows the current time.
 It operates independently of the rest of the lock screen mask.
 */

@interface ALSClockView : UIView

- (instancetype)initWithRadius:(CGFloat)radius internalPadding:(CGFloat)internalPadding color:(UIColor *)color;

@end
