#import "ALSCustomLockScreenMask.h"

@interface ALSCustomLockScreenMask()

@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic) CGFloat lastKnownScrollPercentage;
@property (nonatomic) CGFloat newScrollPercentage;

@property (nonatomic) CGFloat buttonSize;
@property (nonatomic) CGFloat largeCircleInternalPadding;
@property (nonatomic) CGFloat largeCircleMaxRadius;
@property (nonatomic) CGFloat largeCircleMinRadius;

@end


@implementation ALSCustomLockScreenMask

/*
 Our init method simply sets everything up.
 */
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super init];
    if(self) {
        [self setFrame:frame];
        
        _buttonSize = 90;
        _largeCircleInternalPadding = 20;
        _largeCircleMinRadius = 100;
        
        _lastKnownScrollPercentage = 0;
        _newScrollPercentage = 0;
        
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateMask)];
        [_displayLink setFrameInterval:1];
        [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    }
    return self;
}

+ (UIBezierPath *)pathForCircleWithRadius:(CGFloat)radius center:(CGPoint)center {
    return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(center.x-radius, center.y-radius, radius*2, radius*2) byRoundingCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(radius, radius)];
}

/*
 Reposition everytying as needed.
 */
- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    
    self.largeCircleMaxRadius = ceilf(sqrt(self.bounds.size.width*self.bounds.size.width+self.bounds.size.height*self.bounds.size.height)/2);
    
    [self updateMask];
}

/*
 Caled via our display link/
 Check if we have to do any updating, and then do it!
 */
- (void)updateMask {
    if(true || self.lastKnownScrollPercentage != self.newScrollPercentage) {
        self.lastKnownScrollPercentage = self.newScrollPercentage;
        
        CGFloat largeCircleRadius = self.largeCircleMinRadius+(self.largeCircleMaxRadius-self.largeCircleMinRadius)*self.lastKnownScrollPercentage;
        UIBezierPath *largeCircleMask = [[self class] pathForCircleWithRadius:largeCircleRadius center:CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2)];
        
        //UIBezierPath *transparentPieces = [UIBezierPath bezierPath];
        [largeCircleMask appendPath:[[self class] pathForCircleWithRadius:largeCircleRadius-self.largeCircleInternalPadding/2 center:CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2)]];
        
         
        [self setFillColor:[[UIColor blackColor] CGColor]];
        [self setPath:[largeCircleMask CGPath]];
        [self setFillRule:kCAFillRuleEvenOdd];
    }
}

- (void)updateScrollPercentage:(CGFloat)percentage {
    self.newScrollPercentage = percentage;
}

@end
