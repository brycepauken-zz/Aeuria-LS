#import "SBLockScreenScrollView.h"

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
- (id)lockScreenViewController;

@end

%hook SBLockScreenScrollView

%new
- (void)checkShouldShowCustomLockScreen {
    UIView *mediaControlsView = [[self.customProperties objectForKey:@"mediaControlsView"] object];
    if(!mediaControlsView) {
        mediaControlsView = [self findViewOfClass:[%c(MPUSystemMediaControlsView) class] inView:self maxDepth:9];
        [self.customProperties setObject:[ALSProxyObject proxyOfType:ALSProxyObjectWeakReference forObject:mediaControlsView] forKey:@"mediaControlsView"];
    }
    
    NSNumber *shouldShowCustomLockScreenExistingNum = [[self.customProperties objectForKey:@"shouldShowCustomLockScreen"] object];
    BOOL shouldShowCustomLockScreenExisting = [shouldShowCustomLockScreenExistingNum boolValue];
    
    NSNumber *notificationViewFilledNum = [[self.customProperties objectForKey:@"notificationViewFilled"] object];
    BOOL notificationViewFilled = [notificationViewFilledNum boolValue];
    
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

- (void)layoutSubviews {
    %orig;
    
    if(![[self.customProperties objectForKey:@"notificationView"] object]) {
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
    UIView *notificationView = [[self.customProperties objectForKey:@"notificationView"] object];
    if(!notificationView) {
        notificationView = [self findViewOfClass:[%c(SBLockScreenNotificationTableView) class] inView:self maxDepth:6];
        [self.customProperties setObject:[ALSProxyObject proxyOfType:ALSProxyObjectWeakReference forObject:notificationView] forKey:@"notificationView"];
    }
    
    if(notificationView) {
        [self.customProperties setObject:[ALSProxyObject proxyOfType:ALSProxyObjectStrongReference forObject:@([((UITableView *)notificationView).dataSource tableView:(UITableView *)notificationView numberOfRowsInSection:0]>0)] forKey:@"notificationViewFilled"];
        [self checkShouldShowCustomLockScreen];
    }
}

%end
