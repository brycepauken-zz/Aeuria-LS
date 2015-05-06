#import "SBLockScreenScrollView.h"

#import "ALSCustomLockScreenContainer.h"

/*
 The SBLockScreenScrollView class represents the main scrollview
 present on the lock screen, and we hook it as a quick and easy way
 to hide a number of compontents that we don't want visible.
 */

%hook SBLockScreenScrollView

- (void)layoutSubviews {
    /*for(UIGestureRecognizer *gestureRecognizer in self.gestureRecognizers) {
        [gestureRecognizer setEnabled:NO];
    }*/
    [self setScrollEnabled:NO];
    for(UIView *view in self.subviews) {
        //not the right (in both ways) view; hide it
        if(view.frame.origin.x <= 0) {
            [view setHidden:YES];
        }
        else {
            UIView *currentView = view;
            while(currentView) {
                for(UIGestureRecognizer *gestureRecognizer in currentView.gestureRecognizers) {
                    [gestureRecognizer setEnabled:!([gestureRecognizer isKindOfClass:[UITapGestureRecognizer class]] || [gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]])];
                }
                currentView = currentView.superview;
            }
            
            //hide all subviews that aren't our custom lock screen container
            for(UIView *subview in view.subviews) {
                [subview setHidden:![subview isKindOfClass:[ALSCustomLockScreenContainer class]]];
            }
        }
    }
}

%end
