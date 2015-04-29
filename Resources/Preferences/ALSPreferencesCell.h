#import "PSTableCell.h"

@interface ALSPreferencesCell : PSTableCell

- (void)handlePress:(UILongPressGestureRecognizer*)sender;
- (id)internalValue;
- (UITableView *)parentTableView;
- (void)savePreferenceValue:(id)value;

@end