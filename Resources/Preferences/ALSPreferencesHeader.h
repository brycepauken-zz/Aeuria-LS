#import "PSTableCell.h"

@interface ALSPreferencesHeader : PSTableCell

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;

@end