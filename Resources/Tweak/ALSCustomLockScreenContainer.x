#import "ALSCustomLockScreenContainer.h"

#import "ALSCustomLockScreen.h"
#import "ALSCustomLockScreenOverlay.h"

@interface ALSCustomLockScreenContainer()

@property (nonatomic, strong) ALSCustomLockScreen *customLockScreen;
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

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *tappedButton = [self.customLockScreen hitTest:point withEvent:event];
    if(tappedButton) {
        return self.customLockScreen;
    }
    return self.scrollView;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat percentage = 1-(scrollView.contentOffset.x/self.bounds.size.width);
    [self.customLockScreen updateScrollPercentage:percentage];
}

- (void)setFrame:(CGRect)frame {
    CGRect prevFrame = self.frame;
    [super setFrame:frame];
    if(!CGRectEqualToRect(self.frame, prevFrame)) {
        [self.scrollView setContentSize:CGSizeMake(self.bounds.size.width*2, self.bounds.size.height)];
    }
}

@end