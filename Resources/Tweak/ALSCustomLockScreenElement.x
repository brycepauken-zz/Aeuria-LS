#import "ALSCustomLockScreenElement.h"

#import "ALSPreferencesManager.h"
#import <CoreText/CoreText.h>

@interface ALSCustomLockScreenElement()

@property (nonatomic, strong) ALSPreferencesManager *preferencesManager;

@end

@implementation ALSCustomLockScreenElement

static const int kPathDefaultFontSize = 256;
static const CGFloat kScaleSearchAcceptablePointDifference = 0.1;
static const CGFloat kScaleSearchAcceptableScaleDifference = 0.001;

- (instancetype)initWithPreferencesManager:(ALSPreferencesManager *)preferencesManager {
    self = [super init];
    if(self) {
        _preferencesManager = preferencesManager;
    }
    return self;
}

/*
 Creates a path for the given text and font, rendered at the font size given by kPathDefaultFontSize.
 */
+ (CGPathRef)createPathForText:(NSString *)text fontName:(NSString *)fontName {
    //freed before return
    CGMutablePathRef path = CGPathCreateMutable();
    
    //create font attributes once
    static NSMutableDictionary *fontAttributes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
         fontAttributes = [[NSMutableDictionary alloc] init];
    });
    @synchronized(self) {
        if(![fontAttributes objectForKey:fontName]) {
            //freed near-immediately
            CTFontRef titleFontRef = CTFontCreateWithName((__bridge CFStringRef)fontName, kPathDefaultFontSize, NULL);
            [fontAttributes setObject:[NSDictionary dictionaryWithObjectsAndKeys:(__bridge id)titleFontRef, kCTFontAttributeName, @(0.01), kCTKernAttributeName, nil] forKey:fontName];
            CFRelease(titleFontRef);
        }
    }
    
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:text attributes:[fontAttributes objectForKey:fontName]];
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
 Returns the factor needed to scale the given size to fit within the given radius.
 The isHalfCircle parameter dictates whether or not the size should be limited to
 half of the circle rather than its entirety, and if so, the offset parameter dictates
 how far from the center the path will be. Due to the complexities introduced by the
 offset parameter, the scale must be determined using a binary search type algorithm
 rather than with math alone.
 */
+ (CGFloat)scaleForPathOfSize:(CGSize)pathSize withinRadius:(CGFloat)radius isHalfCircle:(BOOL)isHalfCircle withOffsetFromCenter:(CGFloat)offset maxHeight:(int)maxHeight {
    if(isHalfCircle) {
        pathSize.width/=2;
        CGFloat radiusSquared = radius*radius;
        CGFloat minScale = 0;
        CGFloat maxScale = 1;
        CGFloat midScale, scaledWidth, scaledHeight, distanceFromCircle;
        CGFloat returnVal = -1;
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
                returnVal = midScale;
            }
        }
        if(returnVal < 0) {
            returnVal = minScale;
        }
        if(returnVal*pathSize.height > maxHeight) {
            return maxHeight/pathSize.height;
        }
        return returnVal;
    }
    else {
        CGFloat diagonal = radius*2;
        CGFloat height = (diagonal*pathSize.height)/sqrt(pathSize.width*pathSize.width + pathSize.height*pathSize.height);
        CGFloat returnVal = height/pathSize.height;
        if(returnVal*pathSize.height > maxHeight) {
            return maxHeight/pathSize.height;
        }
        return returnVal;
    }
}

@end
