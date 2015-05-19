#import <UIKit/UIKit.h>

@class ALSCustomLockScreen;

@interface ALSCustomLockScreenContainer : UIView <UIScrollViewDelegate>

@property (nonatomic, weak) UIView *keyboardView;
@property (nonatomic, weak) UIView *mediaControlsView;
@property (nonatomic, weak) UIView *notificationView;
@property (nonatomic, weak) UITextField *passcodeTextField;

- (ALSCustomLockScreen *)customLockScreen;
- (void)notificationViewChanged;
- (void)resetView;
- (UIScrollView *)scrollView;
- (void)setPasscodeEntered:(void (^)(NSString *passcode))passcodeEntered;

@end
