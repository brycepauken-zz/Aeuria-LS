#import "ALSCustomLockScreenContainer.h"

#import "ALSCustomLockScreen.h"
#import "ALSCustomLockScreenMask.h"
#import "ALSCustomLockScreenOverlay.h"
#import "SBLockScreenViewController.h"
#import "SBUIPasscodeLockViewWithKeypad.h"

@interface ALSCustomLockScreenContainer()

@property (nonatomic, strong) ALSCustomLockScreen *customLockScreen;

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
        
        [self repositionClockIfNeeded];
    }
    return self;
}

- (void)dealloc {
    [self.passcodeTextField removeTarget:self action:@selector(passcodeTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
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
    [self updateCustomLockScreenAlpha];
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
    [self.customLockScreen resetView];
    [self setNeedsLayout];
}

/*
 Stores a reference to the passcode keyboard view.
 */
- (void)setKeyboardView:(UIView *)keyboardView {
    _keyboardView = keyboardView;
    [self.customLockScreen setKeyboardHeight:keyboardView.frame.size.height];
}

/*
 Stores a reference to the media controls view.
 */
- (void)setMediaControlsView:(UIView *)mediaControlsView {
    _mediaControlsView = mediaControlsView;
    [self mediaControlsBecameHidden:YES];
}

/*
 Stores a reference to the notification view.
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

- (void)setPercentage:(CGFloat)percentage {
    _percentage = MAX(0,MIN(1,percentage));
    
    [self.customLockScreen updateScrollPercentage:_percentage];
    [self.notificationView setAlpha:1-_percentage];
    [self.mediaControlsView setAlpha:1-_percentage];
    
    [self updateCustomLockScreenAlpha];
    
    if(percentage==0) {
        [[self.customLockScreen filledOverlayMask] removeAllDotsAndAnimate:NO withCompletion:nil];
    }
}

- (void)updateCustomLockScreenAlpha {
    [self.customLockScreen setAlpha:(self.mediaControlsViewHidden?1:self.percentage)];
}

@end