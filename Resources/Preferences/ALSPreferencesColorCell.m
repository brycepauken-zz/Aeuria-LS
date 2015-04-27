#import "ALSPreferencesColorCell.h"

#import "PSListController.h"
#import "PSSpecifier.h"

@interface ALSPreferencesColorCell()

@property (nonatomic, strong) UIView *coloredBorder;
@property (nonatomic, strong) UILabel *colorLabel;
@property (nonatomic, weak) UITableView *parentTableView;
@property (nonatomic, strong) UIView *sideBar;
@property (nonatomic, strong) PSSpecifier *specifier;
@property (nonatomic) BOOL touchDown;

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
        
        //add the border that shows the selected color
        _coloredBorder = [[UIView alloc] initWithFrame:CGRectInset(_sideBar.bounds, kColoredBorderPadding, kColoredBorderPadding)];
        [_coloredBorder setAutoresizingMask:UIViewAutoresizingFlexibleBottomMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin];
        [_coloredBorder.layer setBorderColor:[UIColor redColor].CGColor];
        [_coloredBorder.layer setBorderWidth:1];
        [_coloredBorder.layer setCornerRadius:2];
        [_coloredBorder.layer setMasksToBounds:YES];
        [_sideBar addSubview:_coloredBorder];
        
        _colorLabel = [[UILabel alloc] init];
        [_colorLabel setFont:[UIFont fontWithName:@"HelveticaNeue-Light" size:15]];
        [_colorLabel setText:@"#FF0000"];
        //[_colorLabel setTextColor:[UIColor colorWithWhite:0.2 alpha:1]];
        [_colorLabel sizeToFit];
        [_colorLabel setCenter:CGPointMake(_sideBar.bounds.size.width/2, _sideBar.bounds.size.height/2)];
        [_sideBar addSubview:_colorLabel];
        
        [self addSubview:_sideBar];
    }
    return self;
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
    
}

- (void)showColorPicker {
    //create an overlay to darken the background
    UIView *backgroundOverlay = [[UIView alloc] initWithFrame:self.window.bounds];
    [backgroundOverlay setAlpha:0.5];
    [backgroundOverlay setBackgroundColor:[UIColor blackColor]];
    [self.window addSubview:backgroundOverlay];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    self.touchDown = YES;
    [self setBackgroundColor:[UIColor colorWithWhite:0.9 alpha:1]];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self touchesEnded:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if(self.touchDown) {
        [self setTouchDown:NO];
        [self setBackgroundColor:[UIColor colorWithWhite:1 alpha:1]];
        [self showColorPicker];
    }
}

@end