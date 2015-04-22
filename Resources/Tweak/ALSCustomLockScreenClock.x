#import "ALSCustomLockScreenClock.h"

#import <CoreText/CoreText.h>

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

@end

@implementation ALSCustomLockScreenClock

static const int kPathDefaultFontSize = 256;
static const CGFloat kScaleSearchAcceptablePointDifference = 0.1;
static const CGFloat kScaleSearchAcceptableScaleDifference = 0.001;
static const int kSubtitleOffset = 14;

/*
 The init method — simply save our clock's type and radius.
 */
- (instancetype)initWithRadius:(CGFloat)radius type:(ALSClockType)type {
    self = [super init];
    if(self) {
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
            self.currentPath = [[self class] generatePathWithType:self.type radius:self.radius forHour:hour minute:minute];
        }
    }
    //return a copy of the (possibly new) current path, so transformations don't affect our cache
    return [UIBezierPath bezierPathWithCGPath:self.currentPath.CGPath];
}

/*
 The generatePathForHour:forMinute: method creates the UIBezierPath representing
 the clock cutout for the given hour and minute.
 */
+ (UIBezierPath *)generatePathWithType:(ALSClockType)type radius:(CGFloat)radius forHour:(NSInteger)hour minute:(NSInteger)minute {
    if(type == ALSClockTypeText) {
        //get the hour and minute as strings
        NSString *hourString = [[self numberToText:hour isMinute:NO] uppercaseString];
        NSString *minuteString = [self numberToText:minute isMinute:YES];
        
        //get paths representing the hour and minute strings (rendered in a large font)
        //freed before return
        CGPathRef largeHourPath = [self createPathForText:hourString isTitle:YES];
        //freed before return
        CGPathRef largeMinutePath = [self createPathForText:minuteString isTitle:NO];
        
        CGSize largeHourPathSize = CGPathGetPathBoundingBox(largeHourPath).size;
        CGFloat hourScale = [self scaleForPathOfSize:largeHourPathSize withinRadius:radius isHalfCircle:YES withOffsetFromCenter:0];
        UIBezierPath *hourPath = [UIBezierPath bezierPathWithCGPath:largeHourPath];
        [hourPath applyTransform:CGAffineTransformMakeScale(hourScale, hourScale)];
        [hourPath applyTransform:CGAffineTransformMakeTranslation(radius-(largeHourPathSize.width*hourScale)/2, radius-(largeHourPathSize.height*hourScale))];
        
        CGSize largeMinutePathSize = CGPathGetPathBoundingBox(largeMinutePath).size;
        CGFloat minuteScale = [self scaleForPathOfSize:largeMinutePathSize withinRadius:radius isHalfCircle:YES withOffsetFromCenter:kSubtitleOffset];
        UIBezierPath *minutePath = [UIBezierPath bezierPathWithCGPath:largeMinutePath];
        [minutePath applyTransform:CGAffineTransformMakeScale(minuteScale, minuteScale)];
        [minutePath applyTransform:CGAffineTransformMakeTranslation(radius-(largeMinutePathSize.width*minuteScale)/2, radius+kSubtitleOffset)];
        
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
 Creates a path for the given text, rendered at the font size given by kPathDefaultFontSize.
 The isTitle parameter only determines which font to use.
 */
+ (CGPathRef)createPathForText:(NSString *)text isTitle:(BOOL)isTitle {
    //freed before return
    CGMutablePathRef path = CGPathCreateMutable();
    
    static NSDictionary *titleStringAttributes;
    static NSDictionary *subtitleStringAttributes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //freed near-immediately
        CTFontRef titleFontRef = CTFontCreateWithName(CFSTR("AvenirNext-DemiBold"), kPathDefaultFontSize, NULL);
        titleStringAttributes = [NSDictionary dictionaryWithObjectsAndKeys:(__bridge id)titleFontRef, kCTFontAttributeName, @(0.01), kCTKernAttributeName, nil];
        CFRelease(titleFontRef);
        
        //freed near-immediately
        CTFontRef subtitleFontRef = CTFontCreateWithName(CFSTR("Georgia-Italic"), kPathDefaultFontSize, NULL);
        subtitleStringAttributes = [NSDictionary dictionaryWithObjectsAndKeys:(__bridge id)subtitleFontRef, kCTFontAttributeName, @(0.01), kCTKernAttributeName, nil];
        CFRelease(subtitleFontRef);
    });
    
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:text attributes:(isTitle?titleStringAttributes:subtitleStringAttributes)];
    //freed after loop
    CTLineRef line = CTLineCreateWithAttributedString((CFAttributedStringRef)attributedString);
    CFArrayRef runArray = CTLineGetGlyphRuns(line);
    for(CFIndex i=0; i<CFArrayGetCount(runArray); i++) {
        CTRunRef run = (CTRunRef)CFArrayGetValueAtIndex(runArray, i);
        CTFontRef runFont = CFDictionaryGetValue(CTRunGetAttributes(run), kCTFontAttributeName);
        for(CFIndex j=0; j<CTRunGetGlyphCount(run); j++) {
            CFRange thisGlyphRange = CFRangeMake(j, 1);
            CGGlyph glyph;
            CGPoint position;
            CTRunGetGlyphs(run, thisGlyphRange, &glyph);
            CTRunGetPositions(run, thisGlyphRange, &position);
            
            //freed near-immediately
            CGPathRef letter = CTFontCreatePathForGlyph(runFont, glyph, NULL);
            CGAffineTransform t = CGAffineTransformMakeTranslation(position.x, position.y);
            t = CGAffineTransformScale(t, 1, -1);
            CGPathAddPath(path, &t, letter);
            CGPathRelease(letter);
        }
    }
    CFRelease(line);
    
    CGRect pathBounds = CGPathGetPathBoundingBox(path);
    CGAffineTransform pathTranslation = CGAffineTransformMakeTranslation(-pathBounds.origin.x, -pathBounds.origin.y);
    
    //not freed here; owned by caller of method
    CGPathRef returnPath = CGPathCreateCopyByTransformingPath(path, &pathTranslation);
    CGPathRelease(path);
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

/*
 The preloadPathForHour:forMinute: method caches a path (generally for the
 upcoming minute) to make transitions more seamless.
 */
- (void)preloadPathForHour:(NSInteger)hour minute:(NSInteger)minute {
    //check if we need to update preloaded path
    if(!self.preloadedPath || hour!=self.preloadedHour || minute!=self.preloadedMinute) {
        self.preloadedPath = [[self class] generatePathWithType:self.type radius:self.radius forHour:hour minute:minute];
        
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

/*
 Returns the factor needed to scale the given size to fit within the given radius.
 The isHalfCircle parameter dictates whether or not the size should be limited to
 half of the circle rather than its entirety, and if so, the offset parameter dictates
 how far from the center the path will be. Due to the complexities introduced by the
 offset parameter, the scale must be determined using a binary search type algorithm
 rather than with math alone.
 */
+ (CGFloat)scaleForPathOfSize:(CGSize)pathSize withinRadius:(CGFloat)radius isHalfCircle:(BOOL)isHalfCircle withOffsetFromCenter:(CGFloat)offset {
    if(isHalfCircle) {
        pathSize.width/=2;
        CGFloat radiusSquared = radius*radius;
        CGFloat minScale = 0;
        CGFloat maxScale = 1;
        CGFloat midScale, scaledWidth, scaledHeight, distanceFromCircle;
        int tries = 0;
        while(maxScale-minScale > kScaleSearchAcceptableScaleDifference) {
            ++tries;
            midScale = (minScale+maxScale)/2;
            scaledWidth = pathSize.width*midScale;
            scaledHeight = pathSize.height*midScale+offset;
            distanceFromCircle = radiusSquared-(scaledWidth*scaledWidth+scaledHeight*scaledHeight);
            
            if(distanceFromCircle < 0) {
                maxScale = midScale;
            }
            else if(distanceFromCircle > kScaleSearchAcceptablePointDifference) {
                minScale = midScale;
            }
            else {
                return midScale;
            }
        }
        
        return minScale;
    }
    return 1;
}

@end
