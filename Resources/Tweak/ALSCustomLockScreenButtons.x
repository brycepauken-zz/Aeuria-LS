#import "ALSCustomLockScreenButtons.h"

#import "ALSPreferencesManager.h"

@interface ALSCustomLockScreenButtons()

//preference properties
@property (nonatomic) int buttonDistanceFromEdge;
@property (nonatomic) int buttonRadius;
@property (nonatomic) int buttonPadding;
@property (nonatomic) float clockInvisibleAt;

@end

@implementation ALSCustomLockScreenButtons

/*
 The init method — simply save our clock's type and radius.
 */
- (instancetype)initWithPreferencesManager:(ALSPreferencesManager *)preferencesManager {
    self = [super initWithPreferencesManager:preferencesManager];
    if(self) {
        _buttonDistanceFromEdge = 20;
        _buttonRadius = 44;
        _buttonPadding = 10;
        _clockInvisibleAt = [[preferencesManager preferenceForKey:@"clockInvisibleAt"] floatValue];
    }
    return self;
}

- (UIBezierPath *)buttonsPathForRadius:(CGFloat)radius middleButtonStartingRadius:(CGFloat)middleButtonStartingRadius {
    UIBezierPath *returnPath = [UIBezierPath bezierPath];
    
    //holds sqrt computations
    static NSMutableDictionary *distances;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        distances = [[NSMutableDictionary alloc] init];
    });
    
    //buttons in order: 1-9, bottom-left, 0, bottom-right
    for(int i=0;i<12;i++) {
        //bottom-left/right buttons functionality still coming
        if(i==9 || i==11) {
            continue;
        }
        
        CGFloat xOffset = (i%3-1)*(self.buttonRadius*2+self.buttonPadding);
        CGFloat yOffset = (i/3-1)*(self.buttonRadius*2+self.buttonPadding);
        CGFloat distSquared = xOffset*xOffset + yOffset*yOffset;
        
        if(i==4) {
            xOffset = 0;
            yOffset = 0;
            CGFloat fakeOffset = self.buttonRadius*2+self.buttonPadding;
            distSquared = fakeOffset*fakeOffset + fakeOffset*fakeOffset;
        }
        else {
            xOffset = (i%3-1)*(self.buttonRadius*2+self.buttonPadding);
            yOffset = (i/3-1)*(self.buttonRadius*2+self.buttonPadding);
            distSquared = xOffset*xOffset + yOffset*yOffset;
        }
        
        NSNumber *distSquaredNumber = @(distSquared);
        NSNumber *distNumber = [distances objectForKey:distSquaredNumber];
        if(!distNumber) {
            distNumber = @(sqrt(distSquared));
            [distances setObject:distNumber forKey:distSquaredNumber];
        }
        CGFloat buttonRadius = MAX(0,MIN(self.buttonRadius,radius-self.buttonDistanceFromEdge-[distNumber floatValue]-self.buttonRadius));
        [returnPath appendPath:[[self class] pathForCircleWithRadius:buttonRadius center:CGPointMake(xOffset, yOffset)]];
    }
    
    return returnPath;
}

+ (UIBezierPath *)pathForCircleWithRadius:(CGFloat)radius center:(CGPoint)center {
    return [UIBezierPath bezierPathWithRoundedRect:CGRectMake(center.x-radius, center.y-radius, radius*2, radius*2) byRoundingCorners:UIRectCornerAllCorners cornerRadii:CGSizeMake(radius, radius)];
}

@end
