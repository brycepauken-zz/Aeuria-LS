#import "ALSPreferencesColorCell.h"

#import "ALSPreferencesColorPicker.h"

@interface ALSPreferencesColorCell()

@property (nonatomic, strong) UIView *coloredBorder;
@property (nonatomic, strong) UILabel *colorLabel;
@property (nonatomic, strong) ALSPreferencesColorPicker *colorPicker;
@property (nonatomic, strong) UIView *sideBar;

@end

@implementation ALSPreferencesColorCell

static const int kColoredBorderPadding = 6;
static const int kSideBarWidth = 84;

- (id)initWithSpecifier:(PSSpecifier *)specifier {
    return [self initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil specifier:specifier];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier specifier:specifier];
    if(self) {
        //add the bar on the side (used to provide a background for light colors)
        _sideBar = [[UIView alloc] initWithFrame:CGRectMake(self.bounds.size.width-kSideBarWidth, 0, kSideBarWidth, self.bounds.size.height)];
        [_sideBar setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleHeight];
        [_sideBar setBackgroundColor:[UIColor colorWithWhite:0.8 alpha:1]];
        [_sideBar setUserInteractionEnabled:YES];
        
        //add the border that shows the selected color
        _coloredBorder = [[UIView alloc] initWithFrame:CGRectInset(_sideBar.bounds, kColoredBorderPadding, kColoredBorderPadding)];
        [_coloredBorder setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin];
        [_sideBar setUserInteractionEnabled:YES];
        [_coloredBorder.layer setBorderColor:[UIColor whiteColor].CGColor];
        [_coloredBorder.layer setBorderWidth:2];
        [_coloredBorder.layer setCornerRadius:2];
        [_coloredBorder.layer setMasksToBounds:YES];
        [_sideBar addSubview:_coloredBorder];
        
        _colorLabel = [[UILabel alloc] init];
        [_colorLabel setFont:[UIFont fontWithName:@"Menlo-Regular" size:14]];
        [_colorLabel setText:@"#FFFFFF"];
        [_colorLabel setTextColor:[UIColor colorWithWhite:0.1 alpha:1]];
        [_colorLabel setUserInteractionEnabled:YES];
        [_colorLabel sizeToFit];
        [_colorLabel setCenter:CGPointMake(_sideBar.bounds.size.width/2, _sideBar.bounds.size.height/2)];
        [_sideBar addSubview:_colorLabel];
        
        [self addSubview:_sideBar];
    }
    return self;
}

+ (UIColor *)colorFromHexString:(NSString *)string {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:string];
    [scanner setScanLocation:1];
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

- (void)handlePress:(UILongPressGestureRecognizer*)sender {
    [super handlePress:sender];
    
    if (sender.state == UIGestureRecognizerStateEnded) {
        [self showColorPicker];
    }
}

- (void)setValue:(id)value {
    [super setValue:value];
    
    [self.colorLabel setText:value];
    [self.colorLabel sizeToFit];
    [self.colorLabel setCenter:CGPointMake(self.sideBar.bounds.size.width/2, self.sideBar.bounds.size.height/2)];
    
    UIColor *color = [[self class] colorFromHexString:self.internalValue];
    [self.coloredBorder.layer setBorderColor:color.CGColor];
    
    CGFloat red, green, blue;
    [color getRed:&red green:&green blue:&blue alpha:NULL];
    
    CGFloat brightness = sqrt(0.299*red*red + 0.587*green*green + 0.114*blue*blue);
    [self.sideBar setBackgroundColor:(brightness>0.8?[UIColor colorWithWhite:0.1 alpha:1]:[UIColor clearColor])];
    [self.colorLabel setTextColor:(brightness>0.8?[UIColor whiteColor]:[UIColor colorWithWhite:0.1 alpha:1])];
}

- (void)showColorPicker {
    self.colorPicker = [[ALSPreferencesColorPicker alloc] initWithParentView:self.parentTableView.superview];
    __weak ALSPreferencesColorPicker *weakColorPicker = self.colorPicker;
    __weak ALSPreferencesColorCell *weakSelf = self;
    [self.colorPicker setCompletionBlock:^(NSString *hexColor) {
        [weakColorPicker dismiss];
        if(hexColor) {
            [weakSelf setValue:hexColor];
            [weakSelf savePreferenceValue:hexColor];
        }
    }];
    [self.colorPicker setHexColor:self.internalValue];
    [self.colorPicker show];
}

@end