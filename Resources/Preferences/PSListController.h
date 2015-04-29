@class PSSpecifier;

@interface PSListController : UIViewController {
    NSArray* _specifiers;
}

- (NSArray*)loadSpecifiersFromPlistName:(NSString*)plistName target:(id)target;
- (void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier;
- (PSSpecifier *)specifierForID:(NSString*)specifierID;
- (PSSpecifier*)specifierAtIndex:(int)index;
- (id)specifiers;

@end