@interface ALSPreferencesManager : NSObject

@property (nonatomic, copy) void (^preferencesChanged)();

- (id)preferenceForKey:(id)key;

@end
