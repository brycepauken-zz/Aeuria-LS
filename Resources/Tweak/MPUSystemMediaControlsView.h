#import <UIKit/UIKit.h>

@interface MPUSystemMediaControlsView : UIView

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;

@end
