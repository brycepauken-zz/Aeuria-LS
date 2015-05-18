#import "SBLockScreenNotificationListView.h"

@interface SBLockScreenNotificationListView()

- (id)knownNumberOfRowsNum;
- (void)setKnownNumberOfRowsNum:(id)knownNumberOfRowsNum;

@end

%hook SBLockScreenNotificationListView

%new
- (id)knownNumberOfRowsNum {
    return objc_getAssociatedObject(self, @selector(knownNumberOfRowsNum));
}

%new
- (void)setKnownNumberOfRowsNum:(id)knownNumberOfRowsNum {
    objc_setAssociatedObject(self, @selector(knownNumberOfRowsNum), knownNumberOfRowsNum, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (int)tableView:(id)view numberOfRowsInSection:(int)section {
    int numberOfRows = %orig;
    
    NSNumber *knownNumberOfRowsNum = [self knownNumberOfRowsNum];
    int knownNumberOfRows = -1;
    if(knownNumberOfRowsNum) {
        knownNumberOfRows = [knownNumberOfRowsNum intValue];
    }
    
    if(numberOfRows != knownNumberOfRows) {
        [self setKnownNumberOfRowsNum:@(numberOfRows)];
        
        //find superviews and tell it that something changed (if they want to know)
        UIView *currentView = [self valueForKey:@"_tableView"];
        while(currentView) {
            if([currentView respondsToSelector:@selector(notificationViewChanged)]) {
                [currentView performSelector:@selector(notificationViewChanged)];
            }
            currentView = currentView.superview;
        }
    }
    
    return numberOfRows;
}

%end
