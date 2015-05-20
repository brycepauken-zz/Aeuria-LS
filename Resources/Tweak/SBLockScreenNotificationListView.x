#import "SBLockScreenNotificationListView.h"

@interface SBLockScreenNotificationListView()

- (id)customProperties;
- (id)lockScreenViewController;

@end

%hook SBLockScreenNotificationListView

- (void)_updateTotalContentHeight {
    %orig;
    
    //find superviews and tell it that something changed (if they want to know)
    UIView *currentView = [self valueForKey:@"_tableView"];
    while(currentView) {
        if([currentView respondsToSelector:@selector(notificationViewChanged)]) {
            [currentView performSelector:@selector(notificationViewChanged)];
        }
        currentView = currentView.superview;
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

- (void)layoutSubviews {
    %orig;
    
    UIView *firstSubview = [[self subviews] objectAtIndex:0];
    CGRect firstSubviewFrame = firstSubview.frame;
    
    if(![[self customProperties] objectForKey:@"originalYOffset"]) {
        [[self customProperties] setObject:@(firstSubviewFrame.origin.y) forKey:@"originalYOffset"];
    }
    if(![[self customProperties] objectForKey:@"originalHeight"]) {
        [[self customProperties] setObject:@(firstSubviewFrame.size.height) forKey:@"originalHeight"];
    }
    
    CGFloat halfHeight = [[[self customProperties] objectForKey:@"originalHeight"] doubleValue]/2;
    firstSubviewFrame.origin.y = 0;
    firstSubviewFrame.size.height = halfHeight;
    [firstSubview setFrame:firstSubviewFrame];
    for(UIView *secondSubview in firstSubview.subviews) {
        if([secondSubview isKindOfClass:[UITableView class]]) {
            CGRect secondSubviewFrame = firstSubview.frame;
            secondSubviewFrame.size.height = halfHeight;
            [secondSubview setFrame:secondSubviewFrame];
            break;
        }
    }
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

%end
