//
//  ALSColorGradient.h
//  Test2
//
//  Created by Bryce Pauken on 4/26/15.
//  Copyright (c) 2015 Bryce Pauken. All rights reserved.
//

@interface ALSPreferencesColorGradient : UIView

- (UIColor *)colorAtPoint:(CGPoint)point;
+ (UIImage *)imageForHuePickerWithSize:(CGSize)size;
- (void)setAccessibleSize:(int)accessibleSize;
- (void)setHue:(float)hue;

@end
