#import "AeuriaLSPreferencesSubListController.h"

NSString *kAeuriaLSPreferencesSubListStateChanged = @"AeuriaLSPreferencesSubListStateChanged";

@implementation AeuriaLSPreferencesSubListController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kAeuriaLSPreferencesSubListStateChanged object:self userInfo:@{@"appearing":@(YES)}];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kAeuriaLSPreferencesSubListStateChanged object:self userInfo:@{@"appearing":@(NO)}];
}

@end