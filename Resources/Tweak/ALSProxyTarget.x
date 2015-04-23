#import "ALSProxyTarget.h"

/*
 The ALSProxyTarget class allows the use of an NSTimer or CADisplayLink
 without creating a retain loop (as they both retain their targets).
 Use by creating a ALSProxyTarget object (which stores a weak reference
 to the true target), then using the proxy object's -tick: method as
 the selector for the timer/displaylink.
 */

@interface ALSProxyTarget()

@property (nonatomic) BOOL passCaller;
@property (nonatomic) SEL selector;
@property (nonatomic) void *selectorImplementation;
@property (nonatomic, weak) id target;

@end

@implementation ALSProxyTarget

+ (id)proxyForTarget:(id)target selector:(SEL)selector {
    ALSProxyTarget *proxy = [[ALSProxyTarget alloc] init];
    if(proxy) {
        //make sure the target includes the given method
        if(![target respondsToSelector:selector]) {
            return nil;
        }
        
        //used to determine whether the selector wants the caller (timer or displaylink) passed as well
        NSMethodSignature *selectorSignature = [target methodSignatureForSelector:selector];
        if(selectorSignature == nil || selectorSignature.numberOfArguments > 3) {
            return nil;
        }
        
        proxy.target = target;
        proxy.selector = selector;
        proxy.selectorImplementation = [target methodForSelector:selector];
        proxy.passCaller = selectorSignature.numberOfArguments == 3;
    }
    return proxy;
}

- (void)tick:(id)caller {
    if(self.target) {
        if(self.passCaller) {
            void (*call)(id, SEL, id) = self.selectorImplementation;
            call(self.target, self.selector, caller);
        }
        else {
            void (*call)(id, SEL) = self.selectorImplementation;
            call(self.target, self.selector);
        }
    }
    else {
        if([caller respondsToSelector:@selector(invalidate)]) {
            [caller invalidate];
        }
    }
}

@end