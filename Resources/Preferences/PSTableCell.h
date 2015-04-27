@class PSSpecifier;

@interface PSTableCell : UIView

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier;
- (CGFloat)preferredHeightForWidth:(CGFloat)arg1;
- (void)setValue:(id)value;

@end