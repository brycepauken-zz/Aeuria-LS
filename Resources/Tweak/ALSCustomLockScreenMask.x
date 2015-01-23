#import "ALSCustomLockScreenMask.h"

@interface ALSCustomLockScreenMask()

@property (nonatomic) CGFloat buttonRadius;
@property (nonatomic) CGFloat buttonPadding;
@property (nonatomic) CGFloat largeCircleInternalPadding;
@property (nonatomic) CGFloat largeCircleMaxRadius;
@property (nonatomic) CGFloat largeCircleMinRadius;
@property (nonatomic) CGFloat middleButtonVisiblePercentage;
@property (nonatomic) CGFloat scrollPercentage;

@end


@implementation ALSCustomLockScreenMask

/*
 Our init method simply sets everything up.
 */
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super init];
    if(self) {
        _buttonRadius = 44;
        _buttonPadding = 10;
        _largeCircleInternalPadding = 20;
        _largeCircleMinRadius = 100;
        _middleButtonVisiblePercentage = 0.5;
        
        [self setFrame:frame];
    }
    return self;
}

+ (UIBezierPath *)pathForCircleWithRadius:(CGFloat)radius center:(CGPoint)center {
    return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(center.x-radius, center.y-radius, radius*2, radius*2) byRoundingCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(radius, radius)];
}

/*
 Reposition everytying as needed.
 */
- (void)layoutSublayers {
    [super layoutSublayers];
    
    self.largeCircleMaxRadius = ceilf(sqrt(self.bounds.size.width*self.bounds.size.width+self.bounds.size.height*self.bounds.size.height)/2);
}

/*
 Caled via our display link/
 Check if we have to do any updating, and then do it!
 */
- (void)updateMaskWithLargeRadius:(CGFloat)largeRadius smallRadius:(CGFloat)smallRadius axesButtonsRadii:(CGFloat)axesButtonsRadii diagonalButtonsRadii:(CGFloat)diagonalButtonsRadii zeroButtonRadius:(CGFloat)zeroButtonRadius {
    UIBezierPath *mask = [UIBezierPath bezierPath];
    
    //create mask for large circle
    [mask appendPath:[[self class] pathForCircleWithRadius:largeRadius center:CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2)]];
    
    //remove inner circle (for clock view and middle button)
    [mask appendPath:[[self class] pathForCircleWithRadius:smallRadius center:CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2)]];
    
    //remove buttons on axes (directly above, below, left, or right of center button)
    CGFloat buttonOffset = self.buttonRadius*2+self.buttonPadding;
    for(int i=0;i<9;i++) {
        if(i==4) {
            continue;
        }
        [mask appendPath:[[self class] pathForCircleWithRadius:(i%2==0?diagonalButtonsRadii:axesButtonsRadii) center:CGPointMake(self.bounds.size.width/2+(i%3==0?-buttonOffset:(i%3==2?buttonOffset:0)), self.bounds.size.height/2+(i<3?-buttonOffset:(i>=6?buttonOffset:0)))]];
    }
    [mask appendPath:[[self class] pathForCircleWithRadius:zeroButtonRadius center:CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2+(self.buttonRadius*4+self.buttonPadding*2))]];
    
    [self setFillColor:[[UIColor blackColor] CGColor]];
    [self setPath:[mask CGPath]];
    [self setFillRule:kCAFillRuleEvenOdd];
}

@end
