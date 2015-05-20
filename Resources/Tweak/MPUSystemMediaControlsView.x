#import "MPUSystemMediaControlsView.h"

#import "SBLockScreenViewController.h"

@interface MPUSystemMediaControlsView()

- (id)customProperties;
- (id)lockScreenViewController;

@end

%hook MPUSystemMediaControlsView

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
    
    UIView *currentView = self;
    while(![currentView isKindOfClass:[%c(SBLockScreenView) class]] && currentView) {
        currentView = currentView.superview;
    }
    if(!currentView) {
        return;
    }
    
    UIView *offsetedView = self.superview.superview;
    if(offsetedView && offsetedView.superview) {
        CGRect offsetedViewFrame = offsetedView.frame;
        if(![[self customProperties] objectForKey:@"originalYOffset"]) {
            [[self customProperties] setObject:@(offsetedViewFrame.origin.y) forKey:@"originalYOffset"];
        }
        if([[self lockScreenViewController] customLockScreenHidden]) {
            offsetedViewFrame.origin.y = [[[self customProperties] objectForKey:@"originalYOffset"] doubleValue];
        }
        else {
            offsetedViewFrame.origin.y = offsetedView.superview.frame.size.height - offsetedViewFrame.size.height - 20;
        }
        [offsetedView setFrame:offsetedViewFrame];
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
