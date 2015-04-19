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

static void PreferencesChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    CFStringRef bundleID = CFSTR("com.brycepauken.aeurials");
    CFArrayRef keyList = CFPreferencesCopyKeyList(appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    if(!keyList) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Key List" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];

        return;
    }
    NSDictionary *newPreferences = (NSDictionary *)CFPreferencesCopyMultiple(keyList, bundleID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
    if(!newPreferences) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Preferences" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
    }
    else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Success" message:@"Obtained" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView performSelectorOnMainThread:@selector(show) withObject:nil waitUntilDone:YES];
        
        self.preferences = newPreferences;
    }
    CFRelease(keyList);
}

@end