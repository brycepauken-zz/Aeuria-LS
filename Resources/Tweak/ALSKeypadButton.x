#import "ALSKeypadButton.h"

#import <CoreText/CTLine.h>
#import <CoreText/CTStringAttributes.h>

@interface ALSKeypadButton()

@property (nonatomic, strong) UIColor *color;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic) int number;
@property (nonatomic) CGFloat radius;

@end

@implementation ALSKeypadButton

- (instancetype)initWithRadius:(CGFloat)radius number:(int)number color:(UIColor *)color {
    self = [super initWithFrame:CGRectMake(0, 0, radius*2, radius*2)];
    if(self) {
        _color = color;
        _number = number;
        _radius = radius;
        
        _imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, _radius*2, _radius*2)];
        [_imageView setImage:[[self class] imageWithRadius:_radius number:_number color:_color highlight:NO]];
        [self addSubview:_imageView];
    }
    return self;
}

+ (UIImage *)imageWithRadius:(CGFloat)radius number:(int)number color:(UIColor *)color highlight:(BOOL)highlight {
    UIFont *font = [UIFont fontWithName:@"AvenirNext-Medium" size:48];
    
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(radius*2, radius*2), NO, 0.0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    CGContextTranslateCTM(ctx, 0, radius*2);
    CGContextScaleCTM(ctx, 1.0, -1.0);
    
    NSString *text = [NSString stringWithFormat:@"%i",number];
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:text attributes:@{(__bridge NSString *)kCTFontAttributeName:font, (__bridge NSString *)kCTForegroundColorFromContextAttributeName:(__bridge NSNumber *)kCFBooleanTrue}];
    CTLineRef line = CTLineCreateWithAttributedString((__bridge CFAttributedStringRef)attributedString);
    CGRect bounds = CTLineGetBoundsWithOptions(line, kCTLineBoundsUseGlyphPathBounds);
    CGSize textSize = CGSizeMake(ceilf(bounds.size.width), ceilf(bounds.size.height));
    
    //draw shadow
    //CGContextSetShadowWithColor(ctx, CGSizeMake(0, 1), 2, [UIColor colorWithWhite:0.1 alpha:0.8].CGColor);
    
    CGContextSetTextPosition(ctx, radius-textSize.width/2-(number==1?8:(number==8?3:2)), radius-textSize.height/2);
    CGContextSetFillColorWithColor(ctx, color.CGColor);
    CTLineDraw(line, ctx);
    CFRelease(line);
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return image;
}


@end
