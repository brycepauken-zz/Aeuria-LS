#import "SBLockScreenScrollView.h"

#import "ALSCustomLockScreenContainer.h"

/*
 The SBLockScreenScrollView class represents the main scrollview
 present on the lock screen, and we hook it as a quick and easy way
 to hide a number of compontents that we don't want visible.
 */

@interface SBLockScreenScrollView()

- (id)findNotificationViewInView:(UIView *)view maxDepth:(int)depth;

@end

%hook SBLockScreenScrollView

- (void)layoutSubviews {
    [self setScrollEnabled:NO];
    for(UIView *view in self.subviews) {
        //not the right (in both ways) view; hide it
        if(view.frame.origin.x <= 0) {
            [view setHidden:YES];
        }
        else {
            UIView *notificationView = [self findNotificationViewInView:self maxDepth:5];
            
            //remove tap/press gesture recognizers
            UIView *currentView = view;
            while(currentView) {
                for(UIGestureRecognizer *gestureRecognizer in currentView.gestureRecognizers) {
                    [gestureRecognizer setEnabled:!([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]] || [gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]])];
                }
                currentView = currentView.superview;
            }
            
            //hide all subviews that aren't our custom lock screen container
            for(UIView *subview in view.subviews) {
                if([subview isKindOfClass:[ALSCustomLockScreenContainer class]]) {
                    if(notificationView) {
                        [notificationView removeFromSuperview];
                        [((ALSCustomLockScreenContainer *)subview) addNotificationView:notificationView];
                    }
                }
                else {
                    [subview setHidden:YES];
                }
            }
        }
    }
}

%new
- (id)findNotificationViewInView:(UIView *)view maxDepth:(int)depth {
    if (depth == 0 || [view isKindOfClass:[ALSCustomLockScreenContainer class]]) {
        return nil;
    }
    
    NSInteger count = depth;
    while(count > 0) {
        for(UIView *subview in view.subviews) {
            if ([subview isKindOfClass:[%c(SBLockScreenNotificationTableView) class]]) {
                return subview;
            }
        }
        
        count--;
        for(UIView *subview in view.subviews) {
            UIView *notificationView = [self findNotificationViewInView:subview maxDepth:count];
            if(notificationView) {
                return notificationView;
            }
        }
    }
    
    return nil;
}



%end
