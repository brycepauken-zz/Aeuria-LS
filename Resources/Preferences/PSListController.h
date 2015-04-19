@interface PSListController : UIViewController {
    NSArray* _specifiers;
}

- (NSArray*)loadSpecifiersFromPlistName:(NSString*)plistName target:(id)target;
- (id)specifiers;

@end