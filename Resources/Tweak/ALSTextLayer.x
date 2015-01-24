//
//  ALSTextLayer.m
//  aeurials
//
//  Created by Bryce Pauken on 1/23/15.
//  Copyright (c) 2015 kingfish. All rights reserved.
//

#import "ALSTextLayer.h"

#import <CoreText/CTLine.h>
#import <CoreText/CTStringAttributes.h>

@interface ALSTextLayer()

@property (nonatomic, strong) UIFont *font;
@property (nonatomic, strong) NSString *text;
@property (nonatomic) CGSize textSize;

@end


@implementation ALSTextLayer

- (instancetype)init {
    self = [super init];
    if(self) {
        _font = [UIFont fontWithName:@"AvenirNext-DemiBold" size:48];
        _text = @"Passcode";
        _textSize = [[self class] sizeOfText:_text withFont:_font];
        
        [self setFrame:CGRectMake(0, 0, ceilf(_textSize.width)+10, ceilf(_textSize.height)+10)];
        [self setContentsScale:[[UIScreen mainScreen] scale]];
        [self setNeedsDisplay];
    }
    return self;
}

- (void)drawInContext:(CGContextRef)ctx {
    //Draw text on image
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0.0);
    CGContextRef textCtx = UIGraphicsGetCurrentContext();
    CTLineRef line = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)[[NSAttributedString alloc] initWithString:self.text attributes:@{NSFontAttributeName:self.font}]);
    CGContextSetTextPosition(textCtx, 5, 5);
    CTLineDraw(line, textCtx);
    CFRelease(line);
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
    
    CGContextDrawImage(ctx, CGRectMake(0, 0, width/2, height/2), finalMaskImage);
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

@end
