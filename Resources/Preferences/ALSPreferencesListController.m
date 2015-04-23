#import "ALSPreferencesListController.h"

#import "ALSPreferencesProxyTarget.h"
#import "ALSPreferencesSubListController.h"
#import "PSSpecifier.h"

@interface ALSPreferencesListController()

@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, strong) UINavigationBar *navigationBar;
@property (nonatomic, strong) UIView *navigationBarOverlay;
@property (nonatomic, strong) UINavigationController *sublistController;

@end

@implementation ALSPreferencesListController

static NSString *kPreferencePath = @"/User/Library/Preferences/com.brycepauken.aeurials.plist";

- (id)specifiers {
    if(_specifiers == nil) {
        _specifiers = [self loadSpecifiersFromPlistName:@"AeuriaLSPreferences" target:self];
    }
    return _specifiers;
}

- (void)dealloc {
    [self setNavigationBarSubviewsHidden:NO];
    [self.displayLink invalidate];
}

/*- (id)readPreferenceValue:(PSSpecifier*)specifier {
    //read the preference from file
    NSDictionary *preferences = [NSDictionary dictionaryWithContentsOfFile:kPreferencePath];
    if(!preferences[specifier.properties[@"key"]]) {
        return specifier.properties[@"default"];
    }
    return preferences[specifier.properties[@"key"]];
}*/

- (void)setNavigationBarAlpha:(CGFloat)alpha {
    if(alpha<0.025) {
        [self setNavigationBarSubviewsHidden:YES];
        [self.navigationBar setAlpha:1];
    }
    else {
        [self setNavigationBarSubviewsHidden:NO];
        [self.navigationBar setAlpha:alpha];
    }
}

- (void)setNavigationBarSubviewsHidden:(BOOL)hidden {
    if(self.navigationBar) {
        [self.navigationBarOverlay removeFromSuperview];
        for(UIView *view in self.navigationBar.subviews) {
            [view setHidden:hidden];
        }
    }
}

/*- (void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
    //read preferences from file
    NSMutableDictionary *preferences = [NSMutableDictionary dictionaryWithContentsOfFile:kPreferencePath];
    if(!preferences) {
        preferences = [NSMutableDictionary dictionary];
    }
    //set new preference
    [preferences setObject:value forKey:specifier.properties[@"key"]];
    //write preferences back to file
    [preferences writeToFile:kPreferencePath atomically:YES];
    //post a notification
    CFStringRef notifcation = (__bridge CFStringRef)specifier.properties[@"PostNotification"];
    if(notifcation) {
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), notifcation, NULL, NULL, YES);
    }
}*/

- (void)updateNavigationBarAlpha {
    //pick which view to use; our own, or our child controller's view (if there is one)
    UIView *currentView = self.sublistController?self.sublistController.view:self.view;
    
    //find our view's horizontal offset from the root superview (including animating superviews along the way)
    CGFloat viewOffset = 0;
    while(currentView.superview) {
        if(currentView.layer.animationKeys) {
            viewOffset += [currentView.layer.presentationLayer frame].origin.x;
        }
        currentView = currentView.superview;
    }
    
    //get the horizontal offset relative to our navigation bar
    CGFloat navigationBarOffset = [self.navigationBar convertPoint:CGPointMake(0, 0) toView:currentView].x;
    CGFloat relativeOffset = [self.navigationBar convertPoint:CGPointMake(viewOffset+navigationBarOffset, 0) fromView:currentView].x;
    CGFloat alphaValue = relativeOffset/self.navigationBar.bounds.size.width;
    //invert alpha value if we're looking at a subcontroller
    if(self.sublistController) {
        alphaValue = 1-alphaValue;
    }
    [self setNavigationBarAlpha:alphaValue];
    
    if(!self.sublistController) {
        //if our view is hidden or completely off the edge (alpha >= 1)
        if(self.view.hidden || alphaValue >= 1) {
            [self viewDidDisappear:NO];
        }
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    if(!self.sublistController) {
        [self setNavigationBarSubviewsHidden:NO];
        
        self.navigationBar = nil;
        self.navigationBarOverlay = nil;
        [self.displayLink invalidate];
        self.displayLink = nil;
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    /*
     This method is called once the view is about to start animating in,
     but it's called other times too. Our main goal (and reason for using this
     method rather than viewWillAppear) is to find the navigation bar of the Settings
     app. This is not as simple as calling self.navigationController.navigationBar,
     as this returns a proxy bar that's hidden from view — we need to find the actual one.
     */
    if(!self.navigationBar) {
        //find the closest visible navigation bar
        UIView *currentView = self.view.superview;
        while(!self.navigationBar && currentView) {
            for(UIView *subview in currentView.subviews) {
                if([subview isKindOfClass:[UINavigationBar class]] && !subview.hidden) {
                    self.navigationBar = (UINavigationBar *)subview;
                    break;
                }
            }
            currentView = currentView.superview;
        }
        
        //we found the navigation bar — make an image representing it and place it on top (to make the animation look better)
        if(self.navigationBar) {
            if(true) { //iphone/non-split
                //get current image from navigation bar
                UIWindow *window = self.navigationBar.window;
                CGPoint navigationBarPosition = [self.navigationBar convertPoint:CGPointZero toView:window];
                UIGraphicsBeginImageContextWithOptions(self.navigationBar.bounds.size, YES, 0.0);
                CGContextRef ctx = UIGraphicsGetCurrentContext();
                CGContextTranslateCTM(ctx, -navigationBarPosition.x, -navigationBarPosition.y);
                [window drawViewHierarchyInRect:window.bounds afterScreenUpdates:YES];
                UIImage *navigationBarImage = UIGraphicsGetImageFromCurrentImageContext();
                UIGraphicsEndImageContext();
                
                //hide existing subviews
                [self setNavigationBarSubviewsHidden:YES];
                
                //possibly needed to rasterize (avoid group opacity)
                //[self.navigationBar.layer setShouldRasterize:YES];
                //[self.navigationBar.layer setRasterizationScale:[[UIScreen mainScreen].scale];
                
                //set up navigarion bar overlay
                self.navigationBarOverlay = [[UIView alloc] initWithFrame:CGRectMake(0, -20, self.navigationBar.bounds.size.width, self.navigationBar.bounds.size.height+20)];
                [self.navigationBarOverlay setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
                [self.navigationBarOverlay setBackgroundColor:[UIColor colorWithWhite:0.96f alpha:1]];
                [self.navigationBarOverlay.layer setZPosition:MAXFLOAT];
                
                //add image to navigation bar
                UIImageView *navigationBarImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 20, navigationBarImage.size.width, navigationBarImage.size.height)];
                [navigationBarImageView setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleRightMargin];
                [navigationBarImageView setImage:navigationBarImage];
                [self.navigationBarOverlay addSubview:navigationBarImageView];
                
                //add bottom border to overlay
                UIView *navigationBarOverlayBorder = [[UIView alloc] initWithFrame:CGRectMake(0, self.navigationBarOverlay.bounds.size.height, self.navigationBarOverlay.bounds.size.width, 1)];
                [navigationBarOverlayBorder setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
                [navigationBarOverlayBorder setBackgroundColor:[UIColor lightGrayColor]];
                [self.navigationBarOverlay addSubview:navigationBarOverlayBorder];
                
                [self.navigationBar addSubview:self.navigationBarOverlay];
                
                //start display link to update navigation bar alpha
                [self.displayLink setPaused:NO];
            }
        }
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    //watch for sublist changes
    [[NSNotificationCenter defaultCenter] addObserverForName:kALSPreferencesSubListStateChanged object:nil queue:nil usingBlock:^(NSNotification *notification) {
        if([[notification.userInfo objectForKey:@"appearing"] boolValue]) {
            self.sublistController = notification.object;
            [self.navigationBarOverlay setHidden:YES];
        }
        else {
            self.sublistController = nil;
            [self.navigationBarOverlay setHidden:NO];
        }
    }];
    
    //used to track our pane's horizontal offset
    ALSPreferencesProxyTarget *proxyTarget = [ALSPreferencesProxyTarget proxyForTarget:self selector:@selector(updateNavigationBarAlpha)];
    self.displayLink = [CADisplayLink displayLinkWithTarget:proxyTarget selector:@selector(tick:)];
    [self.displayLink setFrameInterval:1];
    [self.displayLink setPaused:YES];
    [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
}

@end