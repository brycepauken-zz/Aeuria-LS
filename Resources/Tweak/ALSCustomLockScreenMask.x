#import "ALSCustomLockScreenMask.h"

#import "ALSTextLayer.h"

@interface ALSCustomLockScreenMask()

@property (nonatomic) CGFloat buttonRadius;
@property (nonatomic) CGFloat buttonPadding;
@property (nonatomic, strong) CAShapeLayer *circleMaskLayer;
@property (nonatomic, strong) CAShapeLayer *internalLayer;
@property (nonatomic) CGFloat largeCircleInternalPadding;
@property (nonatomic) CGFloat largeCircleMaxRadius;
@property (nonatomic) CGFloat largeCircleMinRadius;
@property (nonatomic) CGFloat middleButtonVisiblePercentage;
@property (nonatomic) CGFloat scrollPercentage;
@property (nonatomic, strong) ALSTextLayer *titleLayer;

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
        
        _circleMaskLayer = [[CAShapeLayer alloc] init];
        _internalLayer = [[CAShapeLayer alloc] init];
        _titleLayer = [[ALSTextLayer alloc] init];
        [_internalLayer setMask:_circleMaskLayer];
        
        [self addSublayer:self.internalLayer];
        [self.internalLayer addSublayer:self.titleLayer];
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
    
    [self.circleMaskLayer setFrame:self.frame];
    [self.internalLayer setFrame:self.frame];
    
    self.largeCircleMaxRadius = ceilf(sqrt(self.bounds.size.width*self.bounds.size.width+self.bounds.size.height*self.bounds.size.height)/2);
}

/*
 Caled via our display link/
 Check if we have to do any updating, and then do it!
 */
- (void)updateMaskWithLargeRadius:(CGFloat)largeRadius smallRadius:(CGFloat)smallRadius axesButtonsRadii:(CGFloat)axesButtonsRadii diagonalButtonsRadii:(CGFloat)diagonalButtonsRadii zeroButtonRadius:(CGFloat)zeroButtonRadius {
    UIBezierPath *mask = [UIBezierPath bezierPath];
    
    //this is our layer that masks the large outside circle
    [self.circleMaskLayer setPath:[[[self class] pathForCircleWithRadius:largeRadius center:CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2)] CGPath]];
    
    //add entire bounds to mask
    [mask appendPath:[UIBezierPath bezierPathWithRect:self.bounds]];
    
    //remove area of title
    [mask appendPath:[UIBezierPath bezierPathWithRect:CGRectInset(self.titleLayer.frame, 2, 2)]];
    
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
    
    [self.titleLayer setPosition:CGPointMake(self.bounds.size.width/2, (self.bounds.size.height/2-buttonOffset-self.buttonRadius)/2)];
    
    [self.internalLayer setFillColor:[[UIColor blackColor] CGColor]];
    [self.internalLayer setPath:[mask CGPath]];
    [self.internalLayer setFillRule:kCAFillRuleEvenOdd];
}

@end
