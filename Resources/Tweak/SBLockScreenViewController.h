#import <UIKit/UIKit.h>

/*
 The SBLockScreenViewController manages the lock screen.
 Hooking it allows us to respond to events from the lock screen.
 */

@interface SBLockScreenView : UIView

- (id)passcodeView;

@end

@interface SBLockScreenViewController : NSObject

- (id)lockScreenScrollView;
- (id)lockScreenView;
- (long long)statusBarStyle;
- (void)viewWillAppear:(BOOL)view;

@end
