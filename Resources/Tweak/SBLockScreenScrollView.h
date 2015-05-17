#import <UIKit/UIKit.h>

@interface SBLockScreenScrollView : UIScrollView

- (id)customScrollView;
- (void)notificationViewChanged;
- (void)setCustomScrollView:(id)customScrollView;
- (void)setShouldHideSubviews:(BOOL)shouldHide;
- (BOOL)shouldHideSubviews;

@end
