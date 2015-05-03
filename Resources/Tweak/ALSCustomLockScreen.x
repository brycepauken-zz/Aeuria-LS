#import "ALSCustomLockScreen.h"

#import "ALSCustomLockScreenMask.h"
#import "ALSImmediatePanGestureRecognizer.h"
#import "ALSPreferencesManager.h"
#import "ALSProxyTarget.h"

@interface ALSCustomLockScreen()

@property (nonatomic) BOOL buttonHighlighted;
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, strong) UIView *filledOverlay;
@property (nonatomic, strong) ALSCustomLockScreenMask *filledOverlayMask;
@property (nonatomic) int highlightedButtonIndex;
@property (nonatomic) BOOL needsUpdate;
@property (nonatomic) CGFloat percentage;
@property (nonatomic, strong) ALSPreferencesManager *preferencesManager;
@property (nonatomic) CGFloat previousPercentage;

//preference properties
@property (nonatomic) int buttonPadding;
@property (nonatomic) int buttonRadius;

@end

@implementation ALSCustomLockScreen

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        _preferencesManager = [[ALSPreferencesManager alloc] init];
        
        _buttonPadding = 10;
        _buttonRadius = 44;
        
        _percentage = 0;
        _previousPercentage = 0;
        
        _filledOverlayMask = [[ALSCustomLockScreenMask alloc] initWithFrame:self.bounds preferencesManager:_preferencesManager];
        _filledOverlay = [[UIView alloc] initWithFrame:self.bounds];
        [_filledOverlay setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
        [_filledOverlay setBackgroundColor:[_preferencesManager preferenceForKey:@"faceColor"]];
        [_filledOverlay.layer setMask:_filledOverlayMask];
        
        ALSProxyTarget *proxyTarget = [ALSProxyTarget proxyForTarget:self selector:@selector(updateViews)];
        _displayLink = [CADisplayLink displayLinkWithTarget:proxyTarget selector:@selector(tick:)];
        [_displayLink setFrameInterval:1];
        [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];

        [self addSubview:_filledOverlay];
        
        ALSImmediatePanGestureRecognizer *panGestureRecognizer = [[ALSImmediatePanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognizerCalled:)];
        [self addGestureRecognizer:panGestureRecognizer];
    }
    return self;
}

- (BOOL)buttonAtIndex:(int)index containsPoint:(CGPoint)point {
    CGFloat xOffset = (index%3-1)*(self.buttonRadius*2+self.buttonPadding);
    CGFloat yOffset = (index/3-1)*(self.buttonRadius*2+self.buttonPadding);
    return fabs(xOffset-(point.x-self.bounds.size.width/2)) < self.buttonRadius*2 && fabs(yOffset-(point.y-self.bounds.size.height/2)) < self.buttonRadius*2;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if(self.percentage < 1) {
        return nil;
    }
    
    point.x -= self.bounds.size.width/2;
    point.y -= self.bounds.size.height/2;
    for(int y=0;y<4;y++) {
        CGFloat yOffset = (y-1)*(self.buttonRadius*2+self.buttonPadding);
        if(fabs(yOffset-point.y) < self.buttonRadius) {
            for(int x=0;x<3;x++) {
                //bottom-left/right buttons not used yet
                if(y==3 && x!=1) {
                    continue;
                }
                CGFloat xOffset = (x-1)*(self.buttonRadius*2+self.buttonPadding);
                if(fabs(xOffset-point.x) < self.buttonRadius) {
                    UIView *tempView = [[UIView alloc] init];
                    //used to determine button index
                    [tempView setTag:x+y*3];
                    return tempView;
                }
            }
        }
    }
    
    return nil;
}

- (void)resetView {
    [self.filledOverlayMask resetMask];
}

- (void)panGestureRecognizerCalled:(UIPanGestureRecognizer *)gestureRecognizer {
    CGPoint point = [gestureRecognizer locationInView:self];
    if(gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        UIView *tappedButton = [self hitTest:point withEvent:nil];
        if(tappedButton) {
            _highlightedButtonIndex = (int)tappedButton.tag;
            [self.filledOverlayMask buttonAtIndex:self.highlightedButtonIndex setHighlighted:YES];
            self.buttonHighlighted = YES;
            self.needsUpdate = YES;
        }
    }
    else {
        BOOL withinButton = [self buttonAtIndex:self.highlightedButtonIndex containsPoint:point];
        
        if(withinButton != self.buttonHighlighted) {
            self.buttonHighlighted = withinButton;
            [self.filledOverlayMask buttonAtIndex:self.highlightedButtonIndex setHighlighted:withinButton];
            self.needsUpdate = YES;
        }
        
        if(gestureRecognizer.state == UIGestureRecognizerStateEnded || gestureRecognizer.state == UIGestureRecognizerStateCancelled) {
            if(withinButton) {
                [self.filledOverlayMask buttonAtIndex:self.highlightedButtonIndex setHighlighted:NO];
                self.buttonHighlighted = NO;
                self.needsUpdate = YES;
            }
        }
    }
}

- (void)setPercentage:(CGFloat)percentage {
    _percentage = MAX(0, percentage);
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    UIView *tappedButton = [self hitTest:[[touches anyObject] locationInView:self] withEvent:event];
    if(tappedButton) {
        _highlightedButtonIndex = (int)tappedButton.tag;
        [self.filledOverlayMask buttonAtIndex:self.highlightedButtonIndex setHighlighted:YES];
        self.buttonHighlighted = YES;
        self.needsUpdate = YES;
    }
}

- (void)updateScrollPercentage:(CGFloat)percentage {
    self.percentage = percentage;
}

- (void)updateViews {
    if(self.percentage != self.previousPercentage || self.needsUpdate) {
        self.needsUpdate = NO;
        self.previousPercentage = self.percentage;
        [self.filledOverlayMask updateMaskWithPercentage:self.percentage];
    }
}

@end
