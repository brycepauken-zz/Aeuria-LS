#import "ALSCustomLockScreen.h"

#import "ALSClockView.h"
#import "ALSCustomLockScreenMask.h"
#import "ALSKeypadButton.h"
#import "SBWallpaperImage.h"

@interface ALSCustomLockScreen()

@property (nonatomic, strong) ALSClockView *clockView;
@property (nonatomic, strong) UIColor *color;
@property (nonatomic, strong) NSMutableArray *keypadButtons;
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
        [_overlay setBackgroundColor:_color];
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
        
        _keypadButtons = [NSMutableArray array];
        for(int i=0;i<10;i++) {
            ALSKeypadButton *keypadButton = [[ALSKeypadButton alloc] initWithRadius:[_overlayMask buttonRadius] number:i color:_color];
            [_keypadButtons addObject:keypadButton];
            [keypadButton setAlpha:0];
            [keypadButton setTransform:CGAffineTransformScale(CGAffineTransformIdentity, 0, 0)];
            [self addSubview:keypadButton];
        }
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
 Reposition the keypad buttons.
 */
- (void)layoutSubviews {
    [super layoutSubviews];
    
    CGFloat buttonOffset = [self.overlayMask buttonRadius]*2+[self.overlayMask buttonPadding];
    for(int i=0;i<10;i++) {
        if(i==9) {
            [[self.keypadButtons objectAtIndex:0] setCenter:CGPointMake(self.bounds.size.width/2, self.bounds.size.height/2+[self.overlayMask buttonRadius]*4+[self.overlayMask buttonPadding]*2)];
        }
        else {
            [[self.keypadButtons objectAtIndex:i+1] setCenter:CGPointMake(self.bounds.size.width/2+(i%3==0?-buttonOffset:(i%3==2?buttonOffset:0)), self.bounds.size.height/2+(i<3?-buttonOffset:(i>=6?buttonOffset:0)))];
        }
    }
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
        CGFloat zeroButtonRadius = MAX(0,MIN([self.overlayMask buttonRadius],largeRadius-[self.overlayMask buttonPadding]-([self.overlayMask buttonRadius]*4+[self.overlayMask buttonPadding]*2)));
        
        //update mask
        [self.overlayMask setScrollPercentage:self.lastKnownScrollPercentage];
        [self.overlayMask updateMaskWithLargeRadius:largeRadius smallRadius:(smallRadius-2>=0?smallRadius-2:MIN(-(smallRadius-2),zeroButtonRadius)) axesButtonsRadii:axesButtonsRadii diagonalButtonsRadii:diagonalButtonsRadii zeroButtonRadius:zeroButtonRadius];
        
        //update clock view
        CGFloat clockViewScale = MAX(0,MIN(1,smallRadius/[self.overlayMask largeCircleMinRadius]));
        [self.clockView setTransform:CGAffineTransformScale(CGAffineTransformIdentity, clockViewScale, clockViewScale)];
        
        //update keypad buttons
        CGFloat axesButtonsScale = axesButtonsRadii/[self.overlayMask buttonRadius];
        CGFloat diagonalButtonsScale = diagonalButtonsRadii/[self.overlayMask buttonRadius];
        CGFloat zeroButtonScale = zeroButtonRadius/[self.overlayMask buttonRadius];
        for(int i=0;i<10;i++) {
            CGFloat scale = (i==0||i==5?zeroButtonScale:(i%2==0?axesButtonsScale:diagonalButtonsScale));
            [[self.keypadButtons objectAtIndex:i] setAlpha:scale];
            [(UIView *)[self.keypadButtons objectAtIndex:i] setTransform:CGAffineTransformScale(CGAffineTransformIdentity, scale, scale)];
        }
    }
}

@end
