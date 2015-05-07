#import "ALSCustomLockScreenContainer.h"

#import "ALSCustomLockScreen.h"
#import "ALSCustomLockScreenOverlay.h"

@interface ALSCustomLockScreenContainer()

@property (nonatomic, strong) ALSCustomLockScreen *customLockScreen;
@property (nonatomic, strong) UIView *notificationView;
@property (nonatomic, strong) UIView *notificationViewBackground;
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

- (void)addNotificationView:(UIView *)notificationView {
    //cut notificiation view height in half
    CGRect notificationViewFrame = notificationView.frame;
    notificationViewFrame.size.height /= 2;
    [notificationView setFrame:notificationViewFrame];
    
    //remove all non-tableview subviews
    for(UIView *subview in [notificationView.subviews copy]) {
        if(!([subview isKindOfClass:[%c(UITableViewWrapperView) class]] || [subview isKindOfClass:[UITableView class]])) {
            [subview removeFromSuperview];
        }
    }
    
    [self setNotificationView:notificationView];
    [self.scrollView addSubview:notificationView];
    
    [self setNotificationViewBackground:[[UIView alloc] initWithFrame:notificationView.frame]];
    [self.notificationViewBackground setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.5]];
    [self insertSubview:self.notificationViewBackground belowSubview:self.scrollView];
    
    [self notificationViewChanged];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *tappedButton = [self.customLockScreen hitTest:point withEvent:event];
    if(tappedButton) {
        return self.customLockScreen;
    }
    return self.scrollView;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self.notificationView setFrame:CGRectMake(self.scrollView.bounds.size.width, self.scrollView.bounds.size.height-self.notificationView.frame.size.height, self.scrollView.bounds.size.width, self.notificationView.frame.size.height)];
    [self.notificationViewBackground setFrame:CGRectMake(0, self.scrollView.bounds.size.height-self.notificationView.frame.size.height, self.scrollView.bounds.size.width, self.notificationView.frame.size.height)];
}

- (void)notificationViewChanged {
    //CGSize contentSize = [(UITableView *)self.notificationView contentSize];
    BOOL shouldHideNotificationView = [((UITableView *)self.notificationView).dataSource tableView:(UITableView *)self.notificationView numberOfRowsInSection:0]==0;
    [self.notificationView setHidden:shouldHideNotificationView];
    [self.notificationViewBackground setHidden:shouldHideNotificationView];
}

- (void)resetView {
    [self.scrollView setContentOffset:CGPointMake(self.bounds.size.width, 0)];
    [self.customLockScreen resetView];
    [self setNeedsLayout];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat percentage = 1-(scrollView.contentOffset.x/self.bounds.size.width);
    [self.customLockScreen updateScrollPercentage:percentage];
    [self.notificationView setAlpha:1-percentage];
    [self.notificationViewBackground setAlpha:1-percentage];
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