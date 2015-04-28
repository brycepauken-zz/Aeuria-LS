#import "ALSPreferencesSubListController.h"

NSString *kALSPreferencesSubListStateChanged = @"ALSPreferencesSubListStateChanged";

@implementation ALSPreferencesSubListController

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
    [super setPreferenceValue:value specifier:specifier];
    
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.brycepauken.aeurials/PreferencesChanged"), NULL, NULL, YES);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kALSPreferencesSubListStateChanged object:self userInfo:@{@"appearing":@(YES)}];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kALSPreferencesSubListStateChanged object:self userInfo:@{@"appearing":@(NO)}];
}

@end