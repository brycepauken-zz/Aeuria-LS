@interface ALSPreferencesProxyTarget : NSObject

+ (id)proxyForTarget:(id)target selector:(SEL)selector;
- (void)tick:(id)caller;

@end
