typedef NS_ENUM(NSInteger, HOICellStatus) {
    HOICellStatusNone,
    HOICellStatusSnowflakeVisible,
    HOICellStatusCheckmarkVisible
};

@interface ALSPThemeTableCell : UITableViewCell

- (void)animateCellStatusChange:(HOICellStatus)newStatus;
- (void)setCheckmarkHidden:(BOOL)hidden;
- (void)setRespringLabelHidden:(BOOL)hidden;
- (void)setSnowflakeHidden:(BOOL)hidden;
- (void)setTopDividerHidden:(BOOL)hidden;
- (void)setText:(NSString *)text;

@end
