#import "SBLockScreenNotificationListView.h"

%hook SBLockScreenNotificationListView

-(void)_updateTotalContentHeight {
    %orig;
    
    //find the custom lock screen container view and tell it that something changed
    UIView *currentView = [self valueForKey:@"_tableView"];
    for(int i=0; i<5 && currentView; i++) {
        if([currentView respondsToSelector:@selector(notificationViewChanged)]) {
            [currentView performSelector:@selector(notificationViewChanged)];
            break;
        }
        currentView = currentView.superview;
    }
}

%end
