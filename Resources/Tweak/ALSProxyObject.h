#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, ALSProxyObjectType) {
    ALSProxyObjectStrongReference,
    ALSProxyObjectWeakReference,
    ALSProxyObjectCopyReference
};

@interface ALSProxyObject : NSObject <NSCopying>

+ (instancetype)proxyOfType:(ALSProxyObjectType)type forObject:(id)object;
- (id)object;

@end
