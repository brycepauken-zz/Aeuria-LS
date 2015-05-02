#import "ALSPreferencesManager.h"

#import <UIKit/UIKit.h>

/*
 The ALSPreferencesManager class allows us to read the preferences
 specified in the Settings application.
 */

@interface ALSPreferencesManager()

@property (nonatomic, strong) NSDictionary *preferences;

@end

@implementation ALSPreferencesManager

static NSString *kALSPreferencesDefaultsPath = @"/Library/PreferenceBundles/AeuriaLSPreferences.bundle/Defaults.plist";

void preferencesChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    ALSPreferencesManager *preferencesManager = (__bridge ALSPreferencesManager *)observer;
    
    CFStringRef bundleID = CFSTR("com.brycepauken.aeurials");
    //freed at end of method
    CFArrayRef keyList = CFPreferencesCopyKeyList(bundleID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    if(keyList) {
        //freed automatically by ARC
        NSDictionary *newPreferences = CFBridgingRelease(CFPreferencesCopyMultiple(keyList, bundleID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost));
        if(newPreferences) {
            preferencesManager.preferences = newPreferences;
        }
        CFRelease(keyList);
    }
}

- (id)init {
    self = [super init];
    if(self) {
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge void *)self, (CFNotificationCallback)preferencesChanged, CFSTR("com.brycepauken.aeurials/PreferencesChanged"), NULL, CFNotificationSuspensionBehaviorCoalesce);
        preferencesChanged(NULL, (__bridge void *)self, NULL, NULL, NULL);
    }
    return self;
}

- (void)dealloc {
    CFNotificationCenterRemoveEveryObserver(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge void *)self);
}

- (id)preferenceForKey:(id)key {
    if(!self.preferences) {
        return nil;
    }
    return [self.preferences objectForKey:key];
}

- (void)setPreferences:(NSDictionary *)preferences {
    static NSDictionary *defaults;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaults = [[NSDictionary alloc] initWithContentsOfFile:kALSPreferencesDefaultsPath];
        if(!defaults) {
            defaults = [[NSDictionary alloc] init];
        }
    });
    
    NSMutableDictionary *newPreferences = [NSMutableDictionary dictionaryWithDictionary:defaults];
    [newPreferences addEntriesFromDictionary:preferences];
    _preferences = newPreferences;
}

@end