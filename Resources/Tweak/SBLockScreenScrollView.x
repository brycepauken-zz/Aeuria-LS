#import "SBLockScreenScrollView.h"

#import "ALSCustomLockScreenContainer.h"

/*
 The SBLockScreenScrollView class represents the main scrollview
 present on the lock screen, and we hook it as a quick and easy way
 to hide a number of compontents that we don't want visible.
 */

@interface SBLockScreenScrollView()

@property (nonatomic, strong) UIScrollView *customScrollView;

- (id)findViewOfClass:(Class)class inView:(UIView *)view maxDepth:(int)depth;

@end

%hook SBLockScreenScrollView

%new
- (id)customScrollView {
    return objc_getAssociatedObject(self, @selector(customScrollView));
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
    [self setScrollEnabled:NO];
    for(UIView *view in self.subviews) {
        //not the right (in both ways) view; hide it
        if(view.frame.origin.x <= 0) {
            [view setHidden:YES];
        }
        else {
            UIView *notificationView = [self findViewOfClass:[%c(SBLockScreenNotificationTableView) class] inView:self maxDepth:5];
            UIView *mediaControlsView = [self findViewOfClass:[%c(MPUSystemMediaControlsView) class] inView:self maxDepth:8];
            
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
                    [self setCustomScrollView:[(ALSCustomLockScreenContainer *)subview scrollView]];
                    if(notificationView) {
                        [notificationView removeFromSuperview];
                        [((ALSCustomLockScreenContainer *)subview) addNotificationView:notificationView];
                    }
                    if(mediaControlsView) {
                        [mediaControlsView removeFromSuperview];
                        [((ALSCustomLockScreenContainer *)subview) addMediaControlsView:mediaControlsView];
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
- (void)setCustomScrollView:(id)customScrollView {
    objc_setAssociatedObject(self, @selector(customScrollView), customScrollView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)setContentOffset:(CGPoint)offset {
    %orig(CGPointMake(self.bounds.size.width, 0));
    [self.customScrollView setContentOffset:offset];
};

%end
