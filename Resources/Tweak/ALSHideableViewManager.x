#import "ALSHideableViewManager.h"
#import "ALSProxyObject.h"

@implementation ALSHideableViewManager

static BOOL _shouldHide;

- (instancetype)init {
    self = [super init];
    if(self) {
        _shouldHide = NO;
    }
    return self;
}

+ (void)addView:(UIView *)view {
    NSArray *keys = [[self hideableObjects] allKeys];
    NSUInteger index = [keys indexOfObjectPassingTest:^(id obj, NSUInteger i, BOOL *stop) {
        return (BOOL)([obj respondsToSelector:@selector(object)] && ([obj object]==view));
    }];
    if(index == NSNotFound) {
        ALSProxyObject *proxyObject = [ALSProxyObject proxyOfType:ALSProxyObjectWeakReference forObject:view];
        [[self hideableObjects] setObject:@(view.hidden) forKey:proxyObject];
    }
}

+ (NSMutableDictionary *)hideableObjects {
    static NSMutableDictionary *hideableObjects;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        hideableObjects = [[NSMutableDictionary alloc] init];
    });
    return hideableObjects;
}

+ (void)setShouldHide:(BOOL)shouldHide {
    _shouldHide = shouldHide;
    for(ALSProxyObject *key in [[self hideableObjects] allKeys]) {
        [[key object] setHidden:(shouldHide?YES:[[[self hideableObjects] objectForKey:key] boolValue])];
    }
}

+ (void)setViewHidden:(BOOL)hidden forView:(UIView *)view {
    NSArray *keys = [[self hideableObjects] allKeys];
    NSUInteger index = [keys indexOfObjectPassingTest:^(id obj, NSUInteger i, BOOL *stop) {
        return (BOOL)([obj respondsToSelector:@selector(object)] && ([obj object]==view));
    }];
    if(index != NSNotFound) {
        [[self hideableObjects] setObject:@(hidden) forKey:[keys objectAtIndex:index]];
    }
}

+ (BOOL)shouldHide {
    return _shouldHide;
}

+ (BOOL)viewHidden:(UIView *)view {
    NSArray *keys = [[self hideableObjects] allKeys];
    NSUInteger index = [keys indexOfObjectPassingTest:^(id obj, NSUInteger i, BOOL *stop) {
        return (BOOL)([obj respondsToSelector:@selector(object)] && ([obj object]==view));
    }];
    if(index != NSNotFound) {
        [[self hideableObjects] objectForKey:[keys objectAtIndex:index]];
    }
    return NO;
}

@end