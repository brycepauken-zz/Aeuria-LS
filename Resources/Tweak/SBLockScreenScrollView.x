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

- (NSArray *)ancestorsOfView:(UIView *)view;
- (void)checkShouldShowCustomLockScreen;
- (id)findViewOfClass:(Class)class inView:(UIView *)view maxDepth:(int)depth;
- (void)hideSubviewsIfNeeded;
- (id)lockScreenViewController;
- (void)searchSubviews;
+ (void)setNonAncestorsHidden:(BOOL)hidden fromView:(UIView *)view withAncestorsList:(NSArray *)ancestorsList currentDepth:(NSInteger)currentDepth;
- (void)setProperty:(id)property forKey:(id<NSCopying>)key;

@end

%hook SBLockScreenScrollView

/*
 Returns an array containing, in order, the views in the
 hierarchy leading from `self` to `view`.
 */
%new
- (NSArray *)ancestorsOfView:(UIView *)view {
    NSMutableArray *ancestors = [[NSMutableArray alloc] init];
    UIView *currentView = view.superview;
    while(currentView!=self && currentView) {
        [ancestors insertObject:currentView atIndex:0];
        currentView = currentView.superview;
    }
    if(currentView == self) {
        return ancestors;
    }
    return nil;
}

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
 Updates all subviews other than SBPasscodeKeyboard (a subview of
 SBUIPasscodeLockViewWithKeyboard) to be hidden or shown as needed
 */
%new
- (void)hideSubviewsIfNeeded {
    BOOL shouldHideSubviews = [self shouldHideSubviews];
    NSArray *mediaControlsViewAncestors = [self.customProperties objectForKey:@"mediaControlsViewAncestors"];
    NSArray *notificationViewAncestors = [self.customProperties objectForKey:@"notificationViewAncestors"];
    
    for(UIView *subview in self.subviews) {
        if([subview isKindOfClass:[%c(SBUIPasscodeLockViewWithKeyboard) class]]) {
            for(UIView *passcodeViewSubview in subview.subviews) {
                if([passcodeViewSubview isKindOfClass:[UILabel class]]) {
                    //we also remove the 'enter passcode' label, since it's tricky to keep hidden
                    [passcodeViewSubview removeFromSuperview];
                }
                [passcodeViewSubview setHidden:(shouldHideSubviews && ![passcodeViewSubview isKindOfClass:[%c(SBPasscodeKeyboard) class]])];
            }
        }
        else if(subview == [mediaControlsViewAncestors firstObject]) {
            [[self class] setNonAncestorsHidden:shouldHideSubviews fromView:subview withAncestorsList:mediaControlsViewAncestors currentDepth:1];
        }
        else if(subview == [notificationViewAncestors firstObject]) {
            [[self class] setNonAncestorsHidden:shouldHideSubviews fromView:subview withAncestorsList:notificationViewAncestors currentDepth:1];
        }
        else {
            [subview setHidden:shouldHideSubviews];
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
        [self setProperty:[self ancestorsOfView:mediaControlsView] forKey:@"mediaControlsViewAncestors"];
    }
    if(![self.customProperties objectForKey:@"notificationView"]) {
        UIView *notificationView = [self findViewOfClass:[%c(SBLockScreenNotificationTableView) class] inView:self maxDepth:6];
        [self setProperty:notificationView forKey:@"notificationView"];
        [self setProperty:[self ancestorsOfView:notificationView] forKey:@"notificationViewAncestors"];
    }
}

- (void)setContentOffset:(CGPoint)offset {
    %orig;
    [[[[[self lockScreenViewController] customLockScreenContainer] customLockScreen] layer] removeAnimationForKey:@"position"];
    [[[[self lockScreenViewController] customLockScreenContainer] scrollView] setContentOffset:offset];
};

/*
 Recurses through the view hierarchy and updates the hidden
 property on views that aren't part of the given ancestor
 list (i.e., hides everything not needed to show the
 notification or media controls views)
 */
%new
+ (void)setNonAncestorsHidden:(BOOL)hidden fromView:(UIView *)view withAncestorsList:(NSArray *)ancestorsList currentDepth:(NSInteger)currentDepth {
    [view setHidden:NO];
    if(currentDepth >= ancestorsList.count) {
        return;
    }
    UIView *ancestor = [ancestorsList objectAtIndex:currentDepth];
    for(UIView *subview in view.subviews) {
        if(subview == ancestor) {
            [self setNonAncestorsHidden:hidden fromView:subview withAncestorsList:ancestorsList currentDepth:currentDepth+1];
        }
        else {
            [subview setHidden:hidden];
        }
    }
}

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
