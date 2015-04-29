#import "ALSPreferencesFontPicker.h"

@interface ALSPreferencesFontPicker()

@property (nonatomic, strong) UIView *backgroundOverlay;
@property (nonatomic, copy) void (^completionBlock)(NSString *fontName);
@property (nonatomic, strong) NSMutableArray *fontNames;
@property (nonatomic, strong) UILabel *selectionLabel;
@property (nonatomic, strong) UITableView *tableView;

@end

@implementation ALSPreferencesFontPicker

static const int kButtonImageLineLength = 16;
static const int kButtonImageLineThickness = 2;
static const int kButtonMargins = 8;
static const int kButtonSize = 30;
static const int kFontPickerWindowHorizontalPadding = 20;
static const int kFontPickerWindowVerticalPadding = 12;
static const int kFontPickerWindowWidth = 280;
static const int kTextFieldHeight = 30;

- (instancetype)initWithParentView:(UIView *)parentView {
    self = [super init];
    if(self) {
        //get a list of font names
        _fontNames = [[NSMutableArray alloc] init];
        NSArray *fontFamilies = [[UIFont familyNames] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
        for(int i=0;i<fontFamilies.count;i++) {
            NSString *fontName = [fontFamilies objectAtIndex:i];
            [_fontNames addObject:@{@"name":fontName, @"fonts":[[UIFont fontNamesForFamilyName:fontName] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)]}];
        }
        
        //create an overlay that darkens the window
        _backgroundOverlay = [[UIView alloc] initWithFrame:parentView.bounds];
        [_backgroundOverlay setAlpha:0];
        [_backgroundOverlay setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
        [_backgroundOverlay setBackgroundColor:[UIColor blackColor]];
        [parentView addSubview:_backgroundOverlay];
        
        //create the accept and cancel buttons
        UIButton *firstButton;
        UIButton *secondButton;
        CGFloat textButtonSectionHeight = MAX(kButtonSize, kTextFieldHeight)+kFontPickerWindowVerticalPadding*2;
        for(int i=0;i<2;i++) {
            UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(kFontPickerWindowWidth-kFontPickerWindowHorizontalPadding-(i==0?kButtonMargins+kButtonSize*2:kButtonSize),  kFontPickerWindowWidth+textButtonSectionHeight*3/2-kButtonSize/2, kButtonSize, kButtonSize)];
            [button addTarget:self action:@selector(buttonDown:) forControlEvents:UIControlEventTouchDown];
            [button addTarget:self action:@selector(buttonTapped:) forControlEvents:UIControlEventTouchUpInside];
            [button setBackgroundColor:[UIColor whiteColor]];
            [button setTag:i];
            [button.layer setCornerRadius:kButtonSize/2];
            
            CAShapeLayer *buttonImage = [[CAShapeLayer alloc] init];
            [buttonImage setFillColor:[UIColor darkGrayColor].CGColor];
            UIBezierPath *buttonImagePath = [[UIBezierPath alloc] init];
            if(i==0) {
                firstButton = button;
                [buttonImagePath appendPath:[UIBezierPath bezierPathWithRect:CGRectMake(-kButtonImageLineLength/2, kButtonImageLineLength/2-kButtonImageLineThickness, kButtonImageLineLength/2, kButtonImageLineThickness)]];
                [buttonImagePath appendPath:[UIBezierPath bezierPathWithRect:CGRectMake(-kButtonImageLineThickness/2, -kButtonImageLineLength/2, kButtonImageLineThickness, kButtonImageLineLength)]];
                [buttonImagePath applyTransform:CGAffineTransformMakeRotation(M_PI/4)];
                [buttonImagePath applyTransform:CGAffineTransformMakeTranslation(kButtonSize/2*1.2, kButtonSize/2*1.1)];
            }
            else {
                secondButton = button;
                [buttonImagePath appendPath:[UIBezierPath bezierPathWithRect:CGRectMake(-kButtonImageLineLength/2, -kButtonImageLineThickness/2, kButtonImageLineLength, kButtonImageLineThickness)]];
                [buttonImagePath appendPath:[UIBezierPath bezierPathWithRect:CGRectMake(-kButtonImageLineThickness/2, -kButtonImageLineLength/2, kButtonImageLineThickness, kButtonImageLineLength)]];
                [buttonImagePath applyTransform:CGAffineTransformMakeRotation(M_PI/4)];
                [buttonImagePath applyTransform:CGAffineTransformMakeTranslation(kButtonSize/2, kButtonSize/2)];
            }
            [buttonImage setPath:buttonImagePath.CGPath];
            [button.layer addSublayer:buttonImage];
            
            [button.layer setShadowColor:[UIColor colorWithWhite:0.1 alpha:1].CGColor];
            [button.layer setShadowOffset:CGSizeMake(0, 2)];
            [button.layer setShadowOpacity:0.5];
            [button.layer setShadowRadius:2];
        }
        
        //create the text field
        _selectionLabel = [[UILabel alloc] initWithFrame:CGRectMake(kFontPickerWindowHorizontalPadding, firstButton.frame.origin.y+kButtonSize/2-kTextFieldHeight/2, firstButton.frame.origin.x-kFontPickerWindowHorizontalPadding-kButtonMargins, kTextFieldHeight)];
        [_selectionLabel setFont:[UIFont fontWithName:@"Helvetica" size:16]];
        [_selectionLabel setText:@"Helvetica"];
        [_selectionLabel setTextColor:[UIColor blackColor]];
        [_selectionLabel.layer setCornerRadius:4];
        
        //create divider above text field
        UIView *selectionLabelDivider = [[UIView alloc] initWithFrame:CGRectMake(0, kFontPickerWindowWidth+textButtonSectionHeight, kFontPickerWindowWidth, 1)];
        [selectionLabelDivider setBackgroundColor:[UIColor lightGrayColor]];
        
        //create the table view
        _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, kFontPickerWindowWidth, kFontPickerWindowWidth+textButtonSectionHeight) style:UITableViewStyleGrouped];
        [_tableView setDataSource:self];
        [_tableView setDelegate:self];
        [_tableView setSectionIndexColor:[UIColor blackColor]];
        
        //set general information
        [self setAlpha:0];
        [self setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin];
        [self setBackgroundColor:[UIColor whiteColor]];
        [self setClipsToBounds:YES];
        [self setFrame:CGRectMake(0, 0, kFontPickerWindowWidth, kFontPickerWindowWidth+textButtonSectionHeight*2)];
        [self setUserInteractionEnabled:NO];
        [self setCenter:CGPointMake(parentView.bounds.size.width/2, parentView.bounds.size.height/2)];
        [self.layer setCornerRadius:4];
        
        [self addSubview:_tableView];
        [self addSubview:_selectionLabel];
        [self addSubview:firstButton];
        [self addSubview:secondButton];
        [self addSubview:selectionLabelDivider];
        
        [parentView addSubview:self];
    }
    return self;
}

- (void)buttonDown:(UIButton *)button {
    [button setBackgroundColor:[UIColor colorWithWhite:0.8 alpha:1]];
    [button.layer setShadowOpacity:0.25];
    [CATransaction begin];
    [CATransaction setValue: (id) kCFBooleanTrue forKey: kCATransactionDisableActions];
    for(CALayer *layer in button.layer.sublayers) {
        [layer setTransform:CATransform3DMakeTranslation(0, 1, 0)];
    }
    [CATransaction commit];
}

- (void)buttonTapped:(UIButton *)button {
    [button setBackgroundColor:[UIColor whiteColor]];
    [button.layer setShadowOpacity:0.5];
    if(self.completionBlock) {
        self.completionBlock(self.selectionLabel.text);
    }
    [CATransaction begin];
    [CATransaction setValue: (id) kCFBooleanTrue forKey: kCATransactionDisableActions];
    for(CALayer *layer in button.layer.sublayers) {
        [layer setTransform:CATransform3DIdentity];
    }
    [CATransaction commit];
}

- (void)dismiss {
    [self setUserInteractionEnabled:NO];
    [self.backgroundOverlay setUserInteractionEnabled:NO];
    [UIView animateWithDuration:0.2 animations:^{
        [self.backgroundOverlay setAlpha:0];
        [self setAlpha:0];
        [self setTransform:CGAffineTransformMakeScale(0.5, 0.5)];
    } completion:^(BOOL finished) {
        [self.backgroundOverlay removeFromSuperview];
        [self removeFromSuperview];
    }];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.fontNames.count;
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    for(int i=0;i<self.fontNames.count;i++) {
        if([title isEqualToString:[[[[self.fontNames objectAtIndex:i] objectForKey:@"name"] substringToIndex:1] uppercaseString]]) {
            return i;
        }
    }
    return -1;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    NSMutableArray *titles = [[NSMutableArray alloc] init];
    for(int i=0;i<self.fontNames.count;i++) {
        NSString *nextTile = [[[[self.fontNames objectAtIndex:i] objectForKey:@"name"] substringToIndex:1] uppercaseString];
        if(i==0 || ![nextTile isEqualToString:[titles lastObject]]) {
            [titles addObject:nextTile];
        }
    }
    return titles;
}

- (void)setFontName:(NSString *)fontName {
    [self.selectionLabel setFont:[UIFont fontWithName:fontName size:16]];
    [self.selectionLabel setText:fontName];
}

- (void)show {
    [UIView animateWithDuration:0.3 animations:^{
        [self.backgroundOverlay setAlpha:0.5];
        [self setAlpha:1];
    } completion:^(BOOL finished) {
        [self setUserInteractionEnabled:YES];
    }];
    
    CAKeyframeAnimation *animation = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    
    CATransform3D scale1 = CATransform3DMakeScale(0.5, 0.5, 1);
    CATransform3D scale2 = CATransform3DMakeScale(1.1, 1.1, 1);
    CATransform3D scale3 = CATransform3DMakeScale(0.9, 0.9, 1);
    CATransform3D scale4 = CATransform3DMakeScale(1.0, 1.0, 1);
    
    NSArray *frameValues = [NSArray arrayWithObjects:[NSValue valueWithCATransform3D:scale1],[NSValue valueWithCATransform3D:scale2],[NSValue valueWithCATransform3D:scale3],[NSValue valueWithCATransform3D:scale4],nil];
    [animation setValues:frameValues];
    
    NSArray *frameTimes = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0],[NSNumber numberWithFloat:0.5],[NSNumber numberWithFloat:0.9],[NSNumber numberWithFloat:1.0],nil];
    [animation setKeyTimes:frameTimes];
    
    animation.fillMode = kCAFillModeForwards;
    animation.removedOnCompletion = NO;
    animation.duration = .3;
    
    [self.layer addAnimation:animation forKey:@"popup"];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellReuseIdentifier = @"FontPickerCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellReuseIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellReuseIdentifier];
    }
    
    NSString *fontName = [[[self.fontNames objectAtIndex:indexPath.section] objectForKey:@"fonts"] objectAtIndex:indexPath.row];
    [cell.textLabel setFont:[UIFont fontWithName:fontName size:16]];
    [cell.textLabel setText:fontName];
    [cell.textLabel sizeToFit];
    
    CGRect textLabelFrame = cell.textLabel.frame;
    textLabelFrame.origin.y = (self.bounds.size.height-textLabelFrame.size.height)/2;
    [cell.textLabel setFrame:textLabelFrame];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    NSString *fontName = [[[self.fontNames objectAtIndex:indexPath.section] objectForKey:@"fonts"] objectAtIndex:indexPath.row];
    [self.selectionLabel setFont:[UIFont fontWithName:fontName size:16]];
    [self.selectionLabel setText:fontName];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [[[self.fontNames objectAtIndex:section] objectForKey:@"fonts"] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return [[self.fontNames objectAtIndex:section] objectForKey:@"name"];
}

@end