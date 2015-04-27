#import "ALSPreferencesColorCell.h"

#import "ALSPreferencesColorPicker.h"
#import "PSListController.h"
#import "PSSpecifier.h"

@interface ALSPreferencesColorCell()

@property (nonatomic, strong) UIView *coloredBorder;
@property (nonatomic, strong) UILabel *colorLabel;
@property (nonatomic, strong) ALSPreferencesColorPicker *colorPicker;
@property (nonatomic, strong) NSString *internalValue;
@property (nonatomic, weak) UITableView *parentTableView;
@property (nonatomic, strong) UIView *sideBar;
@property (nonatomic, strong) PSSpecifier *specifier;

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
        _specifier = specifier;
        
        //add the bar on the side (used to provide a background for light colors)
        _sideBar = [[UIView alloc] initWithFrame:CGRectMake(self.bounds.size.width-kSideBarWidth, 0, kSideBarWidth, self.bounds.size.height)];
        [_sideBar setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleHeight];
        [_sideBar setBackgroundColor:[UIColor clearColor]];
        [_sideBar setUserInteractionEnabled:YES];
        
        //add the border that shows the selected color
        _coloredBorder = [[UIView alloc] initWithFrame:CGRectInset(_sideBar.bounds, kColoredBorderPadding, kColoredBorderPadding)];
        [_coloredBorder setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin];
        [_sideBar setUserInteractionEnabled:YES];
        [_coloredBorder.layer setBorderColor:[UIColor whiteColor].CGColor];
        [_coloredBorder.layer setBorderWidth:1];
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
        
        UILongPressGestureRecognizer *gestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handlePress:)];
        [gestureRecognizer setMinimumPressDuration:0.01];
        [self addGestureRecognizer:gestureRecognizer];
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
    if (sender.state == UIGestureRecognizerStateEnded) {
        [self setBackgroundColor:[UIColor colorWithWhite:1 alpha:1]];
        [self showColorPicker];
    }
    else if (sender.state == UIGestureRecognizerStateBegan){
        [self setBackgroundColor:[UIColor colorWithWhite:0.9 alpha:1]];
    }
}

- (UITableView *)parentTableView {
    if(_parentTableView) {
        return _parentTableView;
    }
    else if(self.superview) {
        //find nearest parent tableview
        UIView *currentView = self;
        while(currentView && ![currentView isKindOfClass:[UITableView class]]) {
            currentView = currentView.superview;
        }
        if(currentView) {
            _parentTableView = (UITableView *)currentView;
            return _parentTableView;
        }
    }
    return nil;
}

/*
 Called to notify the controller to save our setting
 */
- (void)savePreferenceValue:(id)value {
    if(self.parentTableView && [self.parentTableView.delegate respondsToSelector:@selector(setPreferenceValue:specifier:)]) {
        [(id)self.parentTableView.delegate setPreferenceValue:value specifier:self.specifier];
    }
    else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Unable to save your changes. Please try again or seek assistance." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
    }
}

- (void)setValue:(id)value {
    self.internalValue = value;
    [self.colorLabel setText:value];
    [self.coloredBorder.layer setBorderColor:[[self class] colorFromHexString:self.internalValue].CGColor];
}

- (void)showColorPicker {
    self.colorPicker = [[ALSPreferencesColorPicker alloc] initWithParentView:self.parentTableView];
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