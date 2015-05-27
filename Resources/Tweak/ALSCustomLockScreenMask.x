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
@property (nonatomic, strong) CAShapeLayer *clockCutOutLayer;
@property (nonatomic, strong) CAShapeLayer *clockLayer;
@property (nonatomic, strong) CAShapeLayer *clockLayerMask;
@property (nonatomic, strong) CAShapeLayer *clockRenderingLayerMask;
@property (nonatomic) float clockInvisibleAt;
@property (nonatomic, strong) CAShapeLayer *clockRenderingLayer;
@property (nonatomic) NSString *currentDate;
@property (nonatomic) NSInteger currentHour;
@property (nonatomic) NSInteger currentMinute;
@property (nonatomic) CGFloat currentPercentage;
@property (nonatomic, weak) UIView *customLockScreen;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) CAShapeLayer *dotsDisplayLayer;
@property (nonatomic, strong) CAShapeLayer *dotsLayer;
@property (nonatomic, strong) NSMutableArray *highlightedButtonIndexes;
@property (nonatomic, strong) CAShapeLayer *highlightedButtonLayer;
@property (nonatomic) CGFloat horizontalPosition;
@property (nonatomic, strong) NSString *instructions;
@property (nonatomic, strong) UIBezierPath *instructionsPath;
@property (nonatomic, strong) CAShapeLayer *internalLayer;
@property (nonatomic) CGFloat keyboardHeight;
@property (nonatomic) CGFloat largeCircleMaxRadiusIncrement;
@property (nonatomic, strong) UIBezierPath *lastKnownClockPath;
@property (nonatomic) CGFloat lastKnownRadius;
@property (nonatomic, strong) CAShapeLayer *maskLayer;
@property (nonatomic, strong) NSTimer *minuteTimer;
@property (nonatomic, strong) ALSPreferencesManager *preferencesManager;
@property (nonatomic) ALSLockScreenSecurityType securityType;
@property (nonatomic) NSTimeInterval updateUntilTime;
@property (nonatomic) CGFloat verticalPosition;

//preference properties
@property (nonatomic) int buttonDistanceFromEdge;
@property (nonatomic) int buttonPadding;
@property (nonatomic) int buttonRadius;
@property (nonatomic) int clockDotRadius;
@property (nonatomic) int clockType;
@property (nonatomic) NSString *dateFormat;
@property (nonatomic) int dotPadding;
@property (nonatomic) int dotRadius;
@property (nonatomic) int dotVerticalOffset;
@property (nonatomic) int instructionsHeight;
@property (nonatomic) int largeCircleInnerPadding;
@property (nonatomic) int largeCircleMinRadius;
@property (nonatomic) float pressedButtonAlpha;
@property (nonatomic) BOOL shouldHideEnterPasscodeText;
@property (nonatomic) int textFieldCornerRadius;
@property (nonatomic) int textFieldHeight;
@property (nonatomic) int textFieldHorizontalPadding;

@end

@implementation ALSCustomLockScreenMask

- (instancetype)initWithFrame:(CGRect)frame preferencesManager:(ALSPreferencesManager *)preferencesManager {
    self = [super init];
    if(self) {
        _preferencesManager = preferencesManager;
        _buttonDistanceFromEdge = [[preferencesManager preferenceForKey:@"passcodeButtonDistanceFromEdge"] intValue];
        _buttonPadding = [[preferencesManager preferenceForKey:@"passcodeButtonPadding"] intValue];
        _buttonRadius = [[preferencesManager preferenceForKey:@"passcodeButtonRadius"] intValue];
        _clockDotRadius = [[preferencesManager preferenceForKey:@"clockDotRadius"] intValue];
        _clockType = [[preferencesManager preferenceForKey:@"clockType"] intValue];
        _dateFormat = [preferencesManager preferenceForKey:@"dateFormat"];
        _dotPadding = [[preferencesManager preferenceForKey:@"characterDotSidePadding"] intValue];
        _dotRadius = [[preferencesManager preferenceForKey:@"characterDotRadius"] intValue];
        _dotVerticalOffset = [[preferencesManager preferenceForKey:@"characterDotBottomPadding"] intValue];
        _instructionsHeight = [[preferencesManager preferenceForKey:@"enterPasscodeTextHeight"] intValue];
        _largeCircleInnerPadding = [[preferencesManager preferenceForKey:@"clockInnerPadding"] intValue];
        _largeCircleMinRadius = [[preferencesManager preferenceForKey:@"clockRadius"] intValue];
        _pressedButtonAlpha = [[preferencesManager preferenceForKey:@"passcodeButtonPressedAlpha"] floatValue];
        _shouldHideEnterPasscodeText = [[preferencesManager preferenceForKey:@"shouldHideEnterPasscodeText"] boolValue];
        _textFieldCornerRadius = [[preferencesManager preferenceForKey:@"passcodeTextFieldCornerRadius"] intValue];
        _textFieldHeight = [[preferencesManager preferenceForKey:@"passcodeTextFieldHeight"] intValue];
        _textFieldHorizontalPadding = [[preferencesManager preferenceForKey:@"passcodeTextFieldSidePadding"] intValue];
        
        _currentHour = 0;
        _currentMinute = 0;
        _currentPercentage = 0;
        _highlightedButtonIndexes = [[NSMutableArray alloc] init];
        _updateUntilTime = -1;
        
        _horizontalPosition = 0.5;
        _verticalPosition = 0.5;
        
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateFormat:_dateFormat];
        
        _internalLayer = [[CAShapeLayer alloc] init];
        
        //masks to outer bounds
        _circleMaskLayer = [[CAShapeLayer alloc] init];
        [_circleMaskLayer setFillColor:[[UIColor blackColor] CGColor]];
        [_internalLayer setMask:_circleMaskLayer];
        
        //holds main mask (clock & buttons)
        _maskLayer = [[CAShapeLayer alloc] init];
        [_maskLayer setFillColor:[[UIColor blackColor] CGColor]];
        [_maskLayer setFillRule:kCAFillRuleEvenOdd];
        [_internalLayer addSublayer:_maskLayer];
        
        _clockLayer = [[CAShapeLayer alloc] init];
        [_clockLayer setFillColor:[[UIColor blackColor] CGColor]];
        [_internalLayer addSublayer:_clockLayer];
        
        _clockLayerMask = [[CAShapeLayer alloc] init];
        [_clockLayerMask setFillColor:[[UIColor blackColor] CGColor]];
        [_clockLayerMask setFillRule:kCAFillRuleEvenOdd];
        [_clockLayer setMask:_clockLayerMask];
        
        _clockRenderingLayer = [[CAShapeLayer alloc] init];
        [_clockRenderingLayer setFillColor:[[UIColor blackColor] CGColor]];
        [_internalLayer addSublayer:_clockRenderingLayer];
        
        _clockRenderingLayerMask = [[CAShapeLayer alloc] init];
        [_clockRenderingLayerMask setFillColor:[[UIColor blackColor] CGColor]];
        [_clockRenderingLayerMask setFillRule:kCAFillRuleEvenOdd];
        [_clockRenderingLayer setMask:_clockRenderingLayerMask];
        
        _clockCutOutLayer = [[CAShapeLayer alloc] init];
        [_clockCutOutLayer setFillColor:[[UIColor blackColor] CGColor]];
        [_clockCutOutLayer setFillRule:kCAFillRuleEvenOdd];
        [_maskLayer setMask:_clockCutOutLayer];
        
        //holds dots above passcode entry
        _dotsLayer = [[CAShapeLayer alloc] init];
        [_dotsLayer setFillColor:[[UIColor blackColor] CGColor]];
        [_maskLayer addSublayer:_dotsLayer];
        _dotsDisplayLayer = [[CAShapeLayer alloc] init];
        [_dotsDisplayLayer setFillColor:[[UIColor blackColor] CGColor]];
        [_maskLayer addSublayer:_dotsDisplayLayer];
        
        _highlightedButtonLayer = [[CAShapeLayer alloc] init];
        [_highlightedButtonLayer setFillColor:[[UIColor colorWithWhite:0 alpha:_pressedButtonAlpha] CGColor]];
        [_internalLayer addSublayer:_highlightedButtonLayer];
        
        _clock = [[ALSCustomLockScreenClock alloc] initWithRadius:_largeCircleMinRadius-_largeCircleInnerPadding type:_clockType preferencesManager:_preferencesManager];
        _buttons = [[ALSCustomLockScreenButtons alloc] initWithPreferencesManager:_preferencesManager];
        
        [self setFrame:frame];
        [self addSublayer:_internalLayer];
        [self layoutSublayers];
        
        [self setInstructions:@"Enter Passcode"];
        [self setupTimer];
        [self updateMaskWithPercentage:0];
    }
    return self;
}

- (void)addDotAndAnimate:(BOOL)animate {
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    
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
        [subdot addAnimation:positionAnimation forKey:@"ShakeAnimation"];
        [subdot setPosition:CGPointMake(newPositionX, self.dotRadius+4)];
    }
    [CATransaction commit];
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
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    [self.circleMaskLayer setFrame:self.bounds];
    [self.highlightedButtonLayer setFrame:self.bounds];
    [self.internalLayer setFrame:self.bounds];
    [self.maskLayer setFrame:self.bounds];
    [self.clockCutOutLayer setFrame:self.bounds];
    
    CGRect clockLayerFrame = CGRectMake(self.bounds.size.width*self.horizontalPosition-self.largeCircleMinRadius, self.bounds.size.height*self.verticalPosition-self.largeCircleMinRadius, self.largeCircleMinRadius*2, self.largeCircleMinRadius*2);
    [self.clockLayer setFrame:clockLayerFrame];
    [self.clockLayerMask setFrame:CGRectMake(0, 0, self.largeCircleMinRadius*2, self.largeCircleMinRadius*2)];
    [self.clockLayerMask setPath:[[self class] pathForCircleWithRadius:self.largeCircleMinRadius center:CGPointMake(self.largeCircleMinRadius, self.largeCircleMinRadius)].CGPath];
    [self.clockRenderingLayerMask setFrame:CGRectMake(0, 0, self.largeCircleMinRadius*2, self.largeCircleMinRadius*2)];
    clockLayerFrame.origin.y = -clockLayerFrame.size.height*2;
    [self.clockRenderingLayer setFrame:clockLayerFrame];
    
    [self updateDotsLayerFrame];
    
    CGFloat largestHorizontalDistanceToEdge = (0.5+fabs(0.5-self.horizontalPosition))*self.bounds.size.width;
    CGFloat largestVerticalDistanceToEdge = (0.5+fabs(0.5-self.verticalPosition))*self.bounds.size.height;
    self.largeCircleMaxRadiusIncrement = sqrt(largestHorizontalDistanceToEdge*largestHorizontalDistanceToEdge+largestVerticalDistanceToEdge*largestVerticalDistanceToEdge)-self.largeCircleMinRadius;
    
    CGFloat clockInvisibleNeededRadiusIncrement = (self.buttonDistanceFromEdge+(self.buttonRadius*2+self.buttonPadding)*M_SQRT2+self.buttonRadius)-self.largeCircleMinRadius;
    self.clockInvisibleAt = clockInvisibleNeededRadiusIncrement/self.largeCircleMaxRadiusIncrement;
    self.buttons.clockInvisibleAt = self.clockInvisibleAt;
    
    [CATransaction commit];
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

- (void)removeAllDotsAndAnimate:(BOOL)animate withCompletion:(void (^)())completion {
    if(!self.dotsLayer.sublayers.count) {
        return;
    }
    
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        self.dotsLayer.sublayers = nil;
        if(completion) {
            completion();
        }
    }];
    for(CALayer *subdot in [self.dotsLayer.sublayers copy]) {
        CABasicAnimation *scaleAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
        [scaleAnimation setDuration:animate?0.1:0];
        [scaleAnimation setFromValue:[NSValue valueWithCATransform3D:CATransform3DIdentity]];
        [scaleAnimation setToValue:[NSValue valueWithCATransform3D:CATransform3DMakeScale(0, 0, 1)]];
        [subdot addAnimation:scaleAnimation forKey:@"transform"];
        [subdot setTransform:CATransform3DMakeScale(0, 0, 1)];
    }
    [CATransaction commit];
}

- (void)removeDotAndAnimate:(BOOL)animate {
    [CATransaction begin];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    
    //animate position of all dots
    int existingDotCount = (int)self.dotsLayer.sublayers.count-1;
    CGFloat firstDotOffset = (self.dotsLayer.bounds.size.width-(self.dotRadius*2*existingDotCount)-(self.dotPadding*(existingDotCount-1)))/2+self.dotRadius+1;
    CALayer *lastDot;
    for(CALayer *subdot in [self.dotsLayer.sublayers copy]) {
        int dotIndex = [[subdot valueForKey:@"indexNum"] intValue];
        if(dotIndex == -1) {
            continue;
        }
        
        CGFloat newPositionX = firstDotOffset+(self.dotRadius*2+self.dotPadding)*dotIndex;
        CABasicAnimation *positionAnimation = [CABasicAnimation animationWithKeyPath:@"position.x"];
        [positionAnimation setDuration:animate?0.1:0];
        [positionAnimation setFromValue:@([subdot.presentationLayer position].x)];
        [positionAnimation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
        [positionAnimation setToValue:@(newPositionX)];
        [subdot addAnimation:positionAnimation forKey:@"ShakeAnimation"];
        [subdot setPosition:CGPointMake(newPositionX, self.dotRadius+4)];
        
        if(dotIndex == existingDotCount) {
            lastDot = subdot;
        }
    }
    [CATransaction commit];
    
    [CATransaction begin];
    [CATransaction setCompletionBlock:^{
        [lastDot removeFromSuperlayer];
    }];
    [CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
    if(lastDot) {
        [lastDot setValue:@(-1) forKey:@"indexNum"];
        
        //animate alpha
        CABasicAnimation *opacityAnimation = [CABasicAnimation animationWithKeyPath:@"opacity"];
        [opacityAnimation setDuration:animate?0.1:0];
        [opacityAnimation setFromValue:@(1)];
        [opacityAnimation setToValue:@(0)];
        [lastDot addAnimation:opacityAnimation forKey:@"opacity"];
        [lastDot setOpacity:0];
    }
    [CATransaction commit];
}

- (void)resetMask {
    self.currentPercentage = 0;
    for(CALayer *subdot in [self.dotsLayer.sublayers copy]) {
        [subdot removeFromSuperlayer];
    }
    [self setupTimer];
}

- (void)setHorizontalPosition:(CGFloat)horizontalPosition verticalPosition:(CGFloat)verticalPosition {
    self.horizontalPosition = horizontalPosition;
    self.verticalPosition = verticalPosition;
    [self layoutSublayers];
}

- (void)setInstructions:(NSString *)instructions {
    if(![instructions isEqualToString:_instructions]) {
        _instructions = instructions;
        
        if(![instructions isEqualToString:@"Enter Passcode"]) {
            //freed near-immediately
            CGPathRef instructionsPathRef = [ALSCustomLockScreenElement createPathForText:instructions fontName:@"AvenirNext-Medium"];
            self.instructionsPath = [UIBezierPath bezierPathWithCGPath:instructionsPathRef];
            CGPathRelease(instructionsPathRef);
        }
        else {
            //all freed near-immediately
            CGPathRef instructionsEnterPathRef = [ALSCustomLockScreenElement createPathForText:@"Enter" fontName:@"AvenirNext-Medium"];
            CGPathRef instructionsDashPathRef = [ALSCustomLockScreenElement createPathForText:@".." fontName:@"AvenirNext-Medium"];
            CGPathRef instructionsPasscodePathRef = [ALSCustomLockScreenElement createPathForText:@"Passcode" fontName:@"AvenirNext-Regular"];
            
            CGSize instructionsEnterPathSize = CGPathGetPathBoundingBox(instructionsEnterPathRef).size;
            CGSize instructionsDashPathSize = CGPathGetPathBoundingBox(instructionsDashPathRef).size;
            CGSize instructionsPasscodePathSize = CGPathGetPathBoundingBox(instructionsPasscodePathRef).size;
            
            UIBezierPath *enterPath = [UIBezierPath bezierPathWithCGPath:instructionsEnterPathRef];
            UIBezierPath *passcodePath = [UIBezierPath bezierPathWithCGPath:instructionsPasscodePathRef];
            [passcodePath applyTransform:CGAffineTransformMakeTranslation(instructionsEnterPathSize.width+instructionsDashPathSize.width, (instructionsEnterPathSize.height-instructionsPasscodePathSize.height)/2)];
            [enterPath appendPath:passcodePath];
            [enterPath applyTransform:CGAffineTransformMakeTranslation(instructionsDashPathSize.height, 0)];
            self.instructionsPath = enterPath;
            
            CGPathRelease(instructionsEnterPathRef);
            CGPathRelease(instructionsDashPathRef);
            CGPathRelease(instructionsPasscodePathRef);
        }
    }
}

- (void)setSecurityType:(ALSLockScreenSecurityType)securityType {
    _securityType = securityType;
    [self updateDotsLayerFrame];
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
    [self.dotsDisplayLayer addAnimation:shakeAnimation forKey:@"ShakeAnimation"];
}

- (void)updateDotsLayerFrame {
    //dotsLayer's frame is a long horizontal bar placed dotVerticalOffset pixels above the highest button
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    CGFloat maxScreenDimension = MAX(screenSize.width, screenSize.height);
    CGRect dotsLayerFrame = CGRectMake((self.bounds.size.width-maxScreenDimension)/2, self.bounds.size.height/2-self.buttonRadius*3-self.buttonPadding-self.dotVerticalOffset-self.dotRadius*2-4, maxScreenDimension, self.dotRadius*2+8);
    [self.dotsDisplayLayer setFrame:dotsLayerFrame];
    if(self.securityType == ALSLockScreenSecurityTypePhrase) {
        dotsLayerFrame.origin.y = (self.bounds.size.height-self.keyboardHeight)/2-dotsLayerFrame.size.height/2;
    }
    else {
        dotsLayerFrame.origin.y = -dotsLayerFrame.size.height*2;
    }
    [self.dotsLayer setFrame:dotsLayerFrame];
}

- (void)updateMaskWithPercentage:(CGFloat)percentage {
    self.currentPercentage = percentage;
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    
    CGPoint boundsCenter;
    if(self.securityType != ALSLockScreenSecurityTypePhrase || !self.keyboardHeight) {
        boundsCenter = CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2);
    }
    else {
        boundsCenter = CGPointMake(self.bounds.size.width/2, (self.bounds.size.height-self.keyboardHeight*percentage)/2);
    }
    CGPoint clockCenter = CGPointMake(self.bounds.size.width*self.horizontalPosition, self.bounds.size.height*self.verticalPosition);
    
    UIBezierPath *mask = [UIBezierPath bezierPathWithRect:self.bounds];
    UIBezierPath *clockCutOutMask = [UIBezierPath bezierPathWithRect:self.bounds];
    
    UIBezierPath *clockPath = [self.clock clockPathForHour:self.currentHour minute:self.currentMinute date:self.currentDate];
    if(clockPath != self.lastKnownClockPath) {
        self.lastKnownClockPath = clockPath;
        
        UIBezierPath *newClockPath = [clockPath copy];
        [newClockPath applyTransform:CGAffineTransformMakeTranslation(self.clockLayer.bounds.size.width/2-self.clock.radius, self.clockLayer.bounds.size.height/2-self.clock.radius)];
        [self.clockRenderingLayer setPath:newClockPath.CGPath];
        
        UIBezierPath *clockRenderingLayerMaskPath = [UIBezierPath bezierPathWithRect:self.clockRenderingLayerMask.bounds];
        if(self.clockType == ALSClockTypeAnalog && self.clockDotRadius>0) {
            [clockRenderingLayerMaskPath appendPath:[[self class] pathForCircleWithRadius:self.clockDotRadius center:CGPointMake(self.clockRenderingLayerMask.bounds.size.width/2, self.clockRenderingLayerMask.bounds.size.height/2)]];
        }
        [self.clockRenderingLayerMask setPath:clockRenderingLayerMaskPath.CGPath];
        
        static const int bytesPerPixel = 4;
        static const int bitsPerComponent = 8;
        static CGColorSpaceRef colorSpace;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            colorSpace = CGColorSpaceCreateDeviceRGB();
        });
        
        //create a data-backed context, and draw the dots layer inside
        CGFloat screenScale = [UIScreen mainScreen].scale;
        int width = floor(self.clockLayer.bounds.size.width)*screenScale;
        int height = floor(self.clockLayer.bounds.size.height)*screenScale;
        int bytesPerRow = width * bytesPerPixel;
        unsigned char *data = calloc(width * height * bytesPerPixel, 1);
        CGContextRef ctx = CGBitmapContextCreate(data, width, height, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast|kCGBitmapByteOrder32Big);
        CGContextTranslateCTM(ctx, 0, height);
        //CGContextScaleCTM(ctx, 1.0, -1.0);
        CGContextScaleCTM(ctx, screenScale, -screenScale);
        [self.clockRenderingLayer renderInContext:ctx];
        
        //reverse alpha value
        for(int y=0;y<height;y++) {
            int yOffset = y*width;
            for(int x=0;x<width;x++) {
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
        
        self.clockLayer.contents = (id)image.CGImage;
    }
    
    if(self.securityType == ALSLockScreenSecurityTypeCode) {
        //find how much to add to the minimum circle size
        CGFloat largeCircleIncrement = self.largeCircleMaxRadiusIncrement*percentage;
        CGFloat largeRadius = self.largeCircleMinRadius+largeCircleIncrement;
        self.lastKnownRadius = largeRadius;
        
        //mask the whole thing to the large outer circle
        [self.circleMaskLayer setPath:[[self class] pathForCircleWithRadius:largeRadius center:clockCenter].CGPath];
        
        //transform clock path and cut out area below
        CGFloat clockScale = MAX(0,(1-percentage/self.clockInvisibleAt));
        CGFloat clockRadiusScaled = self.clock.radius*clockScale;
        [self.clockLayer setTransform:CATransform3DMakeScale(clockScale, clockScale, 1)];
        [clockCutOutMask appendPath:[[self class] pathForCircleWithRadius:clockRadiusScaled center:clockCenter]];
        
        //add buttons to internal path
        UIBezierPath *buttonsPath = [self.buttons buttonsPathForRadius:largeRadius horizontalCenterOffset:(clockCenter.x-boundsCenter.x) verticalCenterOffset:(clockCenter.y-boundsCenter.y)];
        [buttonsPath applyTransform:CGAffineTransformMakeTranslation(boundsCenter.x, boundsCenter.y)];
        [mask appendPath:buttonsPath];
        
        //add instructions to internal path
        if(!self.shouldHideEnterPasscodeText) {
            UIBezierPath *instructionsPath = [self.instructionsPath copy];
            CGSize instructionsPathSize = CGPathGetPathBoundingBox(instructionsPath.CGPath).size;
            CGFloat instructionsPathScale = (self.instructionsHeight/instructionsPathSize.height);
            [instructionsPath applyTransform:CGAffineTransformMakeScale(instructionsPathScale, instructionsPathScale)];
            [instructionsPath applyTransform:CGAffineTransformMakeTranslation(boundsCenter.x-(instructionsPathSize.width*instructionsPathScale)/2, (boundsCenter.y-self.buttonRadius*3-self.buttonPadding)/2-(instructionsPathSize.height*instructionsPathScale)/2)];
            [mask appendPath:instructionsPath];
        }
        
        //draw dots and remove area behind it
        CGRect dotsRect = [self drawDots];
        if(dotsRect.size.width && dotsRect.size.width<self.bounds.size.width) {
            [mask appendPath:[UIBezierPath bezierPathWithRect:CGRectMake(self.dotsDisplayLayer.frame.origin.x+dotsRect.origin.x+2, self.dotsDisplayLayer.frame.origin.y+2, dotsRect.size.width, self.dotsDisplayLayer.frame.size.height-4)]];
        }
        
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
    else if(self.securityType == ALSLockScreenSecurityTypePhrase) {
        CGFloat largeCircleIncrement = (self.largeCircleMaxRadiusIncrement+self.largeCircleMinRadius)*percentage;
        CGFloat largeRadius = self.largeCircleMinRadius+largeCircleIncrement;
        
        [self.circleMaskLayer setPath:[UIBezierPath bezierPathWithRoundedRect:CGRectMake(boundsCenter.x-largeRadius, boundsCenter.y-self.largeCircleMinRadius, largeRadius*2, self.largeCircleMinRadius*2) cornerRadius:self.largeCircleMinRadius].CGPath];
    
        //transform clock path and cut out area below
        CGFloat verticalTranslation = self.bounds.size.height/2-boundsCenter.y;
        [self.clockLayer setTransform:CATransform3DMakeTranslation(largeCircleIncrement, -verticalTranslation, 1)];
        UIBezierPath *clockCutOut = [[self class] pathForCircleWithRadius:self.clock.radius center:boundsCenter];
        [clockCutOut applyTransform:CGAffineTransformMakeTranslation(largeCircleIncrement, 0)];
        [clockCutOutMask appendPath:clockCutOut];
        
        CGFloat screenOffset = (self.bounds.size.width-self.customLockScreen.bounds.size.width)/2;
        CGFloat leftEdgeOffset = MAX(self.textFieldHorizontalPadding+screenOffset, boundsCenter.x-self.clock.radius-MAX(self.textFieldHorizontalPadding,largeCircleIncrement)+self.textFieldHorizontalPadding);
        CGFloat rightEdgeOffset = MIN(self.bounds.size.width-self.textFieldHorizontalPadding-screenOffset, boundsCenter.x-self.clock.radius+MAX(self.textFieldHorizontalPadding,largeCircleIncrement)-self.textFieldHorizontalPadding);
        [mask appendPath:[UIBezierPath bezierPathWithRoundedRect:CGRectMake(leftEdgeOffset, boundsCenter.y-self.textFieldHeight/2, rightEdgeOffset-leftEdgeOffset, self.textFieldHeight) byRoundingCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(self.textFieldCornerRadius, self.textFieldCornerRadius)]];
    
        if(!self.shouldHideEnterPasscodeText) {
            UIBezierPath *instructionsPath = [self.instructionsPath copy];
            CGSize instructionsPathSize = CGPathGetPathBoundingBox(instructionsPath.CGPath).size;
            CGFloat instructionsPathScale = (self.instructionsHeight/instructionsPathSize.height);
            [instructionsPath applyTransform:CGAffineTransformMakeScale(instructionsPathScale, instructionsPathScale)];
            [instructionsPath applyTransform:CGAffineTransformMakeTranslation(leftEdgeOffset+(rightEdgeOffset-leftEdgeOffset)/2-(instructionsPathSize.width*instructionsPathScale)/2, (self.bounds.size.height-self.keyboardHeight-self.clock.radius-self.textFieldHeight-instructionsPathSize.height*instructionsPathScale)/2+10)];
            [mask appendPath:instructionsPath];
        }
    }
    else if(self.securityType == ALSLockScreenSecurityTypeNone) {
        CGFloat largeCircleIncrement = (self.largeCircleMaxRadiusIncrement+self.largeCircleMinRadius)*percentage;
        
        [self.circleMaskLayer setPath:[UIBezierPath bezierPathWithRoundedRect:CGRectMake(boundsCenter.x-self.largeCircleMinRadius+largeCircleIncrement, boundsCenter.y-self.largeCircleMinRadius, self.largeCircleMinRadius*2, self.largeCircleMinRadius*2) cornerRadius:self.largeCircleMinRadius].CGPath];
        
        //transform clock path and cut out area below
        [self.clockLayer setTransform:CATransform3DMakeTranslation(largeCircleIncrement, 0, 1)];
        UIBezierPath *clockCutOut = [[self class] pathForCircleWithRadius:self.clock.radius center:boundsCenter];
        [clockCutOut applyTransform:CGAffineTransformMakeTranslation(largeCircleIncrement, 0)];
        [clockCutOutMask appendPath:clockCutOut];
    }
    
    [self.maskLayer setPath:mask.CGPath];
    [self.clockCutOutLayer setPath:clockCutOutMask.CGPath];
    
    [CATransaction commit];
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
    
    self.currentHour = currentHour;
    self.currentMinute = currentMinute;
    self.currentDate = [self.dateFormatter stringFromDate:date];
    
    [self updateMaskWithPercentage:self.currentPercentage];
    self.updateUntilTime = CACurrentMediaTime()+0.1;
    
    //preload the mask for the next minute
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSDate *preloadDate = [NSDate dateWithTimeInterval:60 sinceDate:date];
        NSDateComponents *preloadDateComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitHour|NSCalendarUnitMinute fromDate:preloadDate];
        NSInteger preloadMinute = [preloadDateComponents minute];
        NSInteger preloadHour = [preloadDateComponents hour];
        NSString *preloadDateString = [self.dateFormatter stringFromDate:preloadDate];
        [self.clock preloadPathForHour:preloadHour minute:preloadMinute date:preloadDateString];
    });
}

@end
