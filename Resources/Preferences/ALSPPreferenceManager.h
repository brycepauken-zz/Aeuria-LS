typedef NS_ENUM(NSInteger, HOIThemeStatus) {
    HOIThemeStatusNone,
    HOIThemeStatusWinterboardActive,
    HOIThemeStatusActivePreviouslyNone,
    HOIThemeStatusActivePreviouslyWinterboardActive
};

@interface ALSPPreferenceManager : NSObject

+ (void)statusChangedForTheme:(NSString *)theme inFolder:(NSString *)folder status:(HOIThemeStatus)status;
+ (NSArray *)themeList;
+ (HOIThemeStatus)toggledStatus:(HOIThemeStatus)status;

@end
