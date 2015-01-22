#import "ALSPContainerView.h"

#import "ALSPMainView.h"

@interface ALSPContainerView()

@property (nonatomic, strong) ALSPMainView *mainView;
@property (nonatomic, strong) UIScrollView *scrollView;

@end

@implementation ALSPContainerView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self) {
        _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 64, self.bounds.size.width, self.bounds.size.height-64)];
        
        _mainView = [[ALSPMainView alloc] initWithFrame:CGRectMake(20, 20, self.bounds.size.width-40, _scrollView.bounds.size.height-20)];
        [_mainView setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
        [_scrollView addSubview:_mainView];
        
        [self setBackgroundColor:[UIColor colorWithWhite:0.85 alpha:1]];
        [self addSubview:_scrollView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self.scrollView setFrame:CGRectMake(0, 64, self.bounds.size.width, self.bounds.size.height-64)];
    
    CGFloat mainViewHeight = [self.mainView totalHeight];
    [self.mainView setFrame:CGRectMake(20, 20, self.bounds.size.width-40, mainViewHeight)];
    [self.scrollView setContentSize:CGSizeMake(self.bounds.size.width, mainViewHeight+40)];
}

@end
