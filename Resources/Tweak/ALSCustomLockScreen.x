#import "ALSCustomLockScreen.h"

#import "ALSCustomLockScreenMask.h"

@interface ALSCustomLockScreen()

@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, strong) UIView *filledOverlay;
@property (nonatomic, strong) ALSCustomLockScreenMask *filledOverlayMask;
@property (nonatomic) CGFloat percentage;
@property (nonatomic) CGFloat previousPercentage;

@end

@implementation ALSCustomLockScreen

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        _percentage = 0;
        _previousPercentage = 0;
        
        _filledOverlayMask = [[ALSCustomLockScreenMask alloc] initWithFrame:self.bounds];
        _filledOverlay = [[UIView alloc] initWithFrame:self.bounds];
        [_filledOverlay setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
        [_filledOverlay setBackgroundColor:[UIColor whiteColor]];
        [_filledOverlay.layer setMask:_filledOverlayMask];
        
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateViews)];
        [_displayLink setFrameInterval:1];
        [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        
        [self addSubview:_filledOverlay];
        
        [self setUserInteractionEnabled:NO];
    }
    return self;
}

- (void)resetView {
    [self.filledOverlayMask resetMask];
}

- (void)setPercentage:(CGFloat)percentage {
    _percentage = MAX(0, percentage);
}

- (void)updateScrollPercentage:(CGFloat)percentage {
    self.percentage = percentage;
}

- (void)updateViews {
    if(self.percentage != self.previousPercentage) {
        self.previousPercentage = self.percentage;
        [self.filledOverlayMask updateMaskWithPercentage:self.percentage];
    }
}

@end
