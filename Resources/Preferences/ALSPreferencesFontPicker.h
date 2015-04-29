@interface ALSPreferencesFontPicker : UIView <UITableViewDataSource, UITableViewDelegate>

- (instancetype)initWithParentView:(UIView *)parentView;
- (void)dismiss;
- (void)setCompletionBlock:(void (^)(NSString *))completionBlock;
- (void)setFontName:(NSString *)fontName;
- (void)show;

@end