//
//  ALSCustomLockScreenMask.h
//  aeurials
//
//  Created by Bryce Pauken on 1/21/15.
//  Copyright (c) 2015 kingfish. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ALSCustomLockScreenMask : CAShapeLayer

- (instancetype)initWithFrame:(CGRect)frame;
- (void)updateScrollPercentage:(CGFloat)percentage;

@end
