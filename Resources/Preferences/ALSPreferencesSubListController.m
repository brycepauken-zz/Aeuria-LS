#import "ALSPreferencesSubListController.h"

#import "ALSPreferencesListItemsController.h"

NSString *kALSPreferencesSubListStateChanged = @"ALSPreferencesSubListStateChanged";

@interface ALSPreferencesSubListController()

@property (nonatomic, strong) UINavigationController *listItemsController;

@end

@implementation ALSPreferencesSubListController

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
    [super setPreferenceValue:value specifier:specifier];
    
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.brycepauken.aeurials/PreferencesChanged"), NULL, NULL, YES);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kALSPreferencesSubListStateChanged object:self userInfo:@{@"appearing":@(YES)}];
    
    //watch for list items controller changes
    [[NSNotificationCenter defaultCenter] addObserverForName:kALSPreferencesListItemsStateChanged object:nil queue:nil usingBlock:^(NSNotification *notification) {
        if([[notification.userInfo objectForKey:@"appearing"] boolValue]) {
            self.listItemsController = notification.object;
        }
        else {
            self.listItemsController = nil;
        }
    }];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    if(!self.listItemsController) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kALSPreferencesSubListStateChanged object:self userInfo:@{@"appearing":@(NO)}];
    }
}

@end