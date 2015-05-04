#import "ALSCustomLockScreenMask.h"

#import "ALSCustomLockScreenButtons.h"
#import "ALSCustomLockScreenClock.h"
#import "ALSPreferencesManager.h"
#import "ALSProxyTarget.h"

@interface ALSCustomLockScreenMask()

//general properties
@property (nonatomic, strong) ALSCustomLockScreenButtons *buttons;
@property (nonatomic, strong) CAShapeLayer *circleMaskLayer;
@property (nonatomic, strong) ALSCustomLockScreenClock *clock;
@property (nonatomic) NSInteger currentHour;
@property (nonatomic) NSInteger currentMinute;
@property (nonatomic) CGFloat currentPercentage;
@property (nonatomic, strong) NSMutableArray *highlightedButtonIndexes;
@property (nonatomic, strong) CAShapeLayer *highlightedButtonLayer;
@property (nonatomic, strong) NSString *instructions;
@property (nonatomic, strong) UIBezierPath *instructionsPath;
@property (nonatomic, strong) CAShapeLayer *internalLayer;
@property (nonatomic) CGFloat largeCircleMaxInternalPaddingIncrement;
@property (nonatomic) CGFloat largeCircleMaxRadiusIncrement;
@property (nonatomic, strong) NSTimer *minuteTimer;
@property (nonatomic, strong) ALSPreferencesManager *preferencesManager;

//preference properties
@property (nonatomic) int buttonPadding;
@property (nonatomic) int buttonRadius;
@property (nonatomic) float clockInvisibleAt;
@property (nonatomic) int instructionsHeight;
@property (nonatomic) int largeCircleInnerPadding;
@property (nonatomic) int largeCircleMinRadius;
@property (nonatomic) float pressedButtonAlpha;

@end

@implementation ALSCustomLockScreenMask

- (instancetype)initWithFrame:(CGRect)frame preferencesManager:(ALSPreferencesManager *)preferencesManager {
    self = [super init];
    if(self) {
        _preferencesManager = preferencesManager;
        _buttonPadding = 10;
        _buttonRadius = 44;
        _clockInvisibleAt = [[preferencesManager preferenceForKey:@"clockInvisibleAt"] floatValue];
        _instructionsHeight = 30;
        _largeCircleInnerPadding = [[preferencesManager preferenceForKey:@"clockInnerPadding"] intValue];
        _largeCircleMinRadius = [[preferencesManager preferenceForKey:@"clockRadius"] intValue];
        _pressedButtonAlpha = 0.25;
        
        _currentHour = 0;
        _currentMinute = 0;
        _currentPercentage = 0;
        _highlightedButtonIndexes = [[NSMutableArray alloc] init];
        
        _circleMaskLayer = [[CAShapeLayer alloc] init];
        _internalLayer = [[CAShapeLayer alloc] init];
        [_internalLayer setFillColor:[[UIColor blackColor] CGColor]];
        [_internalLayer setFillRule:kCAFillRuleEvenOdd];
        [_internalLayer setMask:_circleMaskLayer];
        
        _highlightedButtonLayer = [[CAShapeLayer alloc] init];
        [_highlightedButtonLayer setFillColor:[[UIColor colorWithWhite:0 alpha:_pressedButtonAlpha] CGColor]];
        
        _clock = [[ALSCustomLockScreenClock alloc] initWithRadius:_largeCircleMinRadius-_largeCircleInnerPadding type:ALSClockTypeText preferencesManager:_preferencesManager];
        _buttons = [[ALSCustomLockScreenButtons alloc] initWithPreferencesManager:_preferencesManager];
        
        [self setFrame:frame];
        [self addSublayer:_internalLayer];
        [self addSublayer:_highlightedButtonLayer];
        [self layoutSublayers];
        
        [self setInstructions:@"Enter Passcode"];
        [self setupTimer];
        [self updateMaskWithPercentage:0];
    }
    return self;
}

- (void)buttonAtIndex:(int)index setHighlighted:(BOOL)highlighted {
    @synchronized(self.highlightedButtonIndexes) {
        NSUInteger buttonIndex = [self.highlightedButtonIndexes indexOfObject:@(index)];
        if(highlighted && buttonIndex==NSNotFound) {
            [self.highlightedButtonIndexes addObject:@(index)];
        }
        else if(!highlighted && buttonIndex!=NSNotFound) {
            [self.highlightedButtonIndexes removeObjectAtIndex:buttonIndex];
        }
    }
}

- (void)layoutSublayers {
    [super layoutSublayers];
    
    [self.circleMaskLayer setFrame:self.frame];
    [self.internalLayer setFrame:self.frame];
    [self.highlightedButtonLayer setFrame:self.frame];
    
    self.largeCircleMaxRadiusIncrement = ceilf(sqrt(self.bounds.size.width*self.bounds.size.width+self.bounds.size.height*self.bounds.size.height)/2)-self.largeCircleMinRadius;
    self.largeCircleMaxInternalPaddingIncrement = ((self.largeCircleMaxRadiusIncrement+self.largeCircleMinRadius)/(CGFloat)self.largeCircleMinRadius)*self.largeCircleInnerPadding-self.largeCircleInnerPadding;
}

+ (UIBezierPath *)pathForCircleWithRadius:(CGFloat)radius center:(CGPoint)center {
    return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(center.x-radius, center.y-radius, radius*2, radius*2) byRoundingCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(radius, radius)];
}

- (void)resetMask {
    self.currentPercentage = 0;
    [self setupTimer];
}

- (void)setInstructions:(NSString *)instructions {
    if(![instructions isEqualToString:_instructions]) {
        _instructions = instructions;
        //freed near-immediately
        CGPathRef instructionsPathRef = [ALSCustomLockScreenElement createPathForText:instructions fontName:@"AvenirNext-Medium"];
        self.instructionsPath = [UIBezierPath bezierPathWithCGPath:instructionsPathRef];
        CGPathRelease(instructionsPathRef);
    }
}

- (void)setupTimer {
    if(self.minuteTimer && [self.minuteTimer isValid]) {
        [self.minuteTimer invalidate];
        self.minuteTimer = nil;
    }
    
    NSDate *currentDate = [NSDate date];
    NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitSecond fromDate:currentDate];
    NSInteger currentSecond = [dateComponents second];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(((60-currentSecond)%60)) * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        ALSProxyTarget *proxyTarget = [ALSProxyTarget proxyForTarget:self selector:@selector(updateTimeOnMinute)];
        self.minuteTimer = [NSTimer scheduledTimerWithTimeInterval:60 target:proxyTarget selector:@selector(tick:) userInfo:nil repeats:YES];
        [self updateTimeOnMinute];
    });
    [self updateTimeWithDate:[NSDate date]];
}

- (void)updateMaskWithPercentage:(CGFloat)percentage {
    self.currentPercentage = percentage;
    
    CGPoint boundsCenter = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    UIBezierPath *mask = [UIBezierPath bezierPathWithRect:self.bounds];
    
    //find how much to add to the minimum circle size
    CGFloat largeCircleIncrement = self.largeCircleMaxRadiusIncrement*percentage;
    CGFloat largeRadius = self.largeCircleMinRadius+largeCircleIncrement;
    
    //mask the whole thing to the large outer circle
    [self.circleMaskLayer setPath:[[self class] pathForCircleWithRadius:largeRadius center:boundsCenter].CGPath];
    
    //add clock to internal path
    CGFloat clockScale = MAX(0,(1-percentage/self.clockInvisibleAt));
    CGFloat clockRadiusScaled = self.clock.radius*clockScale;
    UIBezierPath *clockPath = [self.clock clockPathForHour:self.currentHour minute:self.currentMinute];
    [clockPath applyTransform:CGAffineTransformMakeScale(clockScale, clockScale)];
    [clockPath applyTransform:CGAffineTransformMakeTranslation(boundsCenter.x-clockRadiusScaled, boundsCenter.y-clockRadiusScaled)];
    [mask appendPath:clockPath];
    
    //add buttons to internal path
    UIBezierPath *buttonsPath = [self.buttons buttonsPathForRadius:largeRadius middleButtonStartingRadius:(self.largeCircleMinRadius+self.largeCircleMaxRadiusIncrement*self.clockInvisibleAt)];
    [buttonsPath applyTransform:CGAffineTransformMakeTranslation(boundsCenter.x, boundsCenter.y)];
    [mask appendPath:buttonsPath];
    
    //add instructions to internal path
    UIBezierPath *instructionsPath = [self.instructionsPath copy];
    CGSize instructionsPathSize = CGPathGetPathBoundingBox(instructionsPath.CGPath).size;
    CGFloat instructionsPathScale = (self.instructionsHeight/instructionsPathSize.height);
    [instructionsPath applyTransform:CGAffineTransformMakeScale(instructionsPathScale, instructionsPathScale)];
    [instructionsPath applyTransform:CGAffineTransformMakeTranslation(boundsCenter.x-(instructionsPathSize.width*instructionsPathScale)/2, (boundsCenter.y-self.buttonRadius*3-self.buttonPadding)/2-(instructionsPathSize.height*instructionsPathScale)/2)];
    [mask appendPath:instructionsPath];
    
    [self.internalLayer setPath:mask.CGPath];
    
    //highlight the needed buttons
    UIBezierPath *highlightedButtonsPath = [UIBezierPath bezierPath];
    for(NSNumber *highlightedButtonNumber in self.highlightedButtonIndexes) {
        int buttonIndex = [highlightedButtonNumber intValue];
        CGFloat xOffset = (buttonIndex%3-1)*(self.buttonRadius*2+self.buttonPadding);
        CGFloat yOffset = (buttonIndex/3-1)*(self.buttonRadius*2+self.buttonPadding);
        [highlightedButtonsPath appendPath:[[self class] pathForCircleWithRadius:self.buttonRadius center:CGPointMake(boundsCenter.x+xOffset, boundsCenter.y+yOffset)]];
    }
    [self.highlightedButtonLayer setPath:highlightedButtonsPath.CGPath];
}

- (void)updateTimeOnMinute {
    //update current hour and minute. we use the time 5 seconds from now in case this method
    //is called a fraction of a second early (meaning we'll take the minute and hour at, for
    //example, 1:00:04.99 instead of 12:59:59.99, getting the current time of 1:00).
    [self updateTimeWithDate:[NSDate dateWithTimeInterval:5 sinceDate:[NSDate date]]];
}

- (void)updateTimeWithDate:(NSDate *)date {
    NSDateComponents *dateComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitHour|NSCalendarUnitMinute fromDate:date];
    NSInteger currentMinute = [dateComponents minute];
    NSInteger currentHour = [dateComponents hour];
    
    currentHour %= 12;
    if(currentHour == 0) {
        currentHour = 12;
    }
    
    self.currentHour = currentHour;
    self.currentMinute = currentMinute;
    
    [self updateMaskWithPercentage:self.currentPercentage];
    
    //preload the mask for the next minute
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSDateComponents *preloadDateComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitHour|NSCalendarUnitMinute fromDate:[NSDate dateWithTimeInterval:60 sinceDate:date]];
        NSInteger preloadMinute = [preloadDateComponents minute];
        NSInteger preloadHour = [preloadDateComponents hour];
        [self.clock preloadPathForHour:preloadHour minute:preloadMinute];
    });
}

@end
