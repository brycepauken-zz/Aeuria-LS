#import <UIKit/UIKit.h>

/*
 The ALSKeypadButton is a UIView subclass that represents the
 numbered keys on the lock screen.
 */

@interface ALSKeypadButton : UIView

- (instancetype)initWithRadius:(CGFloat)radius number:(int)number color:(UIColor *)color;

@end
