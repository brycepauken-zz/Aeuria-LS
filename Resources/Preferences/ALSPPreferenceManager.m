#import "ALSPPreferenceManager.h"

@implementation ALSPPreferenceManager

+ (NSMutableDictionary *)AeuriaLSPreferences {
    return [[NSMutableDictionary alloc] initWithContentsOfFile:@"/private/var/mobile/Library/Preferences/com.kingfish.meims.plist"];
}

+ (NSArray *)themeList {
    //get array of themes in the Themes directory...
    NSArray *directoryThemesFolders = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/Library/Themes/" error:NULL];
    //... and a copy of the array with .theme extensions removed
    NSMutableArray *directoryThemes = [directoryThemesFolders mutableCopy];
    for(int i=0;i<directoryThemes.count;i++) {
        NSString *directoryTheme = [directoryThemes objectAtIndex:i];
        if([[directoryTheme lowercaseString] hasSuffix:@".theme"]) {
            [directoryThemes replaceObjectAtIndex:i withObject:[directoryTheme substringToIndex:directoryTheme.length-6]];
        }
    }
    
    //get array of themes active in the AeuriaLS tweak
    NSDictionary *ALSPreferences = [self AeuriaLSPreferences];
    NSMutableArray *hoiThemes;
    if(ALSPreferences && [ALSPreferences objectForKey:@"Themes"]) {
        hoiThemes = [ALSPreferences objectForKey:@"Themes"];
    }
    else {
        hoiThemes = [[NSMutableArray alloc] init];
    }
    
    //get array of themes known by Winterboard
    NSDictionary *winterboardPreferences = [self winterboardPreferences];
    
    if(winterboardPreferences && [winterboardPreferences objectForKey:@"Themes"]) {
        NSArray *winterboardThemes = [winterboardPreferences objectForKey:@"Themes"];
        NSMutableArray *validThemes = [[NSMutableArray alloc] init];
        
        for(NSDictionary *winterboardTheme in winterboardThemes) {
            NSString *themeName = [winterboardTheme objectForKey:@"Name"];
            NSUInteger winterboardThemeIndex = [directoryThemes indexOfObject:themeName];
            NSString *themeFolder = [directoryThemesFolders objectAtIndex:winterboardThemeIndex];
            
            //if theme exists in Themes directory and in Winterboard's theme list:
            if(winterboardThemeIndex != NSNotFound) {
                NSUInteger hoiThemeIndex = [hoiThemes indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop) {
                    return [[obj objectForKey:@"Folder"] isEqualToString:themeFolder];
                }];
                
                HOIThemeStatus themeStatus;
                if([[winterboardTheme objectForKey:@"Active"] boolValue]) {
                    themeStatus = HOIThemeStatusWinterboardActive;
                    if(hoiThemeIndex != NSNotFound) {
                        [hoiThemes removeObjectAtIndex:hoiThemeIndex];
                    }
                }
                else if(hoiThemeIndex != NSNotFound) {
                    themeStatus = [[[hoiThemes objectAtIndex:hoiThemeIndex] objectForKey:@"Status"] integerValue];
                }
                else {
                    themeStatus = HOIThemeStatusNone;
                }
                
                [validThemes addObject:[[NSMutableDictionary alloc] initWithObjectsAndKeys:themeName,@"Name", themeFolder,@"Folder", @(themeStatus),@"Status",  nil]];
            }
        }
        [self setAeuriaLSPreferences:@{@"Themes":hoiThemes}];
        return validThemes;
    }
    return @[];
}

+ (HOIThemeStatus)toggledStatus:(HOIThemeStatus)status {
    switch(status) {
        case HOIThemeStatusNone:
            return HOIThemeStatusActivePreviouslyNone;
            break;
        case HOIThemeStatusWinterboardActive:
            return HOIThemeStatusActivePreviouslyWinterboardActive;
            break;
        case HOIThemeStatusActivePreviouslyNone:
            return HOIThemeStatusNone;
            break;
        case HOIThemeStatusActivePreviouslyWinterboardActive:
            return HOIThemeStatusWinterboardActive;
            break;
        default:
            return HOIThemeStatusNone;
            break;
    }
}

+ (BOOL)setAeuriaLSPreferences:(NSDictionary *)preferences {
    return [preferences writeToFile:@"/private/var/mobile/Library/Preferences/com.kingfish.meims.plist" atomically:YES];
}

+ (BOOL)setWinterboardPreferences:(NSDictionary *)preferences {
    return [preferences writeToFile:@"/private/var/mobile/Library/Preferences/com.saurik.WinterBoard.plist" atomically:YES];
}

+ (void)statusChangedForTheme:(NSString *)theme inFolder:(NSString *)folder status:(HOIThemeStatus)status {
    //get our tweak's preferences and initialize some of its objects if needed
    NSMutableDictionary *ALSPreferences = [self AeuriaLSPreferences];
    if(!ALSPreferences) {
        ALSPreferences = [[NSMutableDictionary alloc] init];
    }
    if(![ALSPreferences objectForKey:@"Themes"]) {
        [ALSPreferences setObject:[[NSMutableArray alloc] init] forKey:@"Themes"];
    }
    
    //find index of theme (if it's already in our preferences)
    NSUInteger hoiIndex = [[ALSPreferences objectForKey:@"Themes"] indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop) {
        return [[obj objectForKey:@"Folder"] isEqualToString:folder];
    }];
    
    //if the user just added a checkmark, then we want to add the theme to our preferences (or update it if it's already there)
    if(status==HOIThemeStatusActivePreviouslyNone || status==HOIThemeStatusActivePreviouslyWinterboardActive) {
        if(hoiIndex == NSNotFound) {
            [[ALSPreferences objectForKey:@"Themes"] addObject:[[NSMutableDictionary alloc] initWithObjectsAndKeys:folder,@"Folder", @(status),@"Status", nil]];
        }
        else {
            [[[ALSPreferences objectForKey:@"Themes"] objectAtIndex:hoiIndex] setObject:@(status) forKey:@"Status"];
        }
    }
    //if the user *didn't* add a checkmark, then if the theme exists in the preferences (it should), then remove it
    else if(hoiIndex != NSNotFound) {
        [[ALSPreferences objectForKey:@"Themes"] removeObjectAtIndex:hoiIndex];
    }
    
    //update the preferences on file
    [self setAeuriaLSPreferences:ALSPreferences];
    
    //if the theme was (or now will be) active in winterboard, then...
    if(status==HOIThemeStatusWinterboardActive || status==HOIThemeStatusActivePreviouslyWinterboardActive) {
        //... get the winterboard preferences
        NSDictionary *winterboardPreferences = [self winterboardPreferences];
        if(winterboardPreferences && [winterboardPreferences objectForKey:@"Themes"]) {
            NSMutableArray *winterboardThemes = [[winterboardPreferences objectForKey:@"Themes"] mutableCopy];
            
            //find index of theme in the Winterboard preferences (it should be there)
            NSUInteger winterboardIndex = [winterboardThemes indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop) {
                return [[obj objectForKey:@"Name"] isEqualToString:theme];
            }];
            if(winterboardIndex != NSNotFound) {
                //recreate the winterboard preferences
                [winterboardThemes replaceObjectAtIndex:winterboardIndex withObject:@{@"Active":(status==HOIThemeStatusWinterboardActive?@(YES):@(NO)), @"Name":theme}];
                NSValue *summerBoardValue = [winterboardPreferences objectForKey:@"SummerBoard"];
                NSDictionary *newWinterboardPreferences = @{@"SummerBoard":(summerBoardValue?summerBoardValue:@(NO)), @"Themes":[NSArray arrayWithArray:winterboardThemes]};
                [self setWinterboardPreferences:newWinterboardPreferences];
            }
        }
    }
}

+ (NSDictionary *)winterboardPreferences {
    return [[NSDictionary alloc] initWithContentsOfFile:@"/private/var/mobile/Library/Preferences/com.saurik.WinterBoard.plist"];
}

@end
