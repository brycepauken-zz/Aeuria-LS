//
//  ALSCustomLockScreen.m
//  aeurials
//
//  Created by Bryce Pauken on 1/20/15.
//  Copyright (c) 2015 kingfish. All rights reserved.
//

#import "ALSCustomLockScreen.h"

#import "ALSCustomLockScreenMask.h"
#import "SBWallpaperImage.h"

@interface ALSCustomLockScreen()

@property (nonatomic, strong) UIView *overlay;
@property (nonatomic, strong) ALSCustomLockScreenMask *overlayMask;
@property (nonatomic, strong) UIImageView *wallpaperView;

@end

@implementation ALSCustomLockScreen

/*
 Our init method simply sets up our instance variables.
 */
- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        //the mask is responsible for creating open areas in the colored portion of the lock screen.
        _overlayMask = [[ALSCustomLockScreenMask alloc] initWithFrame:self.bounds];
        
        //the overlay is that colored portion of the lock screen.
        _overlay = [[UIView alloc] initWithFrame:self.bounds];
        [_overlay setBackgroundColor:[UIColor whiteColor]];
        [_overlay.layer setMask:_overlayMask];
        
        //the wallpaper view is a simple imageview containing the user's selected lockscreen wallpaper.
        _wallpaperView = [[UIImageView alloc] initWithFrame:self.bounds];
        [_wallpaperView setImage:[[%c(SBWallpaperImage) alloc] initWithVariant:0]];
        
        [self setUserInteractionEnabled:NO];
        [self addSubview:_wallpaperView];
        [self addSubview:_overlay];
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
    [self.overlayMask updateScrollPercentage:percentage];
}

@end
