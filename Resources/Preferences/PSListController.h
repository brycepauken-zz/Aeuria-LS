@class PSSpecifier;

@interface PSListController : UIViewController {
    NSArray* _specifiers;
}

- (NSArray*)loadSpecifiersFromPlistName:(NSString*)plistName target:(id)target;
- (void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier;
- (id)specifiers;

@end