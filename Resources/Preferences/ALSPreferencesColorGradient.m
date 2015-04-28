//
//  ALSColorGradient.m
//  Test2
//
//  Created by Bryce Pauken on 4/26/15.
//  Copyright (c) 2015 Bryce Pauken. All rights reserved.
//

#import "ALSPreferencesColorGradient.h"

@interface ALSPreferencesColorGradient()

@property (nonatomic) int accessibleSize;
@property (nonatomic) float hue;

@end

@implementation ALSPreferencesColorGradient

/*
 Helper function for RGBfromHSL
 */
static float RGBfromHue(float p, float q, float t) {
    if(t < 0) t += 1;
    if(t > 1) t -= 1;
    if(t < 1/6.0f) return p+(q-p)*6.0f*t;
    if(t < 1/2.0f) return q;
    if(t < 2/3.0f) return p+(q-p)*(2/3.0f-t)*6.0f;
    return p;
}

/*
 Converts an HSL color (arguments h, s, l in [0..1])
 to an RGB color (char array with r, g, b in [0...255])
 */
static unsigned char *RGBfromHSL(float h, float s, float l) {
    unsigned char *rgb = malloc(3);
    h = MAX(0,MIN(1,h));
    s = MAX(0,MIN(1,s));
    l = MAX(0,MIN(1,l));
    
    if(s == 0) {
        rgb[0] = rgb[1] = rgb[2] = (char)(l * 255.0f);
    }
    else {
        float q = l<=0.5f?(l*(1+s)):(l+s-l*s);
        float p = 2*l-q;
        rgb[0] = (char)(RGBfromHue(p, q, h+1/3.0f)*255.0f);
        rgb[1] = (char)(RGBfromHue(p, q, h)*255.0f);
        rgb[2] = (char)(RGBfromHue(p, q, h-1/3.0f)*255.0f);
    }
    return rgb;
}

/*
 Returns the UIColor corresponding to the given point
 */
- (UIColor *)colorAtPoint:(CGPoint)point {
    int width = floor(self.bounds.size.width);
    int height = floor(self.bounds.size.height);
    int startingX = (width-self.accessibleSize)/2;
    int startingY = (height-self.accessibleSize)/2;
    
    unsigned char *rgb = RGBfromHSL(self.hue, -fabs((floorf(point.x)-startingX)/(CGFloat)self.accessibleSize*2-1)+1, 1-(floorf(point.y)-startingY)/(CGFloat)self.accessibleSize);
    UIColor *color = [UIColor colorWithRed:rgb[0]/255.0f green:rgb[1]/255.0f blue:rgb[2]/255.0f alpha:1];
    free(rgb);
    return color;
    
}

/*
 Draws the color gradient with the current hue property
 */
- (void)drawRect:(CGRect)rect {
    static const int bytesPerPixel = 4;
    static const int bitsPerComponent = 8;
    static CGColorSpaceRef colorSpace;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        colorSpace = CGColorSpaceCreateDeviceRGB();
    });
    
    int width = floor(self.bounds.size.width)*[UIScreen mainScreen].scale;
    int height = floor(self.bounds.size.height)*[UIScreen mainScreen].scale;
    int scaledAccessibleSize = self.accessibleSize*[UIScreen mainScreen].scale;
    int halfScaledAccessibleSize = scaledAccessibleSize/2;
    int startingX = (width-scaledAccessibleSize)/2;
    int startingY = (height-scaledAccessibleSize)/2;
    int bytesPerRow = width * bytesPerPixel;
    
    unsigned char *data = malloc(width * height * bytesPerPixel);
    
    for(int y=0;y<height;y++) {
        int yOffset = y*width;
        for(int x=0;x<width;x++) {
            int offset = (yOffset+x)*bytesPerPixel;
            
            int relativeX = x-startingX;
            float saturation, brightness;
            if(relativeX < halfScaledAccessibleSize) {
                saturation = relativeX*2/(CGFloat)scaledAccessibleSize;
            }
            else {
                saturation = (1-relativeX/(CGFloat)scaledAccessibleSize)*2;
            }
            brightness = 1-(y-startingY)/(CGFloat)scaledAccessibleSize;
            
            unsigned char *rgb = RGBfromHSL(self.hue, saturation, brightness);
            data[offset] = rgb[0];
            data[offset+1] = rgb[1];
            data[offset+2] = rgb[2];
            data[offset+3] = 255;
            free(rgb);
            
        }
    }
    
    CGContextRef ctx = CGBitmapContextCreate(data, self.bounds.size.width*[UIScreen mainScreen].scale, self.bounds.size.height*[UIScreen mainScreen].scale, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast|kCGBitmapByteOrder32Big);
    CGImageRef imageRef = CGBitmapContextCreateImage(ctx);
    UIImage *image = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGContextRelease(ctx);
    free(data);
    
    [image drawInRect:self.bounds];
}

+ (UIImage *)imageForHuePickerWithSize:(CGSize)size {
    static const int bytesPerPixel = 4;
    static const int bitsPerComponent = 8;
    static CGColorSpaceRef colorSpace;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        colorSpace = CGColorSpaceCreateDeviceRGB();
    });
    
    int width = floor(size.width)*[UIScreen mainScreen].scale;
    int height = floor(size.height)*[UIScreen mainScreen].scale;
    int bytesPerRow = width * bytesPerPixel;
    
    unsigned char *data = malloc(width * height * bytesPerPixel);
    
    for(int x=0;x<width;x++) {
        unsigned char *rgb = RGBfromHSL(x/(CGFloat)width, 1, 0.66);
        for(int y=0;y<height;y++) {
            int offset = (x+y*width)*bytesPerPixel;
            data[offset] = rgb[0];
            data[offset+1] = rgb[1];
            data[offset+2] = rgb[2];
            data[offset+3] = 255;
        }
        free(rgb);
    }
    
    CGContextRef ctx = CGBitmapContextCreate(data, size.width*[UIScreen mainScreen].scale, size.height*[UIScreen mainScreen].scale, bitsPerComponent, bytesPerRow, colorSpace, kCGImageAlphaPremultipliedLast|kCGBitmapByteOrder32Big);
    CGImageRef imageRef = CGBitmapContextCreateImage(ctx);
    UIImage *image = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGContextRelease(ctx);
    free(data);
    
    return image;
}

/*
 Update accessible size and redraw
 */
- (void)setAccessibleSize:(int)accessibleSize {
    _accessibleSize = accessibleSize;
    [self setNeedsDisplay];
}

/*
 Update hue and redraw
 */
- (void)setHue:(float)hue {
    _hue = hue;
    [self setNeedsDisplay];
}

@end
