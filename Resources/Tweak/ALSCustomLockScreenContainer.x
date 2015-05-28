#import "ALSCustomLockScreenContainer.h"

#import "ALSCustomLockScreen.h"
#import "ALSCustomLockScreenMask.h"
#import "ALSCustomLockScreenOverlay.h"
#import "SBLockScreenViewController.h"
#import "SBUIPasscodeLockViewWithKeypad.h"

@interface ALSCustomLockScreenContainer()

@property (nonatomic, strong) ALSCustomLockScreen *customLockScreen;
@property (nonatomic, strong) UIView *keyboardViewBackground;
@property (nonatomic, strong) ALSCustomLockScreenOverlay *scrollView;

@end

@implementation ALSCustomLockScreenContainer

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        __weak ALSCustomLockScreenContainer *weakSelf = self;
        _customLockScreen = [[ALSCustomLockScreen alloc] initWithFrame:self.bounds];
        [_customLockScreen setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
        [_customLockScreen setButtonTapped:^(int index) {
            if(index == -1) {
                //emergency button tapped
                [weakSelf.lockScreenViewController showEmergencyDialer];
            }
            else if(index == -2) {
                //delete button tapped
                [weakSelf.keypadView _noteBackspaceHit];
            }
            else {
                [weakSelf.keypadView _noteStringEntered:[NSString stringWithFormat:@"%i",(index==10?0:index+1)] eligibleForPlayingSounds:[weakSelf.keypadView playsKeypadSounds]];
            }
        }];
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
        
        [self repositionClockIfNeeded];
    }
    return self;
}

- (void)dealloc {
    [self.passcodeTextField removeTarget:self action:@selector(passcodeTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self.scrollView setDelegate:nil];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self.scrollView setContentSize:CGSizeMake(self.bounds.size.width*2, self.bounds.size.height)];
    [self.keyboardViewBackground setFrame:CGRectMake(0, self.bounds.size.height-self.keyboardView.frame.size.height, self.bounds.size.width, self.keyboardView.frame.size.height)];
    [self repositionClockIfNeeded];
}

- (void)lockScreenDateViewDidLayoutSubviews:(UIView *)lockScreenDateView {
    CGRect relativeFrame = [self convertRect:lockScreenDateView.frame fromView:lockScreenDateView.superview];
    if(!CGRectIsEmpty(relativeFrame)) {
        self.lockScreenDateVerticalCenter = (relativeFrame.origin.y+relativeFrame.size.height/2);
        [self repositionClockIfNeeded];
    }
}

- (void)mediaControlsBecameHidden:(BOOL)hidden {
    self.mediaControlsViewHidden = hidden;
    [self repositionClockIfNeeded];
}

- (void)notificationViewChanged {
    NSInteger numberOfRows = [((UITableView *)self.notificationView).dataSource tableView:(UITableView *)self.notificationView numberOfRowsInSection:0];
    BOOL shouldHideNotificationView = numberOfRows==0;
    self.notificationViewHidden = shouldHideNotificationView;
    [self repositionClockIfNeeded];
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
            if(characterCountDiff == -1) {
                [[self.customLockScreen filledOverlayMask] removeDotAndAnimate:YES];
            }
            else {
                [[self.customLockScreen filledOverlayMask] removeAllDotsAndAnimate:YES withCompletion:nil];
            }
        }
        self.passcodeTextFieldCharacterCount = newCharacterCount;
    }
}

- (void)removeFromSuperview {
    [((UITableView *)self.notificationView) setTableHeaderView:nil];
    [super removeFromSuperview];
}

- (void)repositionClockIfNeeded {
    if(!self.notificationViewHidden || self.nowPlayingPluginActive) {
        [self.customLockScreen setClockToPosition:CGPointMake(0.5, self.lockScreenDateVerticalCenter/self.bounds.size.height)];
    }
    else {
        [self.customLockScreen setClockToDefaultPosition];
    }
}

- (void)resetView {
    [self.customLockScreen setUserInteractionEnabled:YES];
    [self.scrollView setContentOffset:CGPointMake(self.bounds.size.width, 0)];
    [self.customLockScreen resetView];
    [self setNeedsLayout];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat percentage = 1-(scrollView.contentOffset.x/self.bounds.size.width);
    [self.customLockScreen updateScrollPercentage:percentage];
    [self.notificationView setAlpha:1-percentage];
    [self.mediaControlsView setAlpha:1-percentage];
    [self.keyboardViewBackground setAlpha:percentage*0.75];
    
    if(percentage==0) {
        [[self.customLockScreen filledOverlayMask] removeAllDotsAndAnimate:NO withCompletion:nil];
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
    
    if([UIBlurEffect class] && [UIVisualEffectView class]) {
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
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
    [self mediaControlsBecameHidden:YES];
}

/*
 Stores a reference to the notification view,
 and adds a background behind it.
 */
- (void)setNotificationView:(UIView *)notificationView {
    _notificationView = notificationView;
    [self notificationViewChanged];
}

- (void)setNowPlayingPluginActive:(BOOL)active {
    _nowPlayingPluginActive = active;
    [self repositionClockIfNeeded];
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