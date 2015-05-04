#import "ALSProxyPasscodeHandler.h"

@interface ALSProxyPasscodeHandler()

@property (nonatomic, strong) id passcode;
@property (nonatomic, weak) id passcodeView;

@end

@implementation ALSProxyPasscodeHandler

- (void)forwardInvocation:(NSInvocation *)invocation {
    [invocation invokeWithTarget:self.passcodeView];
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)selector {
    NSMethodSignature *signature = [super methodSignatureForSelector:selector];
    if (!signature) {
        signature = [self.passcodeView methodSignatureForSelector:selector];
    }
    return signature;
}

@end