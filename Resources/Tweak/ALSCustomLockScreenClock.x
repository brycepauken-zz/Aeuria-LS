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
@property (nonatomic) int maxSubtitleHeight;
@property (nonatomic) int maxTitleHeight;
@property (nonatomic) int subtitleOffset;

@end

@implementation ALSCustomLockScreenClock

/*
 The init method — simply save our clock's type and radius.
 */
- (instancetype)initWithRadius:(CGFloat)radius type:(ALSClockType)type preferencesManager:(ALSPreferencesManager *)preferencesManager {
    self = [super initWithPreferencesManager:preferencesManager];
    if(self) {
        _maxSubtitleHeight = [[preferencesManager preferenceForKey:@"maxSubtitleHeight"] intValue];
        _maxTitleHeight = [[preferencesManager preferenceForKey:@"maxTitleHeight"] intValue];
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
            self.currentPath = [[self class] generatePathWithType:self.type radius:self.radius forHour:hour minute:minute maxTitleHeight:self.maxTitleHeight maxSubtitleHeight:self.maxSubtitleHeight subtitleOffset:self.subtitleOffset];
        }
    }
    //return a copy of the (possibly new) current path, so transformations don't affect our cache
    return [UIBezierPath bezierPathWithCGPath:self.currentPath.CGPath];
}

/*
 The generatePathForHour:forMinute: method creates the UIBezierPath representing
 the clock cutout for the given hour and minute.
 */
+ (UIBezierPath *)generatePathWithType:(ALSClockType)type radius:(CGFloat)radius forHour:(NSInteger)hour minute:(NSInteger)minute maxTitleHeight:(int)maxTitleHeight maxSubtitleHeight:(int)maxSubtitleHeight subtitleOffset:(int)subtitleOffset {
    if(type == ALSClockTypeText) {
        //get the hour and minute as strings
        NSString *hourString = [[self numberToText:hour isMinute:NO] uppercaseString];
        NSString *minuteString = [self numberToText:minute isMinute:YES];
        
        //get paths representing the hour and minute strings (rendered in a large font)
        //freed before return
        CGPathRef largeHourPath = [self createPathForText:hourString fontName:@"AvenirNext-DemiBold"];
        //freed before return
        CGPathRef largeMinutePath = [self createPathForText:minuteString fontName:@"Georgia-Italic"];
        
        CGSize largeHourPathSize = CGPathGetPathBoundingBox(largeHourPath).size;
        CGFloat hourScale = [self scaleForPathOfSize:largeHourPathSize withinRadius:radius isHalfCircle:YES withOffsetFromCenter:0 maxHeight:maxTitleHeight];
        UIBezierPath *hourPath = [UIBezierPath bezierPathWithCGPath:largeHourPath];
        [hourPath applyTransform:CGAffineTransformMakeScale(hourScale, hourScale)];
        [hourPath applyTransform:CGAffineTransformMakeTranslation(radius-(largeHourPathSize.width*hourScale)/2, radius-(largeHourPathSize.height*hourScale))];
        
        CGSize largeMinutePathSize = CGPathGetPathBoundingBox(largeMinutePath).size;
        CGFloat minuteScale = [self scaleForPathOfSize:largeMinutePathSize withinRadius:radius isHalfCircle:YES withOffsetFromCenter:subtitleOffset maxHeight:maxSubtitleHeight];
        UIBezierPath *minutePath = [UIBezierPath bezierPathWithCGPath:largeMinutePath];
        [minutePath applyTransform:CGAffineTransformMakeScale(minuteScale, minuteScale)];
        [minutePath applyTransform:CGAffineTransformMakeTranslation(radius-(largeMinutePathSize.width*minuteScale)/2, radius+subtitleOffset)];
        
        UIBezierPath *returnPath = [UIBezierPath bezierPath];
        [returnPath appendPath:hourPath];
        [returnPath appendPath:minutePath];
        
        CGPathRelease(largeHourPath);
        CGPathRelease(largeMinutePath);
        
        return returnPath;
    }
    return nil;
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

/*
 The preloadPathForHour:forMinute: method caches a path (generally for the
 upcoming minute) to make transitions more seamless.
 */
- (void)preloadPathForHour:(NSInteger)hour minute:(NSInteger)minute {
    //check if we need to update preloaded path
    if(!self.preloadedPath || hour!=self.preloadedHour || minute!=self.preloadedMinute) {
        self.preloadedPath = [[self class] generatePathWithType:self.type radius:self.radius forHour:hour minute:minute maxTitleHeight:self.maxTitleHeight maxSubtitleHeight:self.maxSubtitleHeight subtitleOffset:self.subtitleOffset];
        
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
