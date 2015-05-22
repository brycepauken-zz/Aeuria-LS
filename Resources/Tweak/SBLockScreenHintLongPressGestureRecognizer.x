#import "SBLockScreenHintLongPressGestureRecognizer.h"

%hook SBLockScreenHintLongPressGestureRecognizer

- (id)initWithTarget:(id)target action:(SEL)action {
    id selfID = %orig;
    if(selfID) {
        [selfID setEnabled:NO];
    }
    return selfID;
}

- (void)setEnabled:(BOOL)enabled {
    %orig(NO);
}

%end
