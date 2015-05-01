#import "PSTableCell.h"

@interface ALSPreferencesCell : PSTableCell <UIGestureRecognizerDelegate>

- (void)handlePress:(UILongPressGestureRecognizer*)sender;
- (id)internalValue;
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
- (UITableView *)parentTableView;
- (void)savePreferenceValue:(id)value;

@end