//
//  ALSColorPanGestureRecognizer.m
//  Test2
//
//  Created by Bryce Pauken on 4/26/15.
//  Copyright (c) 2015 Bryce Pauken. All rights reserved.
//

#import "ALSColorPanGestureRecognizer.h"

@interface UIGestureRecognizer()

@property(nonatomic,readwrite) UIGestureRecognizerState state;

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;

@end

@implementation ALSColorPanGestureRecognizer

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesBegan:touches withEvent:event];
    self.state = UIGestureRecognizerStateBegan;
}

@end
