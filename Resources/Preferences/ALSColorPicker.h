//
//  ALSColorPicker.h
//  Test2
//
//  Created by Bryce Pauken on 4/26/15.
//  Copyright (c) 2015 Bryce Pauken. All rights reserved.
//

@interface ALSColorPicker : UIView <UIScrollViewDelegate, UITextFieldDelegate>

- (instancetype)initWithParentView:(UIView *)parentView;
+ (ALSColorPicker *)colorPickerWithParentView:(UIView *)parentView;
- (void)dismiss;
- (void)setCompletionBlock:(void (^)(NSString *))completionBlock;
- (void)setHexColor:(NSString *)hexColor;
- (void)show;

@end
