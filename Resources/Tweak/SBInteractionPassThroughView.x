#import "SBInteractionPassThroughView.h"

#import "ALSCustomLockScreenContainer.h"

@interface SBInteractionPassThroughView()

- (id)customProperties;
- (id)findViewOfClass:(Class)class inView:(UIView *)view maxDepth:(int)depth;

@end

%hook SBInteractionPassThroughView

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
    
    UIView *currentView = self;
    while(![currentView isKindOfClass:[%c(SBLockScreenView) class]] && currentView) {
        currentView = currentView.superview;
    }
    if(!currentView) {
        return;
    }
    
    UIView *mediaControls = [[self customProperties] objectForKey:@"mediaControls"];
    if(!mediaControls) {
        mediaControls = [self findViewOfClass:[%c(MPUSystemMediaControlsView) class] inView:self maxDepth:4];
    }
    if(mediaControls) {
        [mediaControls layoutSubviews];
    }
}

%end
