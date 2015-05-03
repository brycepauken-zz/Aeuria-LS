#import "ALSImmediatePanGestureRecognizer.h"

@interface UIGestureRecognizer()

@property(nonatomic,readwrite) UIGestureRecognizerState state;

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;

@end

@implementation ALSImmediatePanGestureRecognizer

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    self.state = UIGestureRecognizerStateBegan;
    [super touchesBegan:touches withEvent:event];
}

@end
