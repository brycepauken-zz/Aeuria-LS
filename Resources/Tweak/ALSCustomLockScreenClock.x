#import "ALSCustomLockScreenClock.h"

#import "ALSPreferencesManager.h"

@interface ALSCustomLockScreenClock()

//general properties
@property (nonatomic) CGFloat radius;
@property (nonatomic) ALSClockType type;

//caching properties
@property (nonatomic) NSInteger currentHour;
@property (nonatomic) NSInteger currentMinute;
@property (nonatomic, strong) UIBezierPath *currentPath;
@property (nonatomic) NSInteger preloadedHour;
@property (nonatomic) NSInteger preloadedMinute;
@property (nonatomic, strong) UIBezierPath *preloadedPath;

//preference properties
@property (nonatomic, strong) NSString *digitalTimeFont;
@property (nonatomic) int handInnerWidth;
@property (nonatomic) int handOuterWidth;
@property (nonatomic) int hourHandExtensionLength;
@property (nonatomic) int hourHandLength;
@property (nonatomic) int hourTickHeight;
@property (nonatomic) int hourTickInnerWidth;
@property (nonatomic) int hourTickOuterWidth;
@property (nonatomic) int hourTickPadding;
@property (nonatomic) int maxDigitalTimeHeight;
@property (nonatomic) int maxSubtitleHeight;
@property (nonatomic) int maxTitleHeight;
@property (nonatomic, strong) NSString *mainFont;
@property (nonatomic) int minuteHandExtensionLength;
@property (nonatomic) int minuteHandLength;
@property (nonatomic, strong) NSString *secondaryFont;
@property (nonatomic) BOOL shouldShowAmPm;
@property (nonatomic) BOOL shouldShowLeadingZero;
@property (nonatomic) int subtitleOffset;

@end

@implementation ALSCustomLockScreenClock

/*
 The init method — simply save our clock's type and radius.
 */
- (instancetype)initWithRadius:(CGFloat)radius type:(ALSClockType)type preferencesManager:(ALSPreferencesManager *)preferencesManager {
    self = [super initWithPreferencesManager:preferencesManager];
    if(self) {
        _digitalTimeFont = [preferencesManager preferenceForKey:@"digitalTimeFont"];
        _handInnerWidth = 8;
        _handOuterWidth = 2;
        _hourHandExtensionLength = 10;
        _hourHandLength = 40;
        _hourTickHeight = 16;
        _hourTickInnerWidth = 2;
        _hourTickOuterWidth = 4;
        _hourTickPadding = 0;
        _maxDigitalTimeHeight = [[preferencesManager preferenceForKey:@"maxDigitalTimeHeight"] intValue];
        _maxSubtitleHeight = [[preferencesManager preferenceForKey:@"maxSubtitleHeight"] intValue];
        _maxTitleHeight = [[preferencesManager preferenceForKey:@"maxTitleHeight"] intValue];
        _mainFont = [preferencesManager preferenceForKey:@"mainFont"];
        _minuteHandExtensionLength = 10;
        _minuteHandLength = 60;
        _secondaryFont = [preferencesManager preferenceForKey:@"secondaryFont"];
        _shouldShowAmPm = [[preferencesManager preferenceForKey:@"shouldShowAmPm"] boolValue];
        _shouldShowLeadingZero = [[preferencesManager preferenceForKey:@"shouldShowLeadingZero"] boolValue];
        _subtitleOffset = [[preferencesManager preferenceForKey:@"clockSubtitleTopPadding"] intValue];
        
        _radius = radius;
        _type = type;
    }
    return self;
}

/*
 The clockPathForHour:forMinute: method returns a UIBezierPath representing
 the clock cutout, taking into cached paths (due to the same hour and minute
 being used previously, or due to the new path being preloaded).
 */
- (UIBezierPath *)clockPathForHour:(NSInteger)hour minute:(NSInteger)minute {
    //if given hour and minute different from last call (which is cached in self.currentPath);
    if(!self.currentPath || hour!=self.currentHour || minute!=self.currentMinute) {
        //update current hour and minute
        self.currentHour = hour;
        self.currentMinute = minute;
        
        //if we've preloaded the requested path, return it; otherwise, generate a new path entirely
        if(self.preloadedPath && hour==self.preloadedHour && minute==self.preloadedMinute) {
            self.currentPath = self.preloadedPath;
        }
        else {
            self.currentPath = [self generatePathForHour:hour minute:minute];
        }
    }
    return self.currentPath;
}

/*
 The generatePathForHour:forMinute: method creates the UIBezierPath representing
 the clock cutout for the given hour and minute.
 */
- (UIBezierPath *)generatePathForHour:(NSInteger)hour minute:(NSInteger)minute {
    UIBezierPath *returnPath;
    if(self.type == ALSClockTypeText) {
        //get the hour and minute as strings
        NSString *hourString = [[[self class] numberToText:hour isMinute:NO] uppercaseString];
        NSString *minuteString = [[self class] numberToText:minute isMinute:YES];
        
        //get paths representing the hour and minute strings (rendered in a large font)
        //freed before return
        CGPathRef largeHourPath = [[self class] createPathForText:hourString fontName:self.mainFont];
        //freed before return
        CGPathRef largeMinutePath = [[self class] createPathForText:minuteString fontName:self.secondaryFont];
        
        CGSize largeHourPathSize = CGPathGetPathBoundingBox(largeHourPath).size;
        CGFloat hourScale = [[self class] scaleForPathOfSize:largeHourPathSize withinRadius:self.radius isHalfCircle:YES withOffsetFromCenter:0 maxHeight:self.maxTitleHeight];
        UIBezierPath *hourPath = [UIBezierPath bezierPathWithCGPath:largeHourPath];
        [hourPath applyTransform:CGAffineTransformMakeScale(hourScale, hourScale)];
        [hourPath applyTransform:CGAffineTransformMakeTranslation(self.radius-(largeHourPathSize.width*hourScale)/2, self.radius-(largeHourPathSize.height*hourScale))];
        
        CGSize largeMinutePathSize = CGPathGetPathBoundingBox(largeMinutePath).size;
        CGFloat minuteScale = [[self class] scaleForPathOfSize:largeMinutePathSize withinRadius:self.radius isHalfCircle:YES withOffsetFromCenter:self.subtitleOffset maxHeight:self.maxSubtitleHeight];
        UIBezierPath *minutePath = [UIBezierPath bezierPathWithCGPath:largeMinutePath];
        [minutePath applyTransform:CGAffineTransformMakeScale(minuteScale, minuteScale)];
        [minutePath applyTransform:CGAffineTransformMakeTranslation(self.radius-(largeMinutePathSize.width*minuteScale)/2, self.radius+self.subtitleOffset)];
        
        returnPath = [UIBezierPath bezierPath];
        [returnPath appendPath:hourPath];
        [returnPath appendPath:minutePath];
        
        CGPathRelease(largeHourPath);
        CGPathRelease(largeMinutePath);
    }
    else if(self.type == ALSClockTypeDigital) {
        NSString *timeString = [NSString stringWithFormat:[NSString stringWithFormat:@"%%%@i:%%02i%%@",(self.shouldShowLeadingZero?@"02":@"")],(int)hour,(int)minute,(self.shouldShowAmPm?@" AM":@"")];
        
        //freed before return
        CGPathRef largeTimePath = [[self class] createPathForText:timeString fontName:self.digitalTimeFont];
        
        CGSize largeTimePathSize = CGPathGetPathBoundingBox(largeTimePath).size;
        CGFloat timeScale = [[self class] scaleForPathOfSize:largeTimePathSize withinRadius:self.radius isHalfCircle:NO withOffsetFromCenter:0 maxHeight:self.maxDigitalTimeHeight];
        UIBezierPath *timePath = [UIBezierPath bezierPathWithCGPath:largeTimePath];
        [timePath applyTransform:CGAffineTransformMakeScale(timeScale, timeScale)];
        [timePath applyTransform:CGAffineTransformMakeTranslation(self.radius-(largeTimePathSize.width*timeScale)/2, self.radius-(largeTimePathSize.height*timeScale)/2)];
        
        returnPath = [UIBezierPath bezierPath];
        [returnPath appendPath:timePath];
        
        CGPathRelease(largeTimePath);
    }
    else if(self.type == ALSClockTypeAnalog) {
        returnPath = [UIBezierPath bezierPath];
        
        //create outer 12 hour ticks
        UIBezierPath *defaultHourTickMark = [[self class] pathForTickOfHeight:self.hourTickHeight innerWidth:self.hourTickInnerWidth outerWidth:self.hourTickOuterWidth];
        CGFloat hourTickRadius = self.radius-self.hourTickPadding-self.hourTickHeight;
        for(int i=0;i<12;i++) {
            CGFloat angle = (-M_PI/6)*i;
            UIBezierPath *hourTickMark = [defaultHourTickMark copy];
            [hourTickMark applyTransform:CGAffineTransformMakeRotation(angle)];
            [hourTickMark applyTransform:CGAffineTransformMakeTranslation(self.radius+hourTickRadius*sin(angle), self.radius-hourTickRadius*cos(angle))];
            [returnPath appendPath:hourTickMark];
        }
        
        UIBezierPath *hourHand = [[self class] pathForTickOfHeight:self.hourHandLength+self.hourHandExtensionLength innerWidth:self.handInnerWidth outerWidth:self.handOuterWidth];
        [hourHand applyTransform:CGAffineTransformMakeTranslation(0, self.hourHandExtensionLength)];
        [hourHand applyTransform:CGAffineTransformMakeRotation(M_PI*((hour+(minute/60.0))/6.0))];
        [hourHand applyTransform:CGAffineTransformMakeTranslation(self.radius, self.radius)];
        [returnPath appendPath:hourHand];
        
        UIBezierPath *minuteHand = [[self class] pathForTickOfHeight:self.minuteHandLength+self.minuteHandExtensionLength innerWidth:self.handInnerWidth outerWidth:self.handOuterWidth];
        [minuteHand applyTransform:CGAffineTransformMakeTranslation(0, self.minuteHandExtensionLength)];
        [minuteHand applyTransform:CGAffineTransformMakeRotation(M_PI*(minute/30.0))];
        [minuteHand applyTransform:CGAffineTransformMakeTranslation(self.radius, self.radius)];
        [returnPath appendPath:minuteHand];
    }
    return returnPath;
}

/*
 Returns a string representing the given hour or minute.
 */
+ (NSString *)numberToText:(int)num isMinute:(BOOL)isMinute {
    static NSArray *ones;
    static NSArray *tens;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ones = @[@"zero", @"one", @"two", @"three", @"four", @"five", @"six", @"seven", @"eight", @"nine", @"ten", @"eleven", @"twelve", @"thirteen", @"fourteen", @"fifteen", @"sixteen", @"seventeen", @"eighteen", @"nineteen"];
        tens = @[@"zero", @"ten", @"twenty", @"thirty", @"fourty", @"fifty"];
    });
    
    if(num>=0 && num<tens.count*10) {
        if(num<ones.count) {
            // XX:00
            if(isMinute && num==0) {
                return @"o-clock";
            }
            // XX:01 - XX:09
            else if(isMinute && num>0 && num<10) {
                return [@"oh-" stringByAppendingString:[ones objectAtIndex:num]];
            }
            // 00:XX - 19:XX
            // XX:10 - XX:19
            else {
                return [ones objectAtIndex:num];
            }
        }
        else {
            int ten = num/10;
            int one = num%10;
            // 20:XX
            // XX:20, XX:30, XX:40, XX:50
            if(one == 0) {
                return [tens objectAtIndex:ten];
            }
            // 21:XX, 22:XX, 23:XX, 24:XX
            // XX:21-XX:29, XX:31-XX:39, XX:41-XX:49, XX:51-XX:59
            else {
                return [NSString stringWithFormat:@"%@-%@",[tens objectAtIndex:ten],[ones objectAtIndex:one]];
            }
        }
    }
    return nil;
}

+ (UIBezierPath *)pathForTickOfHeight:(CGFloat)height innerWidth:(CGFloat)innerWidth outerWidth:(CGFloat)outerWidth {
    UIBezierPath *tickPath = [UIBezierPath bezierPath];
    [tickPath moveToPoint:CGPointMake(-innerWidth/2, 0)];
    [tickPath addLineToPoint:CGPointMake(-outerWidth/2, -height)];
    [tickPath addLineToPoint:CGPointMake(outerWidth/2, -height)];
    [tickPath addLineToPoint:CGPointMake(innerWidth/2, 0)];
    [tickPath closePath];
    return tickPath;
}

/*
 The preloadPathForHour:forMinute: method caches a path (generally for the
 upcoming minute) to make transitions more seamless.
 */
- (void)preloadPathForHour:(NSInteger)hour minute:(NSInteger)minute {
    //check if we need to update preloaded path
    if(!self.preloadedPath || hour!=self.preloadedHour || minute!=self.preloadedMinute) {
        self.preloadedPath = [self generatePathForHour:hour minute:minute];
        
        self.preloadedHour = hour;
        self.preloadedMinute = minute;
    }
}

/*
 Getter for the radius property
 */
- (CGFloat)radius {
    return _radius;
}

@end
