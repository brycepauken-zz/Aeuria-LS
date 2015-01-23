#import "ALSCustomLockScreen.h"

#import "ALSClockView.h"
#import "ALSCustomLockScreenMask.h"
#import "SBWallpaperImage.h"

@interface ALSCustomLockScreen()

@property (nonatomic, strong) ALSClockView *clockView;
@property (nonatomic, strong) UIColor *color;
@property (nonatomic, strong) UIView *overlay;
@property (nonatomic, strong) ALSCustomLockScreenMask *overlayMask;
@property (nonatomic, strong) UIImageView *wallpaperView;

//display link properties
@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic) CGFloat lastKnownScrollPercentage;
@property (nonatomic) CGFloat newScrollPercentage;

@end

@implementation ALSCustomLockScreen

/*
 Our init method simply sets up our instance variables.
 */
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        _color = [UIColor whiteColor];
        
        //the wallpaper view is a simple imageview containing the user's selected lockscreen wallpaper.
        _wallpaperView = [[UIImageView alloc] initWithFrame:self.bounds];
        [_wallpaperView setImage:[[%c(SBWallpaperImage) alloc] initWithVariant:0]];
        
        //the mask is responsible for creating open areas in the colored portion of the lock screen.
        _overlayMask = [[ALSCustomLockScreenMask alloc] initWithFrame:self.bounds];
        
        //the overlay is that colored portion of the lock screen.
        _overlay = [[UIView alloc] initWithFrame:self.bounds];
        [_overlay setBackgroundColor:[UIColor whiteColor]];
        [_overlay.layer setMask:_overlayMask];
        
        //the clock view is the circular view that displays the time on the lock screen.
        _clockView = [[ALSClockView alloc] initWithRadius:[_overlayMask largeCircleMinRadius] internalPadding:[_overlayMask largeCircleInternalPadding] color:_color];
        [_clockView setCenter:self.center];
        
        _lastKnownScrollPercentage = MAXFLOAT;
        _newScrollPercentage = 0;
        
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateViews)];
        [_displayLink setFrameInterval:1];
        [_displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        
        [self setUserInteractionEnabled:NO];
        [self addSubview:_wallpaperView];
        [self addSubview:_overlay];
        [self addSubview:_clockView];
    }
    return self;
}

/*
 Hide our lock screen with an animation.
 */
- (void)animateOut {
    /*[UIView animateWithDuration:0.0 delay:0.0 options:0 animations:^{
        [self.window setAlpha:0];
    } completion:nil];*/
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.window setHidden:YES];
    });
}

/*
 Reset the view after animation.
 */
- (void)resetView {
    
}

/*
 Forward the new scroll percentage to our mask
 */
- (void)updateScrollPercentage:(CGFloat)percentage {
    self.newScrollPercentage = percentage;
}

- (void)updateViews {
    if(self.lastKnownScrollPercentage != self.newScrollPercentage) {
        self.lastKnownScrollPercentage = MAX(0,self.newScrollPercentage);
        
        CGFloat largeRadius = [self.overlayMask largeCircleMinRadius]+([self.overlayMask largeCircleMaxRadius]-[self.overlayMask largeCircleMinRadius])*self.lastKnownScrollPercentage;
        CGFloat smallRadius = [self.overlayMask largeCircleMinRadius]-([self.overlayMask largeCircleMinRadius]+[self.overlayMask buttonRadius])*MAX(0,MIN(1,self.lastKnownScrollPercentage/[self.overlayMask middleButtonVisiblePercentage]));
        CGFloat buttonOffset = [self.overlayMask buttonRadius]*2+[self.overlayMask buttonPadding];
        CGFloat axesButtonsRadii = MAX(0,MIN([self.overlayMask buttonRadius],largeRadius-[self.overlayMask buttonPadding]-buttonOffset));
        CGFloat diagonalButtonsRadii = MAX(0,MIN([self.overlayMask buttonRadius],largeRadius-[self.overlayMask buttonPadding]-sqrt(buttonOffset*buttonOffset+buttonOffset*buttonOffset)));
        
        //update mask
        [self.overlayMask setScrollPercentage:self.lastKnownScrollPercentage];
        [self.overlayMask updateMaskWithLargeRadius:largeRadius smallRadius:MAX(0,fabs(smallRadius)-2) axesButtonsRadii:axesButtonsRadii diagonalButtonsRadii:diagonalButtonsRadii];
        
        //update clock view
        CGFloat clockViewScale = MAX(0,MIN(1,smallRadius/[self.overlayMask largeCircleMinRadius]));
        [self.clockView setTransform:CGAffineTransformScale(CGAffineTransformIdentity, clockViewScale, clockViewScale)];
    }
}

@end
