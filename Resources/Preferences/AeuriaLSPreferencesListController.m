#import "AeuriaLSPreferencesListController.h"

#import "ALSPContainerView.h"
#import "ALSPMainView.h"

@interface AeuriaLSPreferencesListController()

@property (nonatomic, strong) ALSPContainerView *containerView;

@end

@implementation AeuriaLSPreferencesListController

- (id)specifiers {
    if(_specifiers == nil) {
        _specifiers = @[];
    }
    return _specifiers;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if(!self.containerView) {
        self.containerView = [[ALSPContainerView alloc] initWithFrame:self.view.bounds];
        [self.containerView setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
        [self.view addSubview:self.containerView];
    }
}

@end
