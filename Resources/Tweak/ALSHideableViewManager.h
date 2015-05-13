#import <UIKit/UIKit.h>

@interface ALSHideableViewManager : NSObject

+ (void)addView:(UIView *)view;
+ (NSUInteger)indexOfView:(UIView *)view;
+ (void)setShouldHide:(BOOL)shouldHide;
+ (void)setViewHidden:(BOOL)hidden forView:(UIView *)view;
+ (BOOL)shouldHide;
+ (BOOL)viewHidden:(UIView *)view;

@end
