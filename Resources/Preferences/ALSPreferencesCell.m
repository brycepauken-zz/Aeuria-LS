#import "ALSPreferencesCell.h"

#import "PSListController.h"

@interface ALSPreferencesCell()

@property (nonatomic, strong) UILabel *fontLabel;
@property (nonatomic, strong) UILongPressGestureRecognizer *gestureRecognizer;
@property (nonatomic, strong) id internalValue;
@property (nonatomic, weak) UITableView *parentTableView;
@property (nonatomic) BOOL registeredObserver;
@property (nonatomic, strong) PSSpecifier *specifier;

@end

@implementation ALSPreferencesCell

- (void)dealloc {
    @synchronized(self) {
        [self tryRemovingObserver];
    }
}

- (id)initWithSpecifier:(PSSpecifier *)specifier {
    return [self initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil specifier:specifier];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier specifier:(PSSpecifier *)specifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier specifier:specifier];
    if(self) {
        _specifier = specifier;
        
        _gestureRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handlePress:)];
        [_gestureRecognizer setDelegate:self];
        [_gestureRecognizer setMinimumPressDuration:0.01];
        [self addGestureRecognizer:_gestureRecognizer];
    }
    return self;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    @synchronized(self) {
        [self tryRemovingObserver];
        self.registeredObserver = YES;
        [self.parentTableView addObserver:self forKeyPath:@"contentOffset" options:NSKeyValueObservingOptionNew context:nil];
    }
    
    return YES;
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

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    @synchronized(self) {
        [self tryRemovingObserver];
    }
    if([object isKindOfClass:[UITableView class]]) {
        [self.gestureRecognizer setEnabled:NO];
        [self.gestureRecognizer setEnabled:YES];
        [self setBackgroundColor:[UIColor colorWithWhite:1 alpha:1]];
    }
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

- (void)tryRemovingObserver {
    if(self.registeredObserver) {
        self.registeredObserver = NO;
        [self.parentTableView removeObserver:self forKeyPath:@"contentOffset"];
    }
}

@end