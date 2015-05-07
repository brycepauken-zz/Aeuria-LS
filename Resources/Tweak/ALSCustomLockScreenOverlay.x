#import "ALSCustomLockScreenOverlay.h"

@implementation ALSCustomLockScreenOverlay

- (void)setContentOffset:(CGPoint)offset {
    [super setContentOffset:offset];
    
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if(!self.dragging) {
        [self.nextResponder touchesBegan:touches withEvent:event];
    }
    else {
        [super touchesBegan:touches withEvent:event];
    }
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    if(!self.dragging) {
        [self.nextResponder touchesMoved:touches withEvent:event];
    }
    else {
        [super touchesMoved:touches withEvent:event];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if(!self.dragging) {
        [self.nextResponder touchesEnded:touches withEvent:event];
    }
    else {
        [super touchesEnded:touches withEvent:event];
    }
}

@end
