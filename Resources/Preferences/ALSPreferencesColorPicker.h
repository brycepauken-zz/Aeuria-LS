@interface ALSPreferencesColorPicker : UIView <UIScrollViewDelegate, UITextFieldDelegate>

- (instancetype)initWithParentView:(UIView *)parentView;
- (void)dismiss;
- (void)setCompletionBlock:(void (^)(NSString *))completionBlock;
- (void)setHexColor:(NSString *)hexColor;
- (void)show;

@end