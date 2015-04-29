@interface PSSpecifier : NSObject

- (NSString *)identifier;
- (NSMutableDictionary *)properties;
- (id)propertyForKey:(NSString*)key;
- (void)setProperty:(id)property forKey:(NSString*)key;
- (NSArray *)values;

@end