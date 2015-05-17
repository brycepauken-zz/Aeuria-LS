#import "ALSCustomLockScreenContainer.h"

#import "ALSCustomLockScreen.h"
#import "ALSCustomLockScreenMask.h"
#import "ALSCustomLockScreenOverlay.h"

@interface ALSCustomLockScreenContainer()

@property (nonatomic, strong) ALSCustomLockScreen *customLockScreen;
@property (nonatomic, weak) UIView *keyboardView;
@property (nonatomic, strong) UIView *keyboardViewBackground;
@property (nonatomic, weak) UIView *mediaControlsView;
@property (nonatomic, strong) UIView *mediaControlsViewBackground;
@property (nonatomic, weak) UIView *notificationView;
@property (nonatomic, strong) UIView *notificationViewBackground;
@property (nonatomic, weak) UITextField *passcodeTextField;
@property (nonatomic) NSInteger passcodeTextFieldCharacterCount;
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
        [_scrollView setScrollEnabled:NO];
        [_scrollView setShowsHorizontalScrollIndicator:NO];
        [_scrollView setShowsVerticalScrollIndicator:NO];
        [self addSubview:_scrollView];
    }
    return self;
}

- (void)dealloc {
    [self.passcodeTextField removeTarget:self action:@selector(passcodeTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self.notificationViewBackground setFrame:CGRectMake(0, 0, self.scrollView.bounds.size.width, self.notificationView.frame.size.height)];
    [self.mediaControlsViewBackground setFrame:CGRectMake(0, self.scrollView.bounds.size.height-self.mediaControlsView.frame.size.height-20, self.scrollView.bounds.size.width, self.mediaControlsView.frame.size.height+20)];
    [self.keyboardViewBackground setFrame:CGRectMake(0, self.bounds.size.height-self.keyboardView.frame.size.height, self.bounds.size.width, self.keyboardView.frame.size.height)];
}

- (void)notificationViewChanged {
    return;
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

- (void)passcodeTextFieldDidChange:(UITextField *)textField {
    if(textField == self.passcodeTextField) {
        NSInteger newCharacterCount = textField.text.length;
        NSInteger characterCountDiff = newCharacterCount-self.passcodeTextFieldCharacterCount;
        if(characterCountDiff > 0) {
            for(int i=0;i<characterCountDiff;i++) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(i*0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [[self.customLockScreen filledOverlayMask] addDotAndAnimate:YES];
                });
            }
        }
        else {
            for(int i=0;i<-characterCountDiff;i++) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(i*0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [[self.customLockScreen filledOverlayMask] removeDotAndAnimate:YES];
                });
            }
        }
        self.passcodeTextFieldCharacterCount = newCharacterCount;
    }
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
    
    if(self.passcodeTextField && percentage==1 && ![self.passcodeTextField isFirstResponder]) {
        //[self.passcodeTextField becomeFirstResponder];
    }
}

- (void)setFrame:(CGRect)frame {
    CGRect prevFrame = self.frame;
    [super setFrame:frame];
    if(!CGRectEqualToRect(self.frame, prevFrame)) {
        [self.scrollView setContentSize:CGSizeMake(self.bounds.size.width*2, self.bounds.size.height)];
    }
}

/*
 Stores a reference to the passcode keyboard view,
 and adds a background behind it.
 */
- (void)setKeyboardView:(UIView *)keyboardView {
    _keyboardView = keyboardView;
    
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
    [self.customLockScreen setKeyboardHeight:keyboardView.frame.size.height];
}

/*
 Stores a reference to the media controls view,
 and adds a background behind it.
 */
- (void)setMediaControlsView:(UIView *)mediaControlsView {
    _mediaControlsView = mediaControlsView;
    
    [self setMediaControlsViewBackground:[[UIView alloc] initWithFrame:mediaControlsView.frame]];
    [self.mediaControlsViewBackground setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.5]];
    [self insertSubview:self.mediaControlsViewBackground belowSubview:self.scrollView];
}

/*
 Stores a reference to the notification view,
 and adds a background behind it.
 */
- (void)setNotificationView:(UIView *)notificationView {
    _notificationView = notificationView;
    
    [self setNotificationViewBackground:[[UIView alloc] initWithFrame:notificationView.frame]];
    [self.notificationViewBackground setBackgroundColor:[UIColor colorWithWhite:0 alpha:0.5]];
    [self insertSubview:self.notificationViewBackground belowSubview:self.scrollView];
    
    [self notificationViewChanged];
}

- (void)setPasscodeEntered:(void (^)(NSString *passcode))passcodeEntered {
    [self.customLockScreen setPasscodeEntered:passcodeEntered];
}

- (void)setPasscodeTextField:(UITextField *)passcodeTextField {
    _passcodeTextField = passcodeTextField;
    [_passcodeTextField addTarget:self action:@selector(passcodeTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    self.passcodeTextFieldCharacterCount = passcodeTextField.text.length;
}

@end