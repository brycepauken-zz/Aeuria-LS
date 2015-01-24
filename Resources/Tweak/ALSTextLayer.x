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

@property (nonatomic) CGFloat margins;
@property (nonatomic, strong) NSString *subtitle;
@property (nonatomic, strong) UIFont *subtitleFont;
@property (nonatomic) CGSize subtitleSize;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) UIFont *titleFont;
@property (nonatomic) CGSize titleSize;

@end


@implementation ALSTextLayer

- (instancetype)init {
    self = [super init];
    if(self) {
        _margins = 10;
        
        _title = @"Enter";
        _titleFont = [UIFont fontWithName:@"AvenirNext-DemiBold" size:48];
        _titleSize = [[self class] sizeOfText:_title withFont:_titleFont];
        
        _subtitle = @"Passcode";
        _subtitleFont = [UIFont fontWithName:@"AvenirNext-UltraLight" size:48];
        _subtitleSize = [[self class] sizeOfText:_subtitle withFont:_subtitleFont];
        
        [self setFrame:CGRectMake(0, 0, ceilf(MAX(_titleSize.width, _subtitleSize.width))+_margins*2, ceilf(_titleSize.height+10+_subtitleSize.height)+_margins*2)];
        [self setContentsScale:[[UIScreen mainScreen] scale]];
        [self setNeedsDisplay];
    }
    return self;
}

- (void)drawInContext:(CGContextRef)ctx {
    //Draw text on image
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, NO, 0.0);
    CGContextRef textCtx = UIGraphicsGetCurrentContext();
    //Draw title
    CTLineRef titleLine = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)[[NSAttributedString alloc] initWithString:self.title attributes:@{NSFontAttributeName:self.titleFont}]);
    CGContextSetTextPosition(textCtx, (self.bounds.size.width-ceilf(self.titleSize.width))/2, self.titleSize.height+10+self.margins);
    CTLineDraw(titleLine, textCtx);
    CFRelease(titleLine);
    //Draw subtitle
    CTLineRef subtitleLine = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)[[NSAttributedString alloc] initWithString:self.subtitle attributes:@{NSFontAttributeName:self.subtitleFont}]);
    CGContextSetTextPosition(textCtx, (self.bounds.size.width-ceilf(self.subtitleSize.width))/2, self.margins);
    CTLineDraw(subtitleLine, textCtx);
    CFRelease(subtitleLine);
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
