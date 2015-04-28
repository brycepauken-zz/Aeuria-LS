//
//  ALSColorPreviewInnerShadow.m
//  Test2
//
//  Created by Bryce Pauken on 4/26/15.
//  Copyright (c) 2015 Bryce Pauken. All rights reserved.
//

#import "ALSPreferencesColorPickerInnerShadow.h"

@interface ALSPreferencesColorPickerInnerShadow()

@property (nonatomic) CGPathRef path;

@end

@implementation ALSPreferencesColorPickerInnerShadow

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        [self setBackgroundColor:[UIColor clearColor]];
        [self setUserInteractionEnabled:NO];
    }
    return self;
}

- (void)dealloc {
    CGPathRelease(_path);
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextAddPath(ctx, self.path);
    CGContextClip(ctx);
    
    CGColorRef shadowColor = [UIColor colorWithWhite:0.1 alpha:1].CGColor;
    CGContextSetAlpha(ctx, 0.5f);
    CGContextBeginTransparencyLayer(ctx, NULL);
    CGContextSetShadowWithColor(ctx, CGSizeMake(0, 1), 2, shadowColor);
    CGContextSetBlendMode(ctx, kCGBlendModeSourceOut);
    CGContextSetFillColorWithColor(ctx, shadowColor);
    CGContextAddPath(ctx, self.path);
    CGContextFillPath(ctx);
    CGContextEndTransparencyLayer(ctx);
}

- (void)setPath:(CGPathRef)path {
    _path = path;
    CGPathRetain(_path);
}

@end
