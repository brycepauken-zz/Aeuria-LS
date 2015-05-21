#import "ALSPreferencesListController.h"

#import "ALSPreferencesProxyTarget.h"
#import "ALSPreferencesSubListController.h"
#import "PSSpecifier.h"

@interface ALSPreferencesListController()

@property (nonatomic, weak) PSListController *sublistController;

@end

@implementation ALSPreferencesListController

- (id)specifiers {
    if(_specifiers == nil) {
        _specifiers = [self loadSpecifiersFromPlistName:@"AeuriaLSPreferences" target:self];
    }
    return _specifiers;
}

- (void)resetSettings {
    if(self.sublistController) {
        for(PSSpecifier *specifier in [self.sublistController specifiers]) {
            if([specifier propertyForKey:@"key"]) {
                [self setPreferenceValue:[specifier propertyForKey:@"default"] specifier:specifier];
            }
        }
        [self.sublistController reloadSpecifiers];
    }
}

- (void)setPreferenceValue:(id)value specifier:(PSSpecifier *)specifier {
    [super setPreferenceValue:value specifier:specifier];
    
    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.brycepauken.aeurials/PreferencesChanged"), NULL, NULL, YES);
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    //watch for sublist changes
    [[NSNotificationCenter defaultCenter] addObserverForName:kALSPreferencesSubListStateChanged object:nil queue:nil usingBlock:^(NSNotification *notification) {
        if([[notification.userInfo objectForKey:@"appearing"] boolValue]) {
            self.sublistController = notification.object;
        }
        else {
            self.sublistController = nil;
        }
    }];
}

@end