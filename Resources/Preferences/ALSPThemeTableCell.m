#import "ALSPThemeTableCell.h"

@interface ALSPThemeTableCell()

@property (nonatomic, strong) UIView *bottomDivider;
@property (nonatomic, strong) UIImageView *checkmarkIconView;
@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UILabel *respringLabel;
@property (nonatomic, strong) UIImageView *snowflakeIconView;
@property (nonatomic, strong) UIView *topDivider;

@end

@implementation ALSPThemeTableCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if(self) {
        _topDivider = [[UIView alloc] init];
        [_topDivider setBackgroundColor:[UIColor colorWithWhite:0.85 alpha:1]];
        
        _bottomDivider = [[UIView alloc] init];
        [_bottomDivider setBackgroundColor:[UIColor colorWithWhite:0.85 alpha:1]];
        
        static dispatch_once_t dispatchOnceToken;
        static NSString *checkmarkIconPath;
        static NSString *snowflakeIconPath;
        dispatch_once(&dispatchOnceToken, ^{
            NSBundle *bundle = [[NSBundle alloc] initWithPath:@"/Library/PreferenceBundles/AeuriaLSPreferences.bundle"];
            checkmarkIconPath = [bundle pathForResource:@"Checkmark" ofType:@"png"];
            snowflakeIconPath = [bundle pathForResource:@"Snowflake" ofType:@"png"];
        });
        
        _checkmarkIconView = [[UIImageView alloc] init];
        [_checkmarkIconView setImage:[UIImage imageWithContentsOfFile:checkmarkIconPath]];
        _snowflakeIconView = [[UIImageView alloc] init];
        [_snowflakeIconView setImage:[UIImage imageWithContentsOfFile:snowflakeIconPath]];
        
        _label = [[UILabel alloc] init];
        [_label setFont:[UIFont systemFontOfSize:20]];
        [_label setTextColor:[UIColor colorWithWhite:0.2 alpha:1]];
        
        _respringLabel = [[UILabel alloc] init];
        [_respringLabel setFont:[UIFont boldSystemFontOfSize:20]];
        [_respringLabel setText:@"Respring"];
        [_respringLabel setTextAlignment:NSTextAlignmentCenter];
        
        [self addSubview:_topDivider];
        [self addSubview:_bottomDivider];
        [self addSubview:_checkmarkIconView];
        [self addSubview:_snowflakeIconView];
        [self addSubview:_label];
        [self addSubview:_respringLabel];
    }
    return self;
}

- (void)animateCellStatusChange:(HOICellStatus)newStatus {
    void (^showAnimation)() = ^{
        [self.checkmarkIconView setHidden:newStatus!=HOICellStatusCheckmarkVisible];
        [self.snowflakeIconView setHidden:newStatus!=HOICellStatusSnowflakeVisible];
        if(newStatus != HOICellStatusNone) {
            if(newStatus == HOICellStatusSnowflakeVisible) {
                [[self class] popView:self.snowflakeIconView completion:nil];
            }
            else if(newStatus == HOICellStatusCheckmarkVisible) {
                [[self class] popView:self.checkmarkIconView completion:nil];
            }
        }
    };
    
    if(!self.checkmarkIconView.hidden) {
        [[self class] unpopView:self.checkmarkIconView completion:^{
            [self.checkmarkIconView setHidden:YES];
            showAnimation();
        }];
    }
    else if(!self.snowflakeIconView.hidden) {
        [[self class] unpopView:self.snowflakeIconView completion:^{
            [self.snowflakeIconView setHidden:YES];
            showAnimation();
        }];
    }
    
    else {
        showAnimation();
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    [self.topDivider setFrame:CGRectMake(0, 0, self.bounds.size.width, 1)];
    [self.bottomDivider setFrame:CGRectMake(0, self.bounds.size.height-1, self.bounds.size.width, 1)];
    [self.checkmarkIconView setFrame:CGRectMake(14, 14, self.bounds.size.height-28, self.bounds.size.height-28)];
    [self.snowflakeIconView setFrame:CGRectMake(14, 14, self.bounds.size.height-28, self.bounds.size.height-28)];
    [self.label setFrame:CGRectMake(self.bounds.size.height, 0, self.bounds.size.width-self.bounds.size.height-10, self.bounds.size.height)];
    [self.respringLabel setFrame:CGRectMake(10, 0, self.bounds.size.width-20, self.bounds.size.height)];
}

+ (void)popView:(UIView *)view completion:(void (^)())completion {
    [CATransaction begin];
    [CATransaction setCompletionBlock:completion];
    
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    
    CATransform3D scale1 = CATransform3DMakeScale(0.5, 0.5, 1);
    CATransform3D scale2 = CATransform3DMakeScale(1.2, 1.2, 1);
    CATransform3D scale3 = CATransform3DMakeScale(0.9, 0.9, 1);
    CATransform3D scale4 = CATransform3DMakeScale(1.0, 1.0, 1);
    
    NSArray *frameValues = [NSArray arrayWithObjects:[NSValue valueWithCATransform3D:scale1],[NSValue valueWithCATransform3D:scale2],[NSValue valueWithCATransform3D:scale3],[NSValue valueWithCATransform3D:scale4],nil];
    [animation setValues:frameValues];
    
    NSArray *frameTimes = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0],[NSNumber numberWithFloat:0.5],[NSNumber numberWithFloat:0.9],[NSNumber numberWithFloat:1.0],nil];
    [animation setKeyTimes:frameTimes];
    
    animation.fillMode = kCAFillModeForwards;
    animation.removedOnCompletion = NO;
    animation.duration = .2;
    
    [view.layer addAnimation:animation forKey:@"popup"];
    
    [CATransaction commit];
}

- (void)setCheckmarkHidden:(BOOL)hidden {
    [self.checkmarkIconView setHidden:hidden];
}

- (void)setRespringLabelHidden:(BOOL)hidden {
    [self.label setHidden:!hidden];
    [self.respringLabel setHidden:hidden];
}

- (void)setSnowflakeHidden:(BOOL)hidden {
    [self.snowflakeIconView setHidden:hidden];
}

- (void)setTopDividerHidden:(BOOL)hidden {
    [self.topDivider setHidden:hidden];
}

- (void)setText:(NSString *)text {
    [self.label setText:text];
}

- (void)setUserInteractionEnabled:(BOOL)enabled {
    [super setUserInteractionEnabled:enabled];
    
    [self.respringLabel setTextColor:enabled?[UIColor colorWithRed:0 green:(122/255.0f) blue:1 alpha:1]:[UIColor lightGrayColor]];
}

+ (void)unpopView:(UIView *)view completion:(void (^)())completion {
    [CATransaction begin];
    [CATransaction setCompletionBlock:completion];
    
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    
    CATransform3D scale1 = CATransform3DMakeScale(1.0, 1.0, 1);
    CATransform3D scale2 = CATransform3DMakeScale(0.25, 0.25, 1);
    
    NSArray *frameValues = [NSArray arrayWithObjects:[NSValue valueWithCATransform3D:scale1],[NSValue valueWithCATransform3D:scale2],nil];
    [animation setValues:frameValues];
    
    NSArray *frameTimes = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0],[NSNumber numberWithFloat:1.0],nil];
    [animation setKeyTimes:frameTimes];
    
    animation.fillMode = kCAFillModeForwards;
    animation.removedOnCompletion = NO;
    animation.duration = .1;
    
    [view.layer addAnimation:animation forKey:@"unpop"];
    
    [CATransaction commit];
}

@end
