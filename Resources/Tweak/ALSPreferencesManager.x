#import "ALSPreferencesManager.h"

#import <UIKit/UIKit.h>

/*
 The ALSPreferencesManager class allows us to read the preferences
 specified in the Settings application.
 */

@interface ALSPreferencesManager()

@property (nonatomic, strong) NSMutableDictionary *preferences;

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
            [preferencesManager setPreferences:(NSMutableDictionary *)newPreferences];
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

+ (UIColor *)colorFromHexString:(NSString *)string {
    unsigned rgbValue = 0;
    NSScanner *scanner = [NSScanner scannerWithString:string];
    [scanner setScanLocation:1];
    [scanner scanHexInt:&rgbValue];
    return [UIColor colorWithRed:((rgbValue & 0xFF0000) >> 16)/255.0 green:((rgbValue & 0xFF00) >> 8)/255.0 blue:(rgbValue & 0xFF)/255.0 alpha:1.0];
}

- (void)dealloc {
    CFNotificationCenterRemoveEveryObserver(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge void *)self);
}

- (id)preferenceForKey:(id)key {
    if(!self.preferences) {
        return nil;
    }
    id preference = [self.preferences objectForKey:key];
    if([preference isKindOfClass:[NSString class]] && [preference length]==7 && [preference characterAtIndex:0]=='#') {
        preference = [[self class] colorFromHexString:preference];
        [self.preferences setObject:preference forKey:key];
    }
    return preference;
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