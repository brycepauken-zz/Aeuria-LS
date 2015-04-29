#import "ALSPreferencesCell.h"

#import "PSListController.h"

@interface ALSPreferencesCell()

@property (nonatomic, strong) UILabel *fontLabel;
@property (nonatomic, strong) id internalValue;
@property (nonatomic, weak) UITableView *parentTableView;
@property (nonatomic, strong) PSSpecifier *specifier;

@end

@implementation ALSPreferencesCell

- (id)initWithSpecifier:(PSSpecifier *)specifier {
    return [self initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil specifier:specifier];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier specifier:specifier];
    if(self) {
        _specifier = specifier;
        
        UILongPressGestureRecognizer *gestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handlePress:)];
        [gestureRecognizer setMinimumPressDuration:0.01];
        [self addGestureRecognizer:gestureRecognizer];
    }
    return self;
}

- (void)handlePress:(UILongPressGestureRecognizer*)sender {
    if (sender.state == UIGestureRecognizerStateEnded) {
        [self setBackgroundColor:[UIColor colorWithWhite:1 alpha:1]];
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
}

@end