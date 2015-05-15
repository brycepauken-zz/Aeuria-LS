#import "ALSCustomLockScreenContainer.h"

#import "ALSCustomLockScreen.h"
#import "ALSCustomLockScreenOverlay.h"

@interface ALSCustomLockScreenContainer()

@property (nonatomic, strong) ALSCustomLockScreen *customLockScreen;
@property (nonatomic, strong) UIView *keyboardView;
@property (nonatomic, strong) UIView *keyboardViewBackground;
@property (nonatomic, strong) UIView *keyboardViewOriginalSuperview;
@property (nonatomic, strong) UIView *mediaControlsView;
@property (nonatomic, strong) UIView *mediaControlsViewBackground;
@property (nonatomic, strong) UIView *mediaControlsViewOriginalSuperview;
@property (nonatomic, strong) UIView *notificationView;
@property (nonatomic, strong) UIView *notificationViewBackground;
@property (nonatomic, strong) UIView *notificationViewOriginalSuperview;
@property (nonatomic, strong) UITextField *passcodeTextField;
@property (nonatomic, strong) ALSCustomLockScreenOverlay *scrollView;

@end

@implementation ALSCustomLockScreenContainer

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        _customLockScreen = [[ALSCustomLockScreen alloc] initWithFrame:self.bounds];
        [_customLockScreen setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
        [self addSubview:_customLockScreen];
        
        _scrollView = [[ALSCustomLockScreenOverlay alloc] initWithFrame:self.bounds];
        [_scrollView setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
        [_scrollView setBounces:NO];
        [_scrollView setContentSize:CGSizeMake(self.bounds.size.width*2, self.bounds.size.height)];
        [_scrollView setContentOffset:CGPointMake(self.bounds.size.width, 0)];
        [_scrollView setDelegate:self];
        [_scrollView setPagingEnabled:YES];
        [_scrollView setShowsHorizontalScrollIndicator:NO];
        [_scrollView setShowsVerticalScrollIndicator:NO];
        [self addSubview:_scrollView];
        
        UIView *overlayView = [[UIView alloc] initWithFrame:self.bounds];
        [overlayView setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
        [self addSubview:overlayView];
    }
    return self;
}

- (void)addKeyboardView:(UIView *)keyboardView fromSuperView:(UIView *)superView {
    [self setKeyboardView:keyboardView];
    [keyboardView removeFromSuperview];
    [self.scrollView addSubview:keyboardView];
    
    if([UIPrintInteractionController class]) {
        UIVisualEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
        UIVisualEffectView *visualEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        [visualEffectView setFrame:keyboardView.frame];
        [self setKeyboardViewBackground:visualEffectView];
    }
    else {
        [self setKeyboardViewBackground:[[UIView alloc] initWithFrame:keyboardView.frame]];
        [self.keyboardViewBackground setBackgroundColor:[UIColor colorWithWhite:0.5 alpha:0.75]];
    }
    [self.keyboardViewBackground setAlpha:0];
    [self insertSubview:self.keyboardViewBackground belowSubview:self.scrollView];
    
    [self setKeyboardViewOriginalSuperview:superView];
    
    [self.customLockScreen setKeyboardHeight:keyboardView.frame.size.height];
}

- (void)addMediaControlsView:(UIView *)mediaControlsView fromSuperView:(UIView *)superView {
    if(![self.customLockScreen shouldShowWithNotifications] || mediaControlsView==self.mediaControlsView) {
        return;
    }
    
    [self setMediaControlsView:mediaControlsView];
    [mediaControlsView removeFromSuperview];
    [self.scrollView addSubview:mediaControlsView];
    
    [self setMediaControlsViewBackground:[[UIView alloc] initWithFrame:mediaControlsView.frame]];
    [self.mediaControlsViewBackground setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.5]];
    [self insertSubview:self.mediaControlsViewBackground belowSubview:self.scrollView];
    
    [self setMediaControlsViewOriginalSuperview:superView];
}

- (void)addNotificationView:(UIView *)notificationView fromSuperView:(UIView *)superView {
    if(![self.customLockScreen shouldShowWithNotifications] || notificationView==self.notificationView) {
        return;
    }
    
    //cut notificiation view height in half
    CGRect notificationViewFrame = notificationView.frame;
    notificationViewFrame.size.height /= 2;
    [notificationView setFrame:notificationViewFrame];
    [(UITableView *)notificationView setSeparatorStyle:UITableViewCellSeparatorStyleNone];
    
    //remove all non-tableview subviews
    for(UIView *subview in [notificationView.subviews copy]) {
        if(!([subview isKindOfClass:[%c(UITableViewWrapperView) class]] || [subview isKindOfClass:[UITableView class]])) {
            [subview removeFromSuperview];
        }
    }
    
    [self setNotificationView:notificationView];
    [notificationView removeFromSuperview];
    [self.scrollView addSubview:notificationView];
    
    [self setNotificationViewBackground:[[UIView alloc] initWithFrame:notificationView.frame]];
    [self.notificationViewBackground setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.5]];
    [self insertSubview:self.notificationViewBackground belowSubview:self.scrollView];
    
    [self setNotificationViewOriginalSuperview:superView];
    
    [self notificationViewChanged];
}

- (void)dealloc {
    [self removeAddedViews];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *tappedButton = [self.customLockScreen hitTest:point withEvent:event];
    if(tappedButton) {
        return self.customLockScreen;
    }
    
    if((!self.notificationViewBackground.hidden && CGRectContainsPoint(self.notificationView.frame, [self.scrollView convertPoint:point fromView:self])) ||
       (!self.mediaControlsViewBackground.hidden && CGRectContainsPoint(self.mediaControlsView.frame, [self.scrollView convertPoint:point fromView:self])) ||
       (!self.keyboardViewBackground.hidden && CGRectContainsPoint(self.keyboardView.frame, [self.scrollView convertPoint:point fromView:self]))) {
        [self.scrollView setScrollEnabled:NO];
    }
    else {
        [self.scrollView setScrollEnabled:YES];
    }
    return [self.scrollView hitTest:[self.scrollView convertPoint:point fromView:self] withEvent:event];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self.notificationView setFrame:CGRectMake(self.scrollView.bounds.size.width, 0, self.scrollView.bounds.size.width, self.notificationView.frame.size.height)];
    [self.notificationViewBackground setFrame:CGRectMake(0, 0, self.scrollView.bounds.size.width, self.notificationView.frame.size.height)];
    [self.mediaControlsView setFrame:CGRectMake(self.scrollView.bounds.size.width, self.scrollView.bounds.size.height-self.mediaControlsView.frame.size.height-20, self.scrollView.bounds.size.width, self.mediaControlsView.frame.size.height)];
    [self.mediaControlsViewBackground setFrame:CGRectMake(0, self.scrollView.bounds.size.height-self.mediaControlsView.frame.size.height-20, self.scrollView.bounds.size.width, self.mediaControlsView.frame.size.height+20)];
    [self.keyboardView setFrame:CGRectMake(self.scrollView.bounds.size.width, self.bounds.size.height-self.keyboardView.frame.size.height, self.bounds.size.width, self.keyboardView.frame.size.height)];
    [self.keyboardViewBackground setFrame:CGRectMake(0, self.bounds.size.height-self.keyboardView.frame.size.height, self.bounds.size.width, self.keyboardView.frame.size.height)];
}

- (void)notificationViewChanged {
    NSInteger numberOfRows = [((UITableView *)self.notificationView).dataSource tableView:(UITableView *)self.notificationView numberOfRowsInSection:0];
    if(numberOfRows==1) {
        CGFloat itemHeight = [((UITableView *)self.notificationView).delegate tableView:(UITableView *)self.notificationView heightForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        [((UITableView *)self.notificationView) setTableHeaderView:[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.notificationView.bounds.size.width, MAX(0,(self.notificationView.bounds.size.height-itemHeight)/2))]];
    }
    else {
        [((UITableView *)self.notificationView) setTableHeaderView:[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.notificationView.bounds.size.width, 0)]];
    }
    BOOL shouldHideNotificationView = numberOfRows==0;
    [self.notificationView setHidden:shouldHideNotificationView];
    [self.notificationViewBackground setHidden:shouldHideNotificationView];
}

- (void)removeAddedViews {
    [self.mediaControlsView removeFromSuperview];
    [self.mediaControlsViewOriginalSuperview addSubview:self.mediaControlsView];
    self.mediaControlsView = nil;
    self.mediaControlsViewOriginalSuperview = nil;
    
    [self.notificationView removeFromSuperview];
    [self.notificationViewOriginalSuperview addSubview:self.notificationView];
    self.notificationView = nil;
    self.notificationViewOriginalSuperview = nil;
    
    [self.keyboardView removeFromSuperview];
    [self.keyboardViewOriginalSuperview addSubview:self.keyboardView];
    self.keyboardView = nil;
    self.keyboardViewOriginalSuperview = nil;
}

- (void)resetView {
    [self setUserInteractionEnabled:YES];
    [self.scrollView setContentOffset:CGPointMake(self.bounds.size.width, 0)];
    [self.customLockScreen resetView];
    [self setNeedsLayout];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat percentage = 1-(scrollView.contentOffset.x/self.bounds.size.width);
    [self.customLockScreen updateScrollPercentage:percentage];
    [self.notificationView setAlpha:1-percentage];
    [self.notificationViewBackground setAlpha:1-percentage];
    [self.mediaControlsView setAlpha:1-percentage];
    [self.mediaControlsViewBackground setAlpha:1-percentage];
    [self.keyboardViewBackground setAlpha:percentage*0.75];
    
    if(self.passcodeTextField) {
        if(percentage==1 && ![self.passcodeTextField isEditing]) {
            [self.passcodeTextField becomeFirstResponder];
        }
        else if([self.passcodeTextField isEditing]) {
            [self.passcodeTextField resignFirstResponder];
        }
    }
}

- (void)setFrame:(CGRect)frame {
    CGRect prevFrame = self.frame;
    [super setFrame:frame];
    if(!CGRectEqualToRect(self.frame, prevFrame)) {
        [self.scrollView setContentSize:CGSizeMake(self.bounds.size.width*2, self.bounds.size.height)];
    }
}

- (void)setPasscodeEntered:(void (^)(NSString *passcode))passcodeEntered {
    [self.customLockScreen setPasscodeEntered:passcodeEntered];
}

@end