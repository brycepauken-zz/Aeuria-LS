#import "ALSProxyObject.h"

@interface ALSProxyObject()

@property (nonatomic, copy) id copiedReference;
@property (nonatomic, strong) id strongReference;
@property (nonatomic) ALSProxyObjectType type;
@property (nonatomic, weak) id weakReference;

@end

@implementation ALSProxyObject

+ (instancetype)proxyOfType:(ALSProxyObjectType)type forObject:(id)object {
    ALSProxyObject *proxyObject = [[ALSProxyObject alloc] init];
    if(proxyObject) {
        [proxyObject setType:type];
        switch(type) {
            case ALSProxyObjectStrongReference:
                [proxyObject setStrongReference:object];
                break;
            case ALSProxyObjectWeakReference:
                [proxyObject setWeakReference:object];
                break;
            case ALSProxyObjectCopyReference:
                [proxyObject setCopiedReference:object];
                break;
            default:
                break;
        }
    }
    return proxyObject;
}

- (id)object {
    switch(self.type) {
        case ALSProxyObjectStrongReference:
            return self.strongReference;
            break;
        case ALSProxyObjectWeakReference:
            return self.weakReference;
            break;
        case ALSProxyObjectCopyReference:
            return self.copiedReference;
            break;
        default:
            break;
    }
}

@end