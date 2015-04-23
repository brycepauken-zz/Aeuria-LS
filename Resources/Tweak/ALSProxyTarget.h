#import <UIKit/UIKit.h>

@interface ALSProxyTarget : NSObject

+ (id)proxyForTarget:(id)target selector:(SEL)selector;
- (void)tick:(id)caller;

@end
