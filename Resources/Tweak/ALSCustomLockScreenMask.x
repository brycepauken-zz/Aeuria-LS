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
@property (nonatomic, strong) CAShapeLayer *dotsDisplayLayer;
@property (nonatomic, strong) CAShapeLayer *dotsLayer;
@property (nonatomic, strong) NSMutableArray *highlightedButtonIndexes;
@property (nonatomic, strong) CAShapeLayer *highlightedButtonLayer;
@property (nonatomic, strong) NSString *instructions;
@property (nonatomic, strong) UIBezierPath *instructionsPath;
@property (nonatomic, strong) CAShapeLayer *internalLayer;
@property (nonatomic) CGFloat largeCircleMaxInternalPaddingIncrement;
@property (nonatomic) CGFloat largeCircleMaxRadiusIncrement;
@property (nonatomic, strong) NSTimer *minuteTimer;
@property (nonatomic, strong) ALSPreferencesManager *preferencesManager;
@property (nonatomic) NSTimeInterval updateUntilTime;

//preference properties
@property (nonatomic) int buttonPadding;
@property (nonatomic) int buttonRadius;
@property (nonatomic) float clockInvisibleAt;
@property (nonatomic) int dotPadding;
@property (nonatomic) int dotRadius;
@property (nonatomic) int dotVerticalOffset;
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
        _dotPadding = 16;
        _dotRadius = 8;
        _dotVerticalOffset = 18;
        _instructionsHeight = 30;
        _largeCircleInnerPadding = [[preferencesManager preferenceForKey:@"clockInnerPadding"] intValue];
        _largeCircleMinRadius = [[preferencesManager preferenceForKey:@"clockRadius"] intValue];
        _pressedButtonAlpha = 0.25;
        _updateUntilTime = -1;
        
        _currentHour = 0;
        _currentMinute = 0;
        _currentPercentage = 0;
        _highlightedButtonIndexes = [[NSMutableArray alloc] init];
        
        //masks to outer bounds
        _circleMaskLayer = [[CAShapeLayer alloc] init];
        [_circleMaskLayer setFillColor:[[UIColor blackColor] CGColor]];
        
        //holds main mask (clock & buttons)
        _internalLayer = [[CAShapeLayer alloc] init];
        [_internalLayer setFillColor:[[UIColor blackColor] CGColor]];
        [_internalLayer setFillRule:kCAFillRuleEvenOdd];
        [_internalLayer setMask:_circleMaskLayer];
        
        //holds dots above passcode entry
        _dotsLayer = [[CAShapeLayer alloc] init];
        [_dotsLayer setFillColor:[[UIColor blackColor] CGColor]];
        [_internalLayer addSublayer:_dotsLayer];
        _dotsDisplayLayer = [[CAShapeLayer alloc] init];
        [_dotsDisplayLayer setFillColor:[[UIColor blackColor] CGColor]];
        [_internalLayer addSublayer:_dotsDisplayLayer];
        
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

- (void)addDotAndAnimate:(BOOL)animate {
    //create new dot
    int existingDotCount = (int)self.dotsLayer.sublayers.count;
    
    CGFloat newDotOffset = (self.dotsLayer.bounds.size.width+(self.dotRadius*2*existingDotCount)+(self.dotPadding*(MAX(1,existingDotCount)-1)))/2+self.dotPadding+self.dotRadius*3/2+1;
    CAShapeLayer *dot = [[CAShapeLayer alloc] init];
    [dot setBounds:CGRectMake(0, 0, self.dotRadius*2, self.dotRadius*2)];
    [dot setFillColor:[[UIColor blackColor] CGColor]];
    [dot setPath:[[self class] pathForCircleWithRadius:self.dotRadius center:CGPointMake(self.dotRadius, self.dotRadius)].CGPath];
    [dot setPosition:CGPointMake(newDotOffset, self.dotRadius+4)];
    [dot setValue:@(existingDotCount) forKey:@"indexNum"];
    [self.dotsLayer addSublayer:dot];
    
    //animate alpha
    CABasicAnimation *opacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
    [opacityAnimation setDuration:animate?0.1:0];
    [opacityAnimation setFromValue:@(0)];
    [opacityAnimation setToValue:@(1)];
    [dot addAnimation:opacityAnimation forKey:@"opacity"];
    
    //animate position of all dots
    existingDotCount++;
    CGFloat firstDotOffset = (self.dotsLayer.bounds.size.width-(self.dotRadius*2*existingDotCount)-(self.dotPadding*(existingDotCount-1)))/2+self.dotRadius+1;
    for(CALayer *subdot in [self.dotsLayer.sublayers copy]) {
        int dotIndex = [[subdot valueForKey:@"indexNum"] intValue];
        
        CGFloat newPositionX = firstDotOffset+(self.dotRadius*2+self.dotPadding)*dotIndex;
        CABasicAnimation *positionAnimation = [CABasicAnimation animationWithKeyPath:@"position.x"];
        [positionAnimation setDuration:animate?0.1:0];
        [positionAnimation setFromValue:@(subdot==dot?dot.position.x:[subdot.presentationLayer position].x)];
        [positionAnimation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
        [positionAnimation setToValue:@(newPositionX)];
        [subdot addAnimation:positionAnimation forKey:@"position"];
        [subdot setPosition:CGPointMake(newPositionX, self.dotRadius+4)];
    }
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

/*
 Draws an inverted-alpha version of self.dotsLayer in self.dotsDisplayLater,
 and returns a CGRect containing the x offset and width.
 */
- (CGRect)drawDots {
    if(!self.dotsLayer.sublayers.count) {
        self.dotsDisplayLayer.contents = nil;
        return CGRectZero;
    }
    
    static const int bytesPerPixel = 4;
    static const int bitsPerComponent = 8;
    static CGColorSpaceRef colorSpace;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        colorSpace = CGColorSpaceCreateDeviceRGB();
    });
    
    //create a data-backed context, and draw the dots layer inside
    CGFloat screenScale = [UIScreen mainScreen].scale;
    int width = floor(self.dotsLayer.bounds.size.width)*screenScale;
    int height = floor(self.dotsLayer.bounds.size.height)*screenScale;
    int bytesPerRow = width * bytesPerPixel;
    unsigned char *data = calloc(width * height * bytesPerPixel, 1);
    CGContextRef ctx = CGBitmapContextCreate(data, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast|kCGBitmapByteOrder32Big);
    CGContextScaleCTM(ctx, screenScale, screenScale);
    [self.dotsLayer.presentationLayer renderInContext:ctx];
    
    //find starting and ending x values
    int startingX = 0, endingX = width, returnStartingX = 0, returnEndingX = width;
    int midYOffset = (height/2)*width;
    for(int x=startingX;x<width;x++) {
        if(data[(midYOffset+x)*bytesPerPixel+3]>0) {
            startingX = MAX(startingX, x-4-self.dotRadius*5);
            returnStartingX = x-2-self.dotRadius*2;
            break;
        }
    }
    for(int x=endingX;x>=startingX;x--) {
        if(data[(midYOffset+x)*bytesPerPixel+3]>0) {
            endingX = MIN(endingX, x+4+self.dotRadius*6+self.dotPadding*3);
            returnEndingX = x+2+self.dotRadius;
            break;
        }
    }
    
    //reverse alpha value
    for(int y=0;y<height;y++) {
        int yOffset = y*width;
        for(int x=startingX;x<endingX;x++) {
            int offset = (yOffset+x)*bytesPerPixel;
            data[offset+3] = 255-data[offset+3];
        }
    }
    
    //get image
    CGImageRef imageRef = CGBitmapContextCreateImage(ctx);
    UIImage *image = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGContextRelease(ctx);
    free(data);
    
    self.dotsDisplayLayer.contents = (id)image.CGImage;
    
    return CGRectMake(returnStartingX/screenScale, 0, (returnEndingX-returnStartingX)/screenScale, height);
}

- (BOOL)isAnimating {
    for(CALayer *layer in [self.dotsLayer.sublayers copy]) {
        if(layer.animationKeys.count) {
            return YES;
        }
    }
    return NO;
}

- (void)layoutSublayers {
    [super layoutSublayers];
    
    [self.circleMaskLayer setFrame:self.bounds];
    [self.internalLayer setFrame:self.bounds];
    [self.highlightedButtonLayer setFrame:self.bounds];
    
    //dotsLayer's frame is a long horizontal bar placed dotVerticalOffset pixels above the highest button
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    CGFloat maxScreenDimension = MAX(screenSize.width, screenSize.height);
    CGRect dotsLayerFrame = CGRectMake((self.bounds.size.width-maxScreenDimension)/2, self.bounds.size.height/2-self.buttonRadius*3-self.buttonPadding-self.dotVerticalOffset-self.dotRadius*2-4, maxScreenDimension, self.dotRadius*2+8);
    [self.dotsDisplayLayer setFrame:dotsLayerFrame];
    dotsLayerFrame.origin.y = -dotsLayerFrame.size.height*2;
    [self.dotsLayer setFrame:dotsLayerFrame];
    
    self.largeCircleMaxRadiusIncrement = ceilf(sqrt(self.bounds.size.width*self.bounds.size.width+self.bounds.size.height*self.bounds.size.height)/2)-self.largeCircleMinRadius;
    self.largeCircleMaxInternalPaddingIncrement = ((self.largeCircleMaxRadiusIncrement+self.largeCircleMinRadius)/(CGFloat)self.largeCircleMinRadius)*self.largeCircleInnerPadding-self.largeCircleInnerPadding;
}

- (BOOL)needsUpdate {
    if(self.updateUntilTime < 0) {
        return NO;
    }
    if(CACurrentMediaTime() < self.updateUntilTime) {
        return YES;
    }
    self.updateUntilTime = -1;
    return NO;
}

+ (UIBezierPath *)pathForCircleWithRadius:(CGFloat)radius center:(CGPoint)center {
    return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(center.x-radius, center.y-radius, radius*2, radius*2) byRoundingCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(radius, radius)];
}

- (void)removeAllDots {
    for(CALayer *subdot in [self.dotsLayer.sublayers copy]) {
        [CATransaction begin];
        [CATransaction setCompletionBlock:^{
            [subdot removeFromSuperlayer];
        }];
        CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
        [scaleAnimation setDuration:0.1];
        [scaleAnimation setFromValue:[NSValue valueWithCATransform3D:CATransform3DIdentity]];
        [scaleAnimation setToValue:[NSValue valueWithCATransform3D:CATransform3DMakeScale(0, 0, 1)]];
        [subdot addAnimation:scaleAnimation forKey:@"transform"];
        [subdot setTransform:CATransform3DMakeScale(0, 0, 1)];
        [CATransaction commit];
    }
}

- (void)resetMask {
    self.currentPercentage = 0;
    for(CALayer *subdot in [self.dotsLayer.sublayers copy]) {
        [subdot removeFromSuperlayer];
    }
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

- (void)shakeDots {
    CABasicAnimation *shakeAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
    [shakeAnimation setAutoreverses:YES];
    [shakeAnimation setDuration:0.05];
    [shakeAnimation setFromValue:[NSValue valueWithCGPoint:CGPointMake(self.dotsDisplayLayer.position.x-10, self.dotsDisplayLayer.position.y)]];
    [shakeAnimation setRepeatCount:4];
    [shakeAnimation setToValue:[NSValue valueWithCGPoint:CGPointMake(self.dotsDisplayLayer.position.x+10, self.dotsDisplayLayer.position.y)]];
    [self.dotsDisplayLayer addAnimation:shakeAnimation forKey:@"position"];
}

- (void)updateMaskWithPercentage:(CGFloat)percentage {
    self.currentPercentage = percentage;
    
    CGPoint boundsCenter = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    
    //find how much to add to the minimum circle size
    CGFloat largeCircleIncrement = self.largeCircleMaxRadiusIncrement*percentage;
    CGFloat largeRadius = self.largeCircleMinRadius+largeCircleIncrement;
    
    //mask the whole thing to the large outer circle
    [self.circleMaskLayer setPath:[[self class] pathForCircleWithRadius:largeRadius center:boundsCenter].CGPath];
    
    //add clock to internal path
    UIBezierPath *mask = [UIBezierPath bezierPathWithRect:self.bounds];
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
    
    //draw dots and remove area behind it
    CGRect dotsRect = [self drawDots];
    if(dotsRect.size.width && dotsRect.size.width<self.bounds.size.width) {
        [mask appendPath:[UIBezierPath bezierPathWithRect:CGRectMake(self.dotsDisplayLayer.frame.origin.x+dotsRect.origin.x+2, self.dotsDisplayLayer.frame.origin.y+2, dotsRect.size.width, self.dotsDisplayLayer.frame.size.height-4)]];
    }
    
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
    self.updateUntilTime = CACurrentMediaTime()+0.1;
    
    //preload the mask for the next minute
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSDateComponents *preloadDateComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitHour|NSCalendarUnitMinute fromDate:[NSDate dateWithTimeInterval:60 sinceDate:date]];
        NSInteger preloadMinute = [preloadDateComponents minute];
        NSInteger preloadHour = [preloadDateComponents hour];
        [self.clock preloadPathForHour:preloadHour minute:preloadMinute];
    });
}

@end
