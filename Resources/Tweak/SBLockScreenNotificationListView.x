#import "SBLockScreenNotificationListView.h"

#import "SBLockScreenViewController.h"

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

%end
