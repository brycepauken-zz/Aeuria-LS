#import <UIKit/UIKit.h>

/*
 The ALSCustomLockScreenElement asks as a superclass to share
 methods between the Clock and Button mask generator obejcts.
 */

@class ALSPreferencesManager;

@interface ALSCustomLockScreenElement : NSObject

- (instancetype)initWithPreferencesManager:(ALSPreferencesManager *)preferencesManager;
+ (CGPathRef)createPathForText:(NSString *)text fontName:(NSString *)fontName;
+ (CGFloat)scaleForPathOfSize:(CGSize)pathSize withinRadius:(CGFloat)radius isHalfCircle:(BOOL)isHalfCircle withOffsetFromCenter:(CGFloat)offset maxHeight:(int)maxHeight;

@end
