#import "ALSClockView.h"

#import <CoreText/CTLine.h>
#import <CoreText/CTStringAttributes.h>

@interface ALSClockView()

@property (nonatomic, strong) UIColor *color;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic) CGFloat internalPadding;
@property (nonatomic) CGFloat radius;

@end


@implementation ALSClockView

- (instancetype)initWithRadius:(CGFloat)radius internalPadding:(CGFloat)internalPadding color:(UIColor *)color {
    self = [super initWithFrame:CGRectMake(0, 0, radius*2, radius*2)];
    if(self) {
        _color = color;
        _radius = radius;
        _internalPadding = internalPadding;
        
        _imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        [_imageView setImage:[[self class] timeViewWithRadius:_radius internalPadding:_internalPadding color:color]];
        
        [self addSubview:_imageView];
    }
    return self;
}

/*
 Returns the maximum font size for the given text and font that fits within a semicircle.
 There's also a verticalOffset parameter that lets you provide the pixel difference
 between the text and the middle of the circle.
 */
+ (int)fontSizeForText:(NSString *)text withFontName:(NSString *)name inSemiCircleOfRadius:(CGFloat)radius withVerticalOffset:(CGFloat)verticalOffset {
    //We use a 'binary search'-like algorithm to find the largest
    //fitting font size, so we need a min and max font value too.
    int minSize = 12;
    int maxSize = 72;
    CGFloat radiusSquared = radius*radius;
    
    while (maxSize >= minSize)  {
        int midSize = (minSize+maxSize)/2;
        CGSize textSize = [self sizeOfText:text withFont:[UIFont fontWithName:name size:midSize]];
        CGPoint cornerPoint = CGPointMake(textSize.width/2, textSize.height+verticalOffset);
        CGFloat outsideCircle = cornerPoint.x*cornerPoint.x+cornerPoint.y+cornerPoint.y - radiusSquared;
        
        if(outsideCircle>0) {
            maxSize = midSize-1;
        }
        else {
            minSize = midSize+1;
            if(outsideCircle==0) {
                break;
            }
        }
    }
    return minSize-1;
}

/*
 Returns the size of the text with the given font.
 */
+ (CGSize)sizeOfText:(NSString *)text withFont:(UIFont *)font {
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:text attributes:@{(__bridge NSString *)kCTFontAttributeName:font}];
    CTLineRef line = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)attributedString);
    CGRect bounds = CTLineGetBoundsWithOptions(line, kCTLineBoundsUseGlyphPathBounds);
    CFRelease(line);
    return CGSizeMake(ceilf(bounds.size.width), ceilf(bounds.size.height));
}


+ (CGImageRef)textMaskWithRadius:(CGFloat)radius internalPadding:(CGFloat)internalPadding {
    CGRect fullRect = CGRectMake(0, 0, radius*2, radius*2);
    int verticalOffset = 4;
    
    NSString *hourText = @"THREE";
    NSString *hourFontName = @"AvenirNext-DemiBold";
    int hourFontSize = [self fontSizeForText:hourText withFontName:hourFontName inSemiCircleOfRadius:radius-internalPadding withVerticalOffset:0];
    CGSize hourTextSize = [self sizeOfText:hourText withFont:[UIFont fontWithName:hourFontName size:hourFontSize]];
    CGPoint hourTextOffset = CGPointMake(radius-hourTextSize.width/2, radius-verticalOffset);
    
    NSString *minuteText = @"twenty-five";
    NSString *minuteFontName = @"Georgia-Italic";
    int minuteVerticalOffset = 20;
    int minuteFontSize = MIN(24,[self fontSizeForText:minuteText withFontName:minuteFontName inSemiCircleOfRadius:radius-internalPadding withVerticalOffset:minuteVerticalOffset]);
    CGSize minuteTextSize = [self sizeOfText:minuteText withFont:[UIFont fontWithName:minuteFontName size:minuteFontSize]];
    CGPoint minuteTextOffset = CGPointMake(radius-minuteTextSize.width/2, radius-minuteVerticalOffset/5-minuteTextSize.height-verticalOffset);
    
    //Create an image containing only our time text
    UIGraphicsBeginImageContextWithOptions(fullRect.size, NO, 0.0);
    CGContextRef textCtx = UIGraphicsGetCurrentContext();
    //draw hour
    CTLineRef hourLine = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)[[NSAttributedString alloc] initWithString:hourText attributes:@{NSFontAttributeName:[UIFont fontWithName:hourFontName size:hourFontSize]}]);
    CGContextSetTextPosition(textCtx, hourTextOffset.x, hourTextOffset.y);
    CTLineDraw(hourLine, textCtx);
    CFRelease(hourLine);
    //draw minute
    CTLineRef minuteLine = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)[[NSAttributedString alloc] initWithString:minuteText attributes:@{NSFontAttributeName:[UIFont fontWithName:minuteFontName size:minuteFontSize]}]);
    CGContextSetTextPosition(textCtx, minuteTextOffset.x, minuteTextOffset.y);
    CTLineDraw(minuteLine, textCtx);
    CFRelease(minuteLine);
    //get image
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    //Create an alpha-only image base
    CGImageRef originalMaskImage = [image CGImage];
    float width = CGImageGetWidth(originalMaskImage);
    float height = CGImageGetHeight(originalMaskImage);
    int strideLength = (((((int)width) + (4) - 1) / (4)) * (4));
    unsigned char * alphaData = calloc(strideLength * height, sizeof(unsigned char));
    CGContextRef alphaOnlyContext = CGBitmapContextCreate(alphaData, width, height, 8, strideLength, NULL, (CGBitmapInfo)kCGImageAlphaOnly);
    
    //Draw the text image to the alpha base
    CGContextDrawImage(alphaOnlyContext, CGRectMake(0, 0, width, height), originalMaskImage);
    
    //Return the resulting image as a mask
    CGImageRef alphaMaskImage = CGBitmapContextCreateImage(alphaOnlyContext);
    CGContextRelease(alphaOnlyContext);
    free(alphaData);
    CGImageRef finalMaskImage = CGImageMaskCreate(CGImageGetWidth(alphaMaskImage), CGImageGetHeight(alphaMaskImage), CGImageGetBitsPerComponent(alphaMaskImage), CGImageGetBitsPerPixel(alphaMaskImage), CGImageGetBytesPerRow(alphaMaskImage), CGImageGetDataProvider(alphaMaskImage), NULL, false);
    CGImageRelease(alphaMaskImage);
    return finalMaskImage;
}

+ (UIImage *)timeViewWithRadius:(CGFloat)radius internalPadding:(CGFloat)internalPadding color:(UIColor *)color {
    CGRect fullRect = CGRectMake(0, 0, radius*2, radius*2);
    UIGraphicsBeginImageContextWithOptions(fullRect.size, NO, 0.0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    CGContextClipToMask(ctx, fullRect, [self textMaskWithRadius:radius internalPadding:internalPadding]);
    
    [color setFill];
    CGContextFillEllipseInRect(ctx, fullRect);
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

@end
