#import "ALSCustomLockScreen.h"

#import "ALSCustomLockScreenContainer.h"
#import "ALSCustomLockScreenMask.h"
#import "ALSImmediatePanGestureRecognizer.h"
#import "ALSPreferencesManager.h"
#import "ALSProxyTarget.h"

@interface ALSCustomLockScreen()

@property (nonatomic) BOOL buttonHighlighted;
@property (nonatomic, copy) void (^buttonTapped)(int index);
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, strong) UIView *filledOverlay;
@property (nonatomic, strong) ALSCustomLockScreenMask *filledOverlayMask;
@property (nonatomic) int highlightedButtonIndex;
@property (nonatomic) CGRect lastKnownBounds;
@property (nonatomic, strong) UIImage *lockscreenWallpaper;
@property (nonatomic) BOOL needsUpdate;
@property (nonatomic, copy) void (^passcodeEntered)(NSString *passcode);
@property (nonatomic) CGFloat percentage;
@property (nonatomic, strong) ALSPreferencesManager *preferencesManager;
@property (nonatomic) CGFloat previousPercentage;

//preference properties
@property (nonatomic, strong) UIColor *backgroundColor;
@property (nonatomic) float backgroundColorAlpha;
@property (nonatomic) int buttonDistanceFromEdge;
@property (nonatomic) int buttonPadding;
@property (nonatomic) int buttonRadius;
@property (nonatomic) float defaultClockHorizontalPosition;
@property (nonatomic) float defaultClockVerticalPosition;
@property (nonatomic) float lockScreenBlurType;
@property (nonatomic, strong) UIColor *lockScreenColor;
@property (nonatomic) float lockScreenColorAlpha;
@property (nonatomic) BOOL shouldBlurLockScreen;
@property (nonatomic) BOOL shouldColorBackground;
@property (nonatomic) BOOL shouldHideStatusBar;
@property (nonatomic) BOOL shouldShowWithNotifications;

@end

@implementation ALSCustomLockScreen

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        _preferencesManager = [[ALSPreferencesManager alloc] init];
        
        _backgroundColor = [_preferencesManager preferenceForKey:@"backgroundColor"];
        _backgroundColorAlpha = [[_preferencesManager preferenceForKey:@"backgroundColorAlpha"] floatValue];
        _buttonDistanceFromEdge = [[_preferencesManager preferenceForKey:@"passcodeButtonDistanceFromEdge"] intValue];
        _buttonPadding = [[_preferencesManager preferenceForKey:@"passcodeButtonPadding"] intValue];
        _buttonRadius = [[_preferencesManager preferenceForKey:@"passcodeButtonRadius"] intValue];
        _defaultClockHorizontalPosition = [[_preferencesManager preferenceForKey:@"defaultClockHorizontalPosition"] floatValue];
        _defaultClockVerticalPosition = [[_preferencesManager preferenceForKey:@"defaultClockVerticalPosition"] floatValue];
        _lockScreenBlurType = [[_preferencesManager preferenceForKey:@"lockScreenBlurType"] intValue];
        _lockScreenColor = [_preferencesManager preferenceForKey:@"lockScreenColor"];
        _lockScreenColorAlpha = [[_preferencesManager preferenceForKey:@"lockScreenColorAlpha"] floatValue];
        _shouldBlurLockScreen = [[_preferencesManager preferenceForKey:@"shouldBlurLockScreen"] boolValue];
        _shouldColorBackground = [[_preferencesManager preferenceForKey:@"shouldColorBackground"] boolValue];
        _shouldHideStatusBar = [[_preferencesManager preferenceForKey:@"shouldHideStatusBar"] boolValue];
        _shouldShowWithNotifications = ![[_preferencesManager preferenceForKey:@"shouldHideForNotificationsOrMedia"] boolValue];
        
        _lastKnownBounds = self.bounds;
        _percentage = 0;
        _previousPercentage = 0;
        
        CGFloat maxDimension = MAX(self.bounds.size.width, self.bounds.size.height);
        _filledOverlayMask = [[ALSCustomLockScreenMask alloc] initWithFrame:CGRectMake((self.bounds.size.width-maxDimension)/2, (self.bounds.size.height-maxDimension)/2, maxDimension, maxDimension) preferencesManager:_preferencesManager];
        [_filledOverlayMask setCustomLockScreen:self];
        _filledOverlay = [[UIView alloc] initWithFrame:self.bounds];
        [_filledOverlay setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
        [_filledOverlay.layer setMask:_filledOverlayMask];
        
        //check if blur should be added
        if(!_shouldBlurLockScreen || ![UIBlurEffect class] || ![UIVisualEffectView class]) {
            [_filledOverlay setBackgroundColor:[_lockScreenColor colorWithAlphaComponent:_lockScreenColorAlpha]];
        }
        else {
            UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:(_lockScreenBlurType==0?UIBlurEffectStyleLight:(_lockScreenBlurType==1?UIBlurEffectStyleExtraLight:UIBlurEffectStyleDark))];
            UIVisualEffectView *visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
            [visualEffectView setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
            [visualEffectView setFrame:_filledOverlay.bounds];
            [_filledOverlay addSubview:visualEffectView];
        }
        
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

- (void)failedEntry {
    if(self.percentage < 0.5) {
        CABasicAnimation *shakeAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
        [shakeAnimation setAutoreverses:YES];
        [shakeAnimation setDuration:0.05];
        [shakeAnimation setFromValue:[NSValue valueWithCGPoint:CGPointMake(self.center.x-10, self.center.y)]];
        [shakeAnimation setRepeatCount:4];
        [shakeAnimation setToValue:[NSValue valueWithCGPoint:CGPointMake(self.center.x+10, self.center.y)]];
        [self.layer addAnimation:shakeAnimation forKey:@"ShakeAnimation"];
    }
    else {
        [self.filledOverlayMask shakeDots];
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.filledOverlayMask removeAllDotsAndAnimate:YES withCompletion:^{
            [self setUserInteractionEnabled:YES];
        }];
    });
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    if(!self.userInteractionEnabled) {
        return nil;
    }
    
    if(self.filledOverlayMask.securityType!=ALSLockScreenSecurityTypeCode) {
        if(self.filledOverlayMask.securityType==ALSLockScreenSecurityTypePhrase && CGRectContainsPoint(CGRectMake(self.bounds.size.width/2-50, 20, 100, 80), point)) {
            self.highlightedButtonIndex = -1;
            return self;
        }
        return nil;
    }
    
    if(CGRectContainsPoint(CGRectMake(0, self.bounds.size.height-50, 100, 50), point) || CGRectContainsPoint(CGRectMake(self.bounds.size.width-100, self.bounds.size.height-50, 100, 50), point)) {
        self.highlightedButtonIndex = -1;
        return self;
    }
    
    //center the tapped point
    point.x -= self.bounds.size.width/2;
    point.y -= self.bounds.size.height/2;
    
    //holds sqrt computations
    static NSMutableDictionary *distances;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        distances = [[NSMutableDictionary alloc] init];
    });
    
    //buttons in order: 1-9, bottom-left, 0, bottom-right
    for(int i=0;i<12;i++) {
        //bottom-left/right buttons functionality still coming
        if(i==9 || i==11) {
            continue;
        }
        
        CGFloat xOffset = (i%3-1)*(self.buttonRadius*2+self.buttonPadding);
        CGFloat yOffset = (i/3-1)*(self.buttonRadius*2+self.buttonPadding);
        CGFloat distSquared = xOffset*xOffset + yOffset*yOffset;
        
        if(i==4) {
            xOffset = 0;
            yOffset = 0;
            CGFloat fakeOffset = self.buttonRadius*2+self.buttonPadding;
            distSquared = fakeOffset*fakeOffset + fakeOffset*fakeOffset;
        }
        else {
            xOffset = (i%3-1)*(self.buttonRadius*2+self.buttonPadding);
            yOffset = (i/3-1)*(self.buttonRadius*2+self.buttonPadding);
            distSquared = xOffset*xOffset + yOffset*yOffset;
        }
        
        NSNumber *distSquaredNumber = @(distSquared);
        NSNumber *distNumber = [distances objectForKey:distSquaredNumber];
        if(!distNumber) {
            distNumber = @(sqrt(distSquared));
            [distances setObject:distNumber forKey:distSquaredNumber];
        }
        CGFloat buttonRadius = MAX(0,MIN(self.buttonRadius,self.filledOverlayMask.lastKnownRadius-self.buttonDistanceFromEdge-[distNumber floatValue]-self.buttonRadius));
        
        if(buttonRadius > 0) {
            if(fabs(yOffset-point.y) < buttonRadius && fabs(xOffset-point.x) < buttonRadius) {
                UIView *tempView = [[UIView alloc] init];
                //used to determine button index
                [tempView setTag:i];
                return tempView;
            }
        }
    }
    
    return nil;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if(!CGRectEqualToRect(self.bounds, self.lastKnownBounds)) {
        CAAnimation *existingAnimation = [self.layer animationForKey:[self.layer.animationKeys firstObject]];
        
        self.lastKnownBounds = self.bounds;
        
        CGPoint centerPoint = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
        CABasicAnimation *centerAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
        [centerAnimation setDuration:[[existingAnimation valueForKey:@"duration"] doubleValue]];
        [centerAnimation setFromValue:[self.filledOverlayMask valueForKey:@"position"]];
        [centerAnimation setTimingFunction:[existingAnimation timingFunction]];
        [centerAnimation setToValue:[NSValue valueWithCGPoint:centerPoint]];
        [self.filledOverlayMask addAnimation:centerAnimation forKey:@"CenterAnimation"];
        
        [CATransaction begin];
        [CATransaction setValue: (id) kCFBooleanTrue forKey: kCATransactionDisableActions];
        [self.filledOverlayMask setPosition:centerPoint];
        [CATransaction commit];
    }
}

- (void)panGestureRecognizerCalled:(UIPanGestureRecognizer *)gestureRecognizer {
    if(!self.userInteractionEnabled) {
        return;
    }
    
    CGPoint point = [gestureRecognizer locationInView:self];
    
    //check delete & emergency buttons
    if(self.buttonTapped) {
        if(self.filledOverlayMask.securityType == ALSLockScreenSecurityTypePhrase) {
            self.highlightedButtonIndex = -1;
            if(gestureRecognizer.state == UIGestureRecognizerStateEnded && CGRectContainsPoint(CGRectMake(self.bounds.size.width/2-50, 20, 100, 80), point)) {
                self.buttonTapped(-1);
            }
            return;
        }
        
        if(CGRectContainsPoint(CGRectMake(0, self.bounds.size.height-50, 100, 50), point)) {
            self.highlightedButtonIndex = -1;
            if(gestureRecognizer.state == UIGestureRecognizerStateEnded) {
                self.buttonTapped(-1);
            }
            return;
        }
        else if(CGRectContainsPoint(CGRectMake(self.bounds.size.width-100, self.bounds.size.height-50, 100, 50), point)) {
            self.highlightedButtonIndex = -1;
            if(gestureRecognizer.state == UIGestureRecognizerStateEnded) {
                [self.filledOverlayMask removeDotAndAnimate:YES];
                self.buttonTapped(-2);
            }
            return;
        }
    }
    
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
                
                [self.filledOverlayMask addDotAndAnimate:YES];
                if(self.buttonTapped) {
                    self.buttonTapped(self.highlightedButtonIndex);
                }
            }
        }
    }
}

- (void)resetView {
    self.needsUpdate = YES;
    self.previousPercentage = 0;
    [self.filledOverlayMask resetMask];
    [self updateViews];
}

- (void)setClockToDefaultPosition {
    [self.filledOverlayMask setHorizontalPosition:self.defaultClockHorizontalPosition verticalPosition:self.defaultClockVerticalPosition];
}

- (void)setClockToPosition:(CGPoint)position {
    [self.filledOverlayMask setHorizontalPosition:position.x verticalPosition:position.y];
}

- (void)setDisplayLinkPaused:(BOOL)paused {
    [self.displayLink setPaused:paused];
}

- (void)setKeyboardHeight:(CGFloat)keyboardHeight {
    [self.filledOverlayMask setKeyboardHeight:keyboardHeight];
}

- (void)setPercentage:(CGFloat)percentage {
    _percentage = MAX(0, percentage);
}

- (void)setSecurityType:(NSInteger)securityType {
    [self.filledOverlayMask setSecurityType:securityType];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    if(!self.superview.userInteractionEnabled) {
        return;
    }
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
    if(self.hidden || !self.superview || self.superview.hidden) {
        return;
    }
    if(self.percentage != self.previousPercentage || self.filledOverlayMask.isAnimating || self.needsUpdate || self.filledOverlayMask.needsUpdate) {
        self.needsUpdate = NO;
        self.previousPercentage = self.percentage;
        [self.filledOverlayMask updateMaskWithPercentage:self.percentage];
    }
}

@end
