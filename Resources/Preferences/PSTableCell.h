@class PSSpecifier;

@interface PSTableCell : UIView

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier;
- (CGFloat)preferredHeightForWidth:(CGFloat)arg1;

@end