#import "ALSCustomLockScreen.h"

#import "ALSCustomLockScreenMask.h"
#import "ALSPreferencesManager.h"
#import "ALSProxyTarget.h"

@interface ALSCustomLockScreen()

@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, strong) UIView *filledOverlay;
@property (nonatomic, strong) ALSCustomLockScreenMask *filledOverlayMask;
@property (nonatomic) CGFloat percentage;
@property (nonatomic, strong) ALSPreferencesManager *preferencesManager;
@property (nonatomic) CGFloat previousPercentage;

@end

@implementation ALSCustomLockScreen

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        _preferencesManager = [[ALSPreferencesManager alloc] init];
        
        _percentage = 0;
        _previousPercentage = 0;
        
        _filledOverlayMask = [[ALSCustomLockScreenMask alloc] initWithFrame:self.bounds preferencesManager:_preferencesManager];
        _filledOverlay = [[UIView alloc] initWithFrame:self.bounds];
        [_filledOverlay setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
        [_filledOverlay setBackgroundColor:[UIColor whiteColor]];
        [_filledOverlay.layer setMask:_filledOverlayMask];
        
        ALSProxyTarget *proxyTarget = [ALSProxyTarget proxyForTarget:self selector:@selector(updateViews)];
        _displayLink = [CADisplayLink displayLinkWithTarget:proxyTarget selector:@selector(tick:)];
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
