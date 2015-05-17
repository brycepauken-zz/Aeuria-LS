#import "SBLockScreenScrollView.h"

#import "ALSCustomLockScreen.h"
#import "ALSCustomLockScreenContainer.h"
#import "ALSProxyObject.h"
#import "SBLockScreenViewController.h"

/*
 The SBLockScreenScrollView class represents the main scrollview
 present on the lock screen, and we hook it as a quick and easy way
 to hide a number of compontents that we don't want visible.
 */

@interface SBLockScreenScrollView()

@property (nonatomic, strong) NSMutableDictionary *customProperties;

- (void)checkShouldShowCustomLockScreen;
- (id)findViewOfClass:(Class)class inView:(UIView *)view maxDepth:(int)depth;
- (void)hideSubviewsIfNeeded;
- (id)lockScreenViewController;
- (void)searchSubviews;

@end

%hook SBLockScreenScrollView

%new
- (void)checkShouldShowCustomLockScreen {
    [self searchSubviews];
    
    NSNumber *shouldShowCustomLockScreenExistingNum = [[self.customProperties objectForKey:@"shouldShowCustomLockScreen"] object];
    BOOL shouldShowCustomLockScreenExisting = [shouldShowCustomLockScreenExistingNum boolValue];
    
    NSNumber *notificationViewFilledNum = [[self.customProperties objectForKey:@"notificationViewFilled"] object];
    BOOL notificationViewFilled = [notificationViewFilledNum boolValue];
    
    UIView *mediaControlsView = [[self.customProperties objectForKey:@"mediaControlsView"] object];
    BOOL shouldShowCustomLockScreen = !mediaControlsView && (notificationViewFilledNum && !notificationViewFilled);
    
    if(!shouldShowCustomLockScreenExistingNum || shouldShowCustomLockScreenExisting!=shouldShowCustomLockScreen) {
        [self.customProperties setObject:[ALSProxyObject proxyOfType:ALSProxyObjectStrongReference forObject:@(shouldShowCustomLockScreen)] forKey:@"shouldShowCustomLockScreen"];
        [[self lockScreenViewController] setCustomLockScreenHidden:!shouldShowCustomLockScreen];
    }
}

%new
- (id)customProperties {
    id customProperties;
    @synchronized(self) {
        customProperties = objc_getAssociatedObject(self, @selector(customProperties));
        if(!customProperties) {
            customProperties = [[NSMutableDictionary alloc] init];
            objc_setAssociatedObject(self, @selector(customProperties), customProperties, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
    return customProperties;
}

%new
- (id)findViewOfClass:(Class)class inView:(UIView *)view maxDepth:(int)depth {
    if (depth == 0 || [view isKindOfClass:[ALSCustomLockScreenContainer class]]) {
        return nil;
    }
    
    NSInteger count = depth;
    while(count > 0) {
        for(UIView *subview in view.subviews) {
            if ([subview isKindOfClass:class]) {
                return subview;
            }
        }
        
        count--;
        for(UIView *subview in view.subviews) {
            UIView *notificationView = [self findViewOfClass:class inView:subview maxDepth:count];
            if(notificationView) {
                return notificationView;
            }
        }
    }
    
    return nil;
}

/*
 Updates all subviews other than SBPasscodeKeyboard (a subview of
 SBUIPasscodeLockViewWithKeyboard) to be hidden or shown as needed
 */
%new
- (void)hideSubviewsIfNeeded {
    BOOL shouldHideSubviews = [self shouldHideSubviews];
    for(UIView *subview in self.subviews) {
        if([subview isKindOfClass:[%c(SBUIPasscodeLockViewWithKeyboard) class]]) {
            for(UIView *passcodeViewSubview in subview.subviews) {
                if([passcodeViewSubview isKindOfClass:[UILabel class]]) {
                    //we also remove the 'enter passcode' label, since it's tricky to keep hidden
                    [passcodeViewSubview removeFromSuperview];
                }
                [passcodeViewSubview setHidden:(shouldHideSubviews && ![passcodeViewSubview isKindOfClass:[%c(SBPasscodeKeyboard) class]])];
            }
        }
        else {
            [subview setHidden:shouldHideSubviews];
        }
    }
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *customLockScreen = [[[self lockScreenViewController] customLockScreenContainer] customLockScreen];
    UIView *tappedButton = [customLockScreen hitTest:point withEvent:event];
    if(tappedButton) {
        return customLockScreen;
    }
    return %orig;
}

- (void)layoutSubviews {
    %orig;
    
    //layoutSubviews is called on scrolling; ignore the other checks if this is the case here
    NSValue *lastKnownOffsetVal = [self.customProperties objectForKey:@"lastKnownOffset"];
    if(lastKnownOffsetVal) {
        CGPoint lastKnownOffset = [lastKnownOffsetVal CGPointValue];
        if(!CGPointEqualToPoint(lastKnownOffset, self.contentOffset)) {
            [self.customProperties setObject:[NSValue valueWithCGPoint:self.contentOffset] forKey:@"lastKnownOffset"];
            return;
        }
    }
    else {
        [self.customProperties setObject:[NSValue valueWithCGPoint:self.contentOffset] forKey:@"lastKnownOffset"];
    }
    
    BOOL notificationViewNotFound = ![[self.customProperties objectForKey:@"notificationView"] object];
    [self searchSubviews];
    
    //tell the lock screen view controller if we've found the notification or media controls views
    if([self lockScreenViewController]) {
        UIView *mediaControlsView = [[self.customProperties objectForKey:@"mediaControlsView"] object];
        if(mediaControlsView) {
            [[[self lockScreenViewController] customLockScreenContainer] addMediaControlsView:mediaControlsView fromSuperView:mediaControlsView.superview];
        }
        UIView *notificationView = [[self.customProperties objectForKey:@"notificationView"] object];
        if(notificationView) {
            [[[self lockScreenViewController] customLockScreenContainer] addNotificationView:notificationView fromSuperView:notificationView.superview];
        }
    }
    
    [self hideSubviewsIfNeeded];
    
    if(notificationViewNotFound && [[self.customProperties objectForKey:@"notificationView"] object]) {
        [self notificationViewChanged];
    }
    [self checkShouldShowCustomLockScreen];
}

%new
- (id)lockScreenViewController {
    __weak static SBLockScreenViewController *lockScreenViewController;
    if(!lockScreenViewController) {
        UIView *currentView = self;
        while(currentView.superview && ![currentView isKindOfClass:[%c(SBLockScreenView) class]]) {
            currentView = currentView.superview;
        }
        if([currentView.nextResponder isKindOfClass:[%c(SBLockScreenViewController) class]]) {
            lockScreenViewController = (SBLockScreenViewController *)currentView.nextResponder;
        }
    }
    return lockScreenViewController;
}

%new
- (void)notificationViewChanged {
    [self searchSubviews];
    
    UIView *notificationView = [[self.customProperties objectForKey:@"notificationView"] object];
    if(notificationView) {
        [self.customProperties setObject:[ALSProxyObject proxyOfType:ALSProxyObjectStrongReference forObject:@([((UITableView *)notificationView).dataSource tableView:(UITableView *)notificationView numberOfRowsInSection:0]>0)] forKey:@"notificationViewFilled"];
        [self checkShouldShowCustomLockScreen];
    }
}

%new
- (void)searchSubviews {
    if(![[self.customProperties objectForKey:@"mediaControlsView"] object]) {
        [self.customProperties setObject:[ALSProxyObject proxyOfType:ALSProxyObjectWeakReference forObject:[self findViewOfClass:[%c(MPUSystemMediaControlsView) class] inView:self maxDepth:9]] forKey:@"mediaControlsView"];
    }
    if(![[self.customProperties objectForKey:@"notificationView"] object]) {
        [self.customProperties setObject:[ALSProxyObject proxyOfType:ALSProxyObjectWeakReference forObject:[self findViewOfClass:[%c(SBLockScreenNotificationTableView) class] inView:self maxDepth:6]] forKey:@"notificationView"];
    }
}

- (void)setContentOffset:(CGPoint)offset {
    %orig;
    [[[[[self lockScreenViewController] customLockScreenContainer] customLockScreen] layer] removeAnimationForKey:@"position"];
    [[[[self lockScreenViewController] customLockScreenContainer] scrollView] setContentOffset:offset];
};

%new
- (void)setShouldHideSubviews:(BOOL)shouldHide {
    [self.customProperties setObject:@(shouldHide) forKey:@"shouldHideSubviews"];
    [self hideSubviewsIfNeeded];
}

%new
- (BOOL)shouldHideSubviews {
    NSNumber *shouldHideSubviewsNum = [self.customProperties objectForKey:@"shouldHideSubviews"];
    if(!shouldHideSubviewsNum) {
        [self setShouldHideSubviews:YES];
        return YES;
    }
    return [shouldHideSubviewsNum boolValue];
}

%end
