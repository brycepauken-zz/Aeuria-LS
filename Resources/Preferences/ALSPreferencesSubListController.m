#import "ALSPreferencesSubListController.h"

#import "PSSpecifier.h"

NSString *kALSPreferencesSubListStateChanged = @"ALSPreferencesSubListStateChanged";

@implementation ALSPreferencesSubListController

static NSString *kALSPreferencesDefaultsPath = @"/Library/PreferenceBundles/AeuriaLSPreferences.bundle/Defaults.plist";

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
    [super setPreferenceValue:value specifier:specifier];
    
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.brycepauken.aeurials/PreferencesChanged"), NULL, NULL, YES);
}

- (id)specifiers {
    static NSDictionary *defaults;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaults = [[NSDictionary alloc] initWithContentsOfFile:kALSPreferencesDefaultsPath];
        if(!defaults) {
            defaults = [[NSDictionary alloc] init];
        }
    });
    id specifiers = [super specifiers];
    for(PSSpecifier *specifier in specifiers) {
        [specifier setProperty:[defaults objectForKey:[specifier propertyForKey:@"key"]] forKey:@"default"];
    }
    return specifiers;
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