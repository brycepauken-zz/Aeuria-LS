#import "SBLockScreenScrollView.h"

#import "ALSCustomLockScreen.h"
#import "ALSCustomLockScreenContainer.h"
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
- (void)hideSubviewsIfNeeded;
- (id)lockScreenViewController;
- (void)searchSubviews;
- (void)setProperty:(id)property forKey:(id<NSCopying>)key;

@end

%hook SBLockScreenScrollView

%new
- (void)checkShouldShowCustomLockScreen {
    [self searchSubviews];
    
    NSNumber *shouldShowCustomLockScreenExistingNum = [self.customProperties objectForKey:@"shouldShowCustomLockScreen"];
    BOOL shouldShowCustomLockScreenExisting = [shouldShowCustomLockScreenExistingNum boolValue];
    
    NSNumber *notificationViewFilledNum = [self.customProperties objectForKey:@"notificationViewFilled"];
    BOOL notificationViewFilled = [notificationViewFilledNum boolValue];
    
    UIView *mediaControlsView = [self.customProperties objectForKey:@"mediaControlsView"];
    BOOL shouldShowCustomLockScreen = !mediaControlsView && (notificationViewFilledNum && !notificationViewFilled);
    
    if(!shouldShowCustomLockScreenExistingNum || shouldShowCustomLockScreenExisting!=shouldShowCustomLockScreen) {
        [self setProperty:@(shouldShowCustomLockScreen) forKey:@"shouldShowCustomLockScreen"];
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

/*
 Hides subviews that should be hidden
 */
%new
- (void)hideSubviewsIfNeeded {
    BOOL shouldHideSubviews = [self shouldHideSubviews];
    
    for(UIView *subview in self.subviews) {
        if(subview.frame.origin.x == self.bounds.size.width) {
            for(UIView *secondarySubview in subview.subviews) {
                if(secondarySubview.frame.size.width > self.bounds.size.width) {
                    [secondarySubview setHidden:shouldHideSubviews];
                }
            }
        }
    }
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *customLockScreen = [[[self lockScreenViewController] customLockScreenContainer] customLockScreen];
    UIView *tappedButton = [customLockScreen hitTest:point withEvent:event];
    if(tappedButton) {
        return customLockScreen;
    }
    return %orig;
}

- (void)layoutSubviews {
    %orig;
    
    if(self.contentSize.width > self.bounds.size.width*2) {
        CGAffineTransform translation;
        if(self.contentOffset.x > self.bounds.size.width) {
            translation = CGAffineTransformMakeTranslation(self.bounds.size.width-self.contentOffset.x, 0);
        }
        else {
            translation = CGAffineTransformIdentity;
        }
        [(UIView *)[[self lockScreenViewController] customLockScreenContainer] setTransform:translation];
    }
    
    //layoutSubviews is called on scrolling; ignore the other checks if this is the case here
    NSValue *lastKnownOffsetVal = [self.customProperties objectForKey:@"lastKnownOffset"];
    if(lastKnownOffsetVal) {
        CGPoint lastKnownOffset = [lastKnownOffsetVal CGPointValue];
        if(!CGPointEqualToPoint(lastKnownOffset, self.contentOffset)) {
            [self setProperty:[NSValue valueWithCGPoint:self.contentOffset] forKey:@"lastKnownOffset"];
            return;
        }
    }
    else {
        [self setProperty:[NSValue valueWithCGPoint:self.contentOffset] forKey:@"lastKnownOffset"];
    }
    
    BOOL notificationViewNotFound = ![self.customProperties objectForKey:@"notificationView"];
    [self searchSubviews];
    
    //tell the lock screen view controller if we've found the notification or media controls views
    if([self lockScreenViewController]) {
        UIView *mediaControlsView = [self.customProperties objectForKey:@"mediaControlsView"];
        if(mediaControlsView) {
            [[[self lockScreenViewController] customLockScreenContainer] setMediaControlsView:mediaControlsView];
        }
        UIView *notificationView = [self.customProperties objectForKey:@"notificationView"];
        if(notificationView) {
            [[[self lockScreenViewController] customLockScreenContainer] setNotificationView:notificationView];
        }
    }
    
    [self hideSubviewsIfNeeded];
    
    UIView *notificationView = [self.customProperties objectForKey:@"notificationView"];
    if(notificationViewNotFound && notificationView) {
        [self notificationViewChanged];
    }
    if(notificationView.superview.superview) {
        [notificationView.superview.superview layoutSubviews];
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
    [self searchSubviews];
    
    [[[self lockScreenViewController] customLockScreenContainer] notificationViewChanged];
    
    UIView *notificationView = [self.customProperties objectForKey:@"notificationView"];
    if(notificationView) {
        [self setProperty:@([((UITableView *)notificationView).dataSource tableView:(UITableView *)notificationView numberOfRowsInSection:0]>0) forKey:@"notificationViewFilled"];
        [self checkShouldShowCustomLockScreen];
    }
}

%new
- (void)searchSubviews {
    if(![self.customProperties objectForKey:@"mediaControlsView"]) {
        UIView *mediaControlsView = [self findViewOfClass:[%c(MPUSystemMediaControlsView) class] inView:self maxDepth:9];
        [self setProperty:mediaControlsView forKey:@"mediaControlsView"];
    }
    if(![self.customProperties objectForKey:@"notificationView"]) {
        UIView *notificationView = [self findViewOfClass:[%c(SBLockScreenNotificationTableView) class] inView:self maxDepth:6];
        [self setProperty:notificationView forKey:@"notificationView"];
    }
}

- (void)setContentOffset:(CGPoint)offset {
    offset.x = MAX(0, offset.x);
    %orig;
    CGFloat percentage = MAX(0,1-(offset.x/self.bounds.size.width));
    [[[[[self lockScreenViewController] customLockScreenContainer] customLockScreen] layer] removeAnimationForKey:@"ShakeAnimation"];
    [[[self lockScreenViewController] customLockScreenContainer] setPercentage:percentage];
    [self setAlpha:1-percentage*0.8];
};

%new
- (void)setProperty:(id)property forKey:(id<NSCopying>)key {
    if(property) {
        [self.customProperties setObject:property forKey:key];
    }
    else {
        [self.customProperties removeObjectForKey:key];
    }
}

%new
- (void)setShouldHideSubviews:(BOOL)shouldHide {
    [self setProperty:@(shouldHide) forKey:@"shouldHideSubviews"];
    [self hideSubviewsIfNeeded];
}

%new
- (BOOL)shouldHideSubviews {
    NSNumber *shouldHideSubviewsNum = [self.customProperties objectForKey:@"shouldHideSubviews"];
    if(!shouldHideSubviewsNum) {
        [self setShouldHideSubviews:YES];
        return YES;
    }
    return [shouldHideSubviewsNum boolValue];
}

%end
